USE ParquesNacionales;
GO

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
	DECLARE @tipo_archivo VARCHAR(50) = 'SIB_KML';

	-- insertar el inicio del proceso en el log
	INSERT INTO importacion.LogImportacion(tipo_archivo, nombre_archivo, detalle)
	VALUES (@tipo_archivo, @ruta_archivo, 'En proceso');

	SET @id_log = SCOPE_IDENTITY(); 

	-- leer KML (se lee como XML)
	-- único uso de sql dinamico 
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

	--crear tabla staging temporal
	CREATE TABLE #staging (
		id_log INT NOT NULL,
		nombre VARCHAR(200),
		cat_gral VARCHAR(100),
		sup_total VARCHAR(50),
		lat_dms VARCHAR(50),
		lon_dms VARCHAR(50),
		ecorregion VARCHAR(200),
		provincia VARCHAR(100),
		region_dnc VARCHAR(100)
	)

	;WITH XMLNAMESPACES (DEFAULT 'http://www.opengis.net/kml/2.2')
	INSERT INTO #staging (id_log, nombre, cat_gral, sup_total, lat_dms, lon_dms ,ecorregion, provincia, region_dnc)
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
	UPDATE #staging
	SET lat_dms = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lat_dms,
					NCHAR(186),  '°'),         
					'''''',      '"'),          
					NCHAR(8217), CHAR(39)),     
					NCHAR(8216), CHAR(39)),     
					NCHAR(8221), '"'),          
					NCHAR(8220), '"'),          
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
	INSERT INTO importacion.ErroresImportacion(id_log, tipo_archivo, registro_origen, dato1, dato2, motivo)
	SELECT @id_log, @tipo_archivo, nombre, lat_dms, lon_dms, 'Sin nombre'
	FROM #staging
	WHERE nombre IS NULL;

	--sin coordenada dms
	INSERT INTO importacion.ErroresImportacion(id_log,tipo_archivo, registro_origen, dato1, dato2, motivo)
	SELECT @id_log, @tipo_archivo, nombre, lat_dms, lon_dms, 'Sin coordenada DMS'
	FROM #staging
	WHERE nombre IS NOT NULL
	AND (lat_dms IS NULL OR lon_dms IS NULL)

	--formato dms invalido
	INSERT INTO importacion.ErroresImportacion (id_log,tipo_archivo,registro_origen, dato1, dato2, motivo)
	SELECT @id_log,@tipo_archivo, nombre,lat_dms, lon_dms, 'Formato DMS invalido'
	FROM #staging
	WHERE nombre IS NOT NULL
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

	--CREACION DE TABLA TEMPORAL PARA DATOS VALIDOS
	CREATE TABLE #validos (
		nombre VARCHAR(200),
		cat_gral VARCHAR(100),
		superficie DECIMAL(12,2),
		latitud DECIMAL(9,6),
		longitud DECIMAL(9,6),
		provincia VARCHAR(100),
		region VARCHAR(100)
	)

	INSERT INTO #validos (nombre, cat_gral, superficie, latitud, longitud, provincia, region)
	SELECT
		s.nombre,
		s.cat_gral,
		TRY_CAST(TRY_CAST(s.sup_total AS FLOAT) AS DECIMAL(12,2)),
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
		s.provincia,
		s.region_dnc
	FROM #staging s
	WHERE s.nombre IS NOT NULL
	AND s.lat_dms IS NOT NULL
	AND s.lon_dms IS NOT NULL
	AND CHARINDEX('°', s.lat_dms) > 0
	AND CHARINDEX(CHAR(39), s.lat_dms) > 0
	AND CHARINDEX('"', s.lat_dms) > 0
	AND CHARINDEX('°', s.lon_dms) > 0
	AND CHARINDEX(CHAR(39), s.lon_dms) > 0
	AND CHARINDEX('"', s.lon_dms) > 0

	--si falla conversion dms a decimal
	INSERT INTO importacion.ErroresImportacion(id_log, tipo_archivo, registro_origen, dato1, dato2, motivo)
	SELECT  @id_log,@tipo_archivo, v.nombre, s.lat_dms, s.lon_dms, 'Conversion DMS dio NULL'
	FROM #validos v
	INNER JOIN #staging s ON v.nombre = s.nombre
	WHERE (v.latitud IS NULL OR v.longitud IS NULL);

	DELETE FROM #validos
	WHERE latitud IS NULL OR longitud IS NULL;

	--AÑADIR TIPOS DE PARQUES DESDE KML (UPSERT
	UPDATE tp
	SET estado = 0
	FROM parques.TipoParque tp
	INNER JOIN (SELECT DISTINCT cat_gral FROM #validos WHERE cat_gral IS NOT NULL) v
	ON tp.descripcion = v.cat_gral COLLATE DATABASE_DEFAULT;

	INSERT INTO parques.TipoParque(descripcion, estado)
	SELECT DISTINCT v.cat_gral, 0
	FROM #validos v
	WHERE v.cat_gral IS NOT NULL
		AND NOT EXISTS (
			SELECT 1 FROM parques.TipoParque tp
			WHERE tp.descripcion = v.cat_gral COLLATE DATABASE_DEFAULT
		);

	--si categoria gral no matchea tipo parque
	INSERT INTO importacion.ErroresImportacion (id_log,tipo_archivo, registro_origen, dato1, dato2, motivo)
	SELECT @id_log,@tipo_archivo,v.nombre, v.cat_gral, NULL,
			CONCAT('Tipo de parque no encontrado: ', v.cat_gral)
	FROM #validos v
	LEFT JOIN parques.TipoParque tp
		ON descripcion = v.cat_gral COLLATE DATABASE_DEFAULT
	WHERE tp.id_tipo_parque IS NULL;

	DELETE FROM #validos
	WHERE cat_gral IS NOT NULL
	AND NOT EXISTS(
		SELECT 1 FROM parques.TipoParque tp
		WHERE tp.descripcion = #validos.cat_gral COLLATE DATABASE_DEFAULT
	);

	-- upsert

	BEGIN TRY
		BEGIN TRANSACTION;
		UPDATE p
			SET 
			latitud = v.latitud,
			longitud = v.longitud,
			superficie = v.superficie,
			region = v.region,
			provincia = v.provincia
		FROM parques.Parque p
		INNER JOIN #validos v 
		ON p.nombre = v.nombre COLLATE DATABASE_DEFAULT
		
		SET @actualizados = @@ROWCOUNT;

		INSERT INTO parques.Parque(nombre, id_tipo_parque, region, provincia,
									latitud, longitud, superficie)
		SELECT v.nombre, tp.id_tipo_parque, v.region, v.provincia, v.latitud, v.longitud, v.superficie
		FROM #validos v
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
	FROM importacion.ErroresImportacion
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
	
END;
GO

