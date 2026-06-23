USE ParquesNacionales;
GO
-- testeando funcionamiento de la importacion desde kml

CREATE OR ALTER PROCEDURE importacion.ImportarParquesKML
	@ruta_archivo VARCHAR(500)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @id_log INT;
	DECLARE @xml_contenido XML;
	DECLARE @leidos INT = 0;
	DECLARE @insertados INT = 0;
	DECLARE @actualizados INT = 0;
	DECLARE @errores INT = 0;
	DECLARE @detalle VARCHAR(500) = '';

	-- insertar el inicio del proceso en el log
	INSERT INTO importacion.LogImportacion(tipo_archivo, nombre_archivo, detalle)
	VALUES ('SIB_KML', @ruta_archivo, 'En proceso');

	SET @id_log = SCOPE_IDENTITY(); 

	-- leer KML (se lee como XML)
	-- único uso de sql dinamico (aclarado válido en consigna)
	BEGIN TRY
		DECLARE @sql NVARCHAR (MAX) = N'
			SELECT @xml_output = CAST(BulkColumn AS XML)
			FROM OPENROWSET(BULK ''' + @ruta_archivo + N''', SINGLE_BLOB) AS x;';

		EXEC sp_executesql @sql,
			N'@xml_output XML OUTPUT',
			@xml_output = @xml_contenido OUTPUT;
	END TRY
	BEGIN CATCH
		UPDATE importacion.LogImportacion
		SET detalle = 'Error al leer el archivo: ' + LEFT(ERROR_MESSAGE(), 400),
			errores = 1
		WHERE id_log = @id_log;
		RETURN;
	END CATCH;

	;WITH XMLNAMESPACES (DEFAULT 'http://www.opengis.net/kml/2.2')
	INSERT INTO importacion.StagingKML (id_log, nombre, cat_gral, sup_total, lat_dms, lon_dms ,ecorregion, provincia, region_dnc)
	SELECT
		@id_log,
		NULLIF(TRIM(p.value('(ExtendedData/SchemaData/SimpleData[@name="nombre"])[1]','VARCHAR(200)')),''),
		NULLIF(TRIM(p.value('(ExtendedData/SchemaData/SimpleData[@name="cat_gral"])[1]', 'VARCHAR(100)')), ''),
		NULLIF(TRIM(p.value('(ExtendedData/SchemaData/SimpleData[@name="sup_total"])[1]', 'VARCHAR(50)')),''),
		NULLIF(TRIM(p.value('(ExtendedData/SchemaData/SimpleData[@name="latitud"])[1]', 'VARCHAR(50)')),''),
		NULLIF(TRIM(p.value('(ExtendedData/SchemaData/SimpleData[@name="longitud"])[1]', 'VARCHAR(50)')),''),
		NULLIF(TRIM(p.value('(ExtendedData/SchemaData/SimpleData[@name="ecorregion"])[1]', 'VARCHAR(200)')),''),
		NULLIF(TRIM(p.value('(ExtendedData/SchemaData/SimpleData[@name="provincia"])[1]', 'VARCHAR(100)')),''),
		NULLIF(TRIM(p.value('(ExtendedData/SchemaData/SimpleData[@name="region_dnc"])[1]', 'VARCHAR(100)')),'')
	FROM @xml_contenido.nodes('//Placemark') AS x(p);

	SET @leidos = @@ROWCOUNT;

	--NORMALIZO CARACTERES TIPOGRAFICOS
	UPDATE importacion.StagingKML
	SET lat_dms = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lat_dms,
					NCHAR(186),  '°'),         -- º → °  (ordinal masculino)
					'''''',      '"'),          -- '' → "  (doble apóstrofe → comilla doble)
					NCHAR(8217), CHAR(39)),     -- ’ → '
					NCHAR(8216), CHAR(39)),     -- ‘ → '
					NCHAR(8221), '"'),          -- ” → "
					NCHAR(8220), '"'),          -- “ → "
		lon_dms = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lon_dms,
					NCHAR(186),  '°'),
					'''''',      '"'),
					NCHAR(8217), CHAR(39)),
					NCHAR(8216), CHAR(39)),
					NCHAR(8221), '"'),
					NCHAR(8220), '"')
	WHERE id_log = @id_log;
	
	--inserts de errores
	--sin nombre
	INSERT INTO importacion.ErroresKML (id_log, nombre, cat_gral, lat_dms, lon_dms, motivo)
	SELECT @id_log, nombre, cat_gral, lat_dms, lon_dms, 'Sin nombre'
	FROM importacion.StagingKML
	WHERE id_log = @id_log AND nombre IS NULL;

	--sin coordenada dms
	INSERT INTO importacion.ErroresKML (id_log, nombre, cat_gral, lat_dms, lon_dms, motivo)
	SELECT @id_log, nombre, cat_gral, lat_dms, lon_dms, 'Sin coordenada DMS'
	FROM importacion.StagingKML
	WHERE id_log = @id_log AND nombre IS NOT NULL
	AND (lat_dms IS NULL OR lon_dms IS NULL)

	--formato dms invalido
	INSERT INTO importacion.ErroresKML (id_log, nombre, cat_gral, lat_dms, lon_dms, motivo)
	SELECT @id_log, nombre, cat_gral, lat_dms, lon_dms, 'Formato DMS invalido'
	FROM importacion.StagingKML
	WHERE id_log = @id_log
	AND nombre IS NOT NULL
	AND lat_dms IS NOT NULL
	AND lon_dms IS NOT NULL
	AND(
         CHARINDEX('°', lat_dms) = 0
         OR CHARINDEX(CHAR(39), lat_dms) = 0
         OR CHARINDEX('"', lat_dms) = 0
         OR CHARINDEX('°', lon_dms) = 0
         OR CHARINDEX(CHAR(39), lon_dms) = 0
         OR CHARINDEX('"', lon_dms) = 0
	)

	INSERT INTO importacion.ValidosKML (id_log,nombre, cat_gral, superficie, latitud, longitud, ecorregion, provincia, region)
	SELECT
		@id_log,
		s.nombre,
		s.cat_gral,
		TRY_CAST(REPLACE(s.sup_total, ',','.') AS DECIMAL(12,2)),
		-- DMS es formato 24° 42' etc. Grados, minutos, segundos. Se castea a decimal (1 grado son 3600 segundos)
		-- la cuenta concreta es: decimal = grados + (minutos/60) + (segundos/3600)
		-- se usa LIKE %S% por que una coordenada en el archivo se ve asi: <SimpleData name="latitud">24° 42' 1,67" S</SimpleData>
		-- S de SUR (SOUTH), siempre va a funcionar porque argentina está en esa ubicación
		CASE 
			WHEN s.lat_dms LIKE '%S%' THEN -1
			WHEN s.lat_dms LIKE '%N%' THEN 1
			ELSE -1
		END *
		(	
			--CHARINDEX busca el símbolo ° en lat_dms y le resta 1
			--SUBSTRING tiene 3 parametros, variable (texto) sobre la que trabaja, inicio y hasta donde.
			-- en este contexto lee la variable lat_dms desde el inicio (1) hasta el simbolo °
			TRY_CAST(TRIM(SUBSTRING(
				s.lat_dms, 1, CHARINDEX('°', s.lat_dms) - 1
			)) AS DECIMAL(9,6))

			-- REPLACE está en caso de que haya una coma en lugar de un punto (robustece)
			-- en este contexto SUBSTRING lee la variabla lat_dms desde el caracter siguiente al símbolo 
			-- "°" hasta el caracter 39 que es el apóstrofe (mas legible de esta manera)
			-- CHARINDEX(CHAR(39), lat_dms) - CHARINDEX('°',lat_dms)-1 da la cantidad de caracteres que debe 
			-- moverse substring (no incluye ni '°' ni apóstrofe)
			+ TRY_CAST(REPLACE(TRIM(SUBSTRING(
				s.lat_dms,
				CHARINDEX('°', s.lat_dms) + 1,
				CHARINDEX(CHAR(39), s.lat_dms) - CHARINDEX ('°', s.lat_dms) - 1
			)), ',','.') AS DECIMAL(9,6)) / 60.0

			-- en este contexto SUBSTRING lee la variable lat_dms desde el siguiente caracter al apóstrofe
			-- hasta llegar a las comillas (simbolo final en coordenadas), calcula la distancia con la resta
			-- aclarada anteriormente, sin incluir ninguno de los dos simbolos.
			+ TRY_CAST(REPLACE(TRIM(SUBSTRING(
				s.lat_dms,
				CHARINDEX(CHAR(39), s.lat_dms) + 1,
				CHARINDEX('"', s.lat_dms) - CHARINDEX(CHAR(39), s.lat_dms) - 1
			)), ',','.') AS DECIMAL(9,6)) / 3600.0

		),
		CASE 
			WHEN s.lon_dms LIKE '%W%' THEN -1 
			WHEN s.lon_dms LIKE '%O%' THEN -1
			WHEN s.lon_dms LIKE '%E%' THEN 1
			ELSE NULL 
		END *
		(
			TRY_CAST(TRIM(SUBSTRING(
				s.lon_dms,
				1,
				CHARINDEX('°', s.lon_dms) - 1
			)) AS DECIMAL(9,6))
			+
			TRY_CAST(REPLACE(TRIM(SUBSTRING(
				s.lon_dms,
				CHARINDEX('°',s.lon_dms) + 1,
				CHARINDEX(CHAR(39), s.lon_dms) - CHARINDEX('°', s.lon_dms) - 1
			)), ',','.') AS DECIMAL(9,6)) / 60.0
			+
			TRY_CAST(REPLACE(TRIM(SUBSTRING(
				s.lon_dms,
				CHARINDEX(CHAR(39), s.lon_dms) + 1,
				CHARINDEX('"', s.lon_dms) - CHARINDEX(CHAR(39), s.lon_dms) - 1
			)), ',','.') AS DECIMAL(9,6)) /  3600.0
		),
		s.ecorregion,
		s.provincia,
		s.region_dnc
	FROM importacion.StagingKML s
	WHERE s.id_log = @id_log
	AND s.nombre IS NOT NULL
	AND s.lat_dms IS NOT NULL
	AND s.lon_dms IS NOT NULL
	AND CHARINDEX('°', s.lat_dms) > 0
	AND CHARINDEX(CHAR(39), s.lat_dms) > 0
	AND CHARINDEX('"', s.lat_dms) > 0
	AND CHARINDEX('°', s.lon_dms) > 0
	AND CHARINDEX(CHAR(39), s.lon_dms) > 0
	AND CHARINDEX('"', s.lon_dms) > 0

	--si falla conversion dms a decimal
	INSERT INTO importacion.ErroresKML(id_log, nombre, cat_Gral, lat_dms, lon_dms, motivo)
	SELECT @id_log, nombre, cat_gral, latitud, longitud, 'Conversion DMS dio NULL'
	FROM importacion.ValidosKML
	WHERE id_log = @id_log
	AND (latitud IS NULL OR longitud IS NULL);

	DELETE FROM importacion.ValidosKML
	WHERE id_log = @id_log
	AND (latitud IS NULL OR longitud IS NULL);

	--AÑADIR TIPOS DE PARQUES DESDE KML
	INSERT INTO parques.TipoParque(descripcion, estado)
	SELECT DISTINCT v.cat_gral, 0
	FROM importacion.ValidosKML v
	WHERE v.id_log = @id_log
		AND v.cat_gral IS NOT NULL
		AND NOT EXISTS (
			SELECT 1 FROM parques.TipoParque tp
			WHERE tp.descripcion = v.cat_gral COLLATE DATABASE_DEFAULT
		);

	--si categoria gral no matchea tipo parque
	INSERT INTO importacion.ErroresKML (id_log, nombre, cat_gral, lat_dms, lon_dms, motivo)
	SELECT @id_log, v.nombre, v.cat_gral, NULL,NULL,
			CONCAT('Tipo de parque no encontrado: ', v.cat_gral)
	FROM importacion.ValidosKML v
	LEFT JOIN parques.TipoParque tp
		ON descripcion = v.cat_gral COLLATE DATABASE_DEFAULT
	WHERE v.id_log = @id_log
	AND tp.id_tipo_parque IS NULL;

	DELETE v
	FROM importacion.ValidosKML v
	LEFT JOIN parques.TipoParque tp
		ON tp.descripcion = v.cat_gral COLLATE DATABASE_DEFAULT
	WHERE tp.id_tipo_parque IS NULL;

	-- upsert

	BEGIN TRY
		BEGIN TRANSACTION;
		UPDATE p
			SET 
			p.latitud = v.latitud,
			p.longitud = v.longitud,
			p.superficie = v.superficie,
			p.region = v.region,
			p.provincia = v.provincia
		FROM parques.Parque p
		INNER JOIN importacion.ValidosKML v 
		ON p.nombre = v.nombre COLLATE DATABASE_DEFAULT
		WHERE v.id_log = @id_log;
		
		SET @actualizados = @@ROWCOUNT;

		INSERT INTO parques.Parque(nombre, id_tipo_parque, region, provincia,
									latitud, longitud, superficie)
		SELECT v.nombre, tp.id_tipo_parque, v.region, v.provincia, v.latitud, v.longitud, v.superficie
		FROM importacion.ValidosKML v
		INNER JOIN parques.TipoParque tp
		ON tp.descripcion = v.cat_gral COLLATE DATABASE_DEFAULT
		WHERE NOT EXISTS(
			SELECT 1 FROM parques.Parque p
			WHERE p.nombre = v.nombre COLLATE DATABASE_DEFAULT
		);

		SET @insertados = @@ROWCOUNT;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 
			ROLLBACK TRANSACTION;

		UPDATE importacion.LogImportacion
		SET detalle = 'Error en upsert: ' + LEFT(ERROR_MESSAGE(),400),
			errores = @leidos
		WHERE id_log = @id_log;

		RETURN;
	END CATCH;

	SELECT @errores = COUNT(*)
	FROM importacion.ErroresKML
	WHERE id_log = @id_log;

	SET @detalle = CONCAT(
		'Leídos: ', @leidos,
		' - Insertados: ', @insertados,
		' - Actualizados: ', @actualizados,
		' - Errores: ', @errores
	);

	UPDATE importacion.LogImportacion
	SET registros_ok = @insertados + @actualizados,
		errores = @errores,
		detalle = @detalle
	WHERE id_log = @id_log;

	SELECT motivo, COUNT(*) AS cantidad
    FROM importacion.ErroresKML
    GROUP BY motivo
    ORDER BY cantidad DESC;
    
    SELECT * FROM importacion.ErroresKML ORDER BY motivo, nombre;
	
END;
GO

-- ejecución básica
EXEC importacion.ImportarParquesKML
     @ruta_archivo = 'C:\datasets finales\parques.kml';


-- Verificar resultado
SELECT tipo_archivo, nombre_archivo, fecha, registros_ok, errores, detalle FROM importacion.LogImportacion ORDER BY Fecha DESC;
SELECT * FROM parques.Parque;
SELECT * FROM parques.TipoParque

-- Verificar UPSERT: ejecutar de nuevo, no debe duplicar
EXEC importacion.ImportarParquesKML
     @ruta_archivo = 'C:\datasets finales\parques.kml';

SELECT COUNT(*) FROM parques.Parque;

DECLARE @ultimo_log INT = (
    SELECT MAX(id_log) FROM importacion.LogImportacion
    WHERE tipo_archivo = 'SIB_KML'
);

SELECT nombre, cat_gral, lat_dms, lon_dms, motivo
FROM importacion.ErroresKML
WHERE id_log = @ultimo_log
ORDER BY motivo, nombre;

SELECT motivo, COUNT(*) AS cantidad
FROM importacion.ErroresKML
WHERE id_log = (
    SELECT MAX(id_log) FROM importacion.LogImportacion
    WHERE tipo_archivo = 'SIB_KML'
)
GROUP BY motivo
ORDER BY cantidad DESC;