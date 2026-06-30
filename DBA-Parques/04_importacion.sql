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
		    WHEN s.lat_dms IS NOT NULL 
			 AND CHARINDEX('°', s.lat_dms) > 0
			 AND CHARINDEX(CHAR(39), s.lat_dms) > 0
			 AND CHARINDEX('"', s.lat_dms) > 0
			THEN
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

				)
			ELSE NULL
		END,
		
		CASE 
			WHEN s.lon_dms IS NOT NULL
			AND CHARINDEX('°', s.lon_dms) > 0
			AND CHARINDEX(CHAR(39), s.lon_dms) > 0
			AND CHARINDEX('"', s.lon_dms) > 0
			THEN
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
				)
			ELSE NULL
		END,
		s.provincia,
		s.region_dnc
	FROM #staging s
	WHERE s.nombre IS NOT NULL

	-- si una coordenada falló, anular ambas
	UPDATE #validos
	SET latitud = NULL,
		longitud = NULL
	WHERE latitud IS NULL OR longitud IS NULL;

	--si falla conversion dms a decimal
	INSERT INTO importacion.ErroresImportacion(id_log, tipo_archivo, registro_origen, dato1, dato2, motivo)
	SELECT  @id_log,@tipo_archivo, v.nombre, s.lat_dms, s.lon_dms, 'Conversion DMS dio NULL'
	FROM #validos v
	INNER JOIN #staging s ON v.nombre = s.nombre
	WHERE (v.latitud IS NULL OR v.longitud IS NULL);

	--AÑADIR TIPOS DE PARQUES DESDE KML (UPSERT)
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



--FUNCION QUE RECIBE MES EN NOMBRE Y DEVUELVE EN NUMERO
CREATE OR ALTER FUNCTION ventas.nombreMesANro(
	@nombre_mes VARCHAR(20)
)
RETURNS INT
AS
BEGIN
	RETURN 
		CASE LOWER(TRIM(@nombre_mes))
			WHEN 'enero' THEN 1
			WHEN 'febrero' THEN 2
			WHEN 'marzo' THEN 3
			WHEN 'abril' THEN 4
			WHEN 'mayo' THEN 5
			WHEN 'junio' THEN 6
			WHEN 'julio' THEN 7
			WHEN 'agosto' THEN 8
			WHEN 'septiembre' THEN 9
			WHEN 'octubre' THEN 10
			WHEN 'noviembre' THEN 11
			WHEN 'diciembre' THEN 12
			ELSE NULL
	END;
END
GO

-------------------------------------------------------------------
------------------COMIENZA IMPORTACION CSV------------------------
CREATE OR ALTER PROCEDURE importacion.ImportarVisitasCSV
    @ruta_archivo VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @id_log INT;
    DECLARE @leidos INT = 0;
    DECLARE @entradas_insertadas INT = 0;
    DECLARE @tickets_insertados INT = 0;
    DECLARE @errores INT = 0;
    DECLARE @detalle VARCHAR(500) = '';

    DECLARE @pct_adulto DECIMAL(4,2) = 0.60;
    DECLARE @pct_jubilado DECIMAL(4,2) = 0.20;
    DECLARE @pct_estudiante DECIMAL(4,2) = 0.15;

    DECLARE @id_tipo_adulto INT;
    DECLARE @id_tipo_jubilado INT;
    DECLARE @id_tipo_estudiante INT;
    DECLARE @id_tipo_discapacitado INT;
    DECLARE @id_tipo_no_residente INT;

    DECLARE @tamanio_grupo INT = 100;
    DECLARE @tipo_archivo VARCHAR(50) = 'YVERA_VISITAS';

    -- LOG INICIAL
    INSERT INTO importacion.LogImportacion (tipo_archivo, nombre_archivo, detalle)
    VALUES (@tipo_archivo, @ruta_archivo, 'En proceso');

    SET @id_log = SCOPE_IDENTITY();

    SELECT @id_tipo_adulto = id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Adulto';
    SELECT @id_tipo_jubilado = id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Jubilado';
    SELECT @id_tipo_estudiante = id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Estudiante';
    SELECT @id_tipo_discapacitado = id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Discapacitado';
    SELECT @id_tipo_no_residente = id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'No residente';

    IF @id_tipo_adulto IS NULL OR @id_tipo_jubilado IS NULL OR @id_tipo_estudiante IS NULL OR @id_tipo_discapacitado IS NULL
        OR @id_tipo_no_residente IS NULL
    BEGIN
        UPDATE importacion.LogImportacion
        SET detalle = 'Faltan tipos de visitante (TipoVisitante)', errores = 1
        WHERE id_log = @id_log;
        RETURN;
    END

    -- TABLA STAGING

    CREATE TABLE #staging (
        anio             VARCHAR(10),
        region           VARCHAR(100),
        mes              VARCHAR(20),
        provincia        VARCHAR(100),
        nombre_parque    VARCHAR(200),
        total_visitantes VARCHAR(50),
        residentes       VARCHAR(50),
        no_residentes    VARCHAR(50)
    );

    BEGIN TRY
        DECLARE @sql VARCHAR(MAX) = '
            BULK INSERT #staging
            FROM ''' + @ruta_archivo + '''
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = '','',
                ROWTERMINATOR = ''0x0a'',
                CODEPAGE = ''65001'',
                TABLOCK
            );';
        EXEC(@sql);
    END TRY
    BEGIN CATCH
        UPDATE importacion.LogImportacion
        SET detalle = 'Error al abrir el archivo: ' + LEFT(ERROR_MESSAGE(), 400), errores = 1
        WHERE id_log = @id_log;
        RETURN;
    END CATCH;

    SELECT @leidos = COUNT(*) FROM #staging;

    -- ERRORES

    -- sin nombre
    INSERT INTO importacion.ErroresImportacion(id_log, tipo_archivo, registro_origen, dato1, dato2,motivo)
    SELECT @id_log, @tipo_archivo, nombre_parque, anio, mes, 'No posee nombre de parque'
    FROM #staging
    WHERE TRIM(ISNULL(nombre_parque, '')) = '';

    -- año o mes inválido
    INSERT INTO importacion.ErroresImportacion(id_log, tipo_archivo, registro_origen, dato1, dato2, motivo)
    SELECT @id_log, @tipo_archivo, nombre_parque, anio, mes, 'Año o mes inválido'
    FROM #staging
    WHERE TRIM(ISNULL(nombre_parque, '')) <> ''
      AND (TRY_CAST(anio AS INT) IS NULL OR ventas.nombreMesANro(mes) IS NULL);

    -- existen 3 parques que no coinciden con el nombre que está en la tabla parques, por lo que se decide crear
    -- una tabla temporal para poder hacer match correctamente.
    CREATE TABLE #alias_parques(
        nombre_csv VARCHAR(200) PRIMARY KEY,
        nombre_real VARCHAR(200) NOT NULL
    );

    INSERT INTO #alias_parques(nombre_csv, nombre_real) VALUES
    ('Pre Delta', 'Predelta'),
    ('Bosques Petrificados', 'Bosques Petrificados de Jaramillo'),
    ('Ansenuza','Anzenuza');

    -- parque no encontrado
    INSERT INTO importacion.ErroresImportacion(id_log, tipo_archivo, registro_origen, dato1, dato2, motivo)
    SELECT @id_log, @tipo_archivo, s.nombre_parque, s.anio, s.mes,
           CONCAT('Parque no encontrado: ', s.nombre_parque)
    FROM #staging s
    LEFT JOIN parques.Parque p
        ON p.nombre = COALESCE( 
            (SELECT nombre_real FROM #alias_parques WHERE nombre_csv = TRIM(s.nombre_parque)),
            TRIM(s.nombre_parque)
        ) COLLATE DATABASE_DEFAULT
    WHERE TRIM(ISNULL(s.nombre_parque, '')) <> ''
      AND TRY_CAST(s.anio AS INT) IS NOT NULL
      AND ventas.nombreMesANro(s.mes) IS NOT NULL
      AND p.id_parque IS NULL;

    -- REGISTROS VALIDOS
    CREATE TABLE #validos (
        id_parque     INT,
        fecha         DATE,
        residentes    INT,
        no_residentes INT
    );

    INSERT INTO #validos (id_parque, fecha, residentes, no_residentes)
    SELECT
        p.id_parque,
        DATEFROMPARTS(TRY_CAST(s.anio AS INT), ventas.nombreMesANro(s.mes), 1),
        ISNULL(TRY_CAST(s.residentes AS INT), 0),
        ISNULL(TRY_CAST(s.no_residentes AS INT), 0)
    FROM #staging s
    INNER JOIN parques.Parque p
        ON p.nombre = COALESCE(
            (SELECT nombre_real FROM #alias_parques WHERE nombre_csv = TRIM(s.nombre_parque)),
            TRIM(s.nombre_parque)
        ) COLLATE DATABASE_DEFAULT
    WHERE TRIM(ISNULL(s.nombre_parque, '')) <> ''
      AND TRY_CAST(s.anio AS INT) IS NOT NULL
      AND ventas.nombreMesANro(s.mes) IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM ventas.Entrada e
          WHERE e.id_parque = p.id_parque
            AND e.fecha = DATEFROMPARTS(TRY_CAST(s.anio AS INT), ventas.nombreMesANro(s.mes), 1)
            AND e.origen = 'IMPORTADO'
      );

    -- REPARTE RESIDENTES EN DIFERENTES TIPOS DE VISITANTE
    CREATE TABLE #cantidades (
        id_parque INT,
        fecha DATE,
        id_tipo_visitante INT,
        cantidad INT
    );

    INSERT INTO #cantidades(id_parque, fecha, id_tipo_visitante, cantidad)
    SELECT v.id_parque, v.fecha, @id_tipo_adulto, FLOOR(v.residentes * @pct_adulto)
    FROM #validos v
    WHERE v.residentes > 0

    UNION ALL 

    SELECT v.id_parque, v.fecha, @id_tipo_jubilado, FLOOR(v.residentes * @pct_jubilado)
    FROM #validos v
    WHERE v.residentes > 0

    UNION ALL 

    SELECT v.id_parque, v.fecha, @id_tipo_estudiante, FLOOR(v.residentes * @pct_estudiante)
    FROM #validos v
    WHERE v.residentes > 0

    UNION ALL 

    --tipo visitante discapacitado absorve los restos de otros
    SELECT 
        v.id_parque, v.fecha, @id_tipo_discapacitado, v.residentes
        - FLOOR(v.residentes * @pct_adulto) 
        - FLOOR(v.residentes * @pct_jubilado)
        - FLOOR(v.residentes * @pct_estudiante)
    FROM #validos v
    WHERE v.residentes > 0

    UNION ALL 
    
    SELECT v.id_parque, v.fecha, @id_tipo_no_residente, v.no_residentes
    FROM #validos v
    WHERE v.no_residentes > 0;

    ALTER TABLE #cantidades ADD precio DECIMAL(10,2) NULL;
    UPDATE c
    SET c.precio = pe.precio
    FROM #cantidades c
    LEFT JOIN ventas.PrecioEntrada pe
        ON pe.id_parque = c.id_parque
    AND pe.id_tipo_visitante = c.id_tipo_visitante
    AND pe.fecha_inicio <= c.fecha
    AND (pe.fecha_fin IS NULL OR pe.fecha_fin >= c.fecha)
    AND pe.estado = 0;

    -- GENERAR GRUPOS

    -- genera tabla de numeros consecutivos del 1 al 2500 (iguazú, el parque que mas grupos necesita, necesita 2500).
    CREATE TABLE #nums (n INT PRIMARY KEY); 
    INSERT INTO #nums (n)
    SELECT TOP 2500 ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
    FROM sys.all_objects a CROSS JOIN sys.all_objects b;

    CREATE TABLE #grupos (
        orden INT IDENTITY(1,1) PRIMARY KEY,
        id_parque INT,
        fecha DATE,
        id_tipo_visitante INT,
        cantidad INT,
        precio DECIMAL(10,2)
    );

    INSERT INTO #grupos (id_parque, fecha, id_tipo_visitante, cantidad, precio)
    SELECT
        c.id_parque,
        c.fecha,
        c.id_tipo_visitante,
        CASE 
            WHEN n.n * @tamanio_grupo <= c.cantidad THEN @tamanio_grupo
            ELSE c.cantidad - ((n.n - 1) * @tamanio_grupo)
        END,
        c.precio
    FROM #cantidades c
    INNER JOIN #nums n
    -- divide el grupo siempre y cuando n.n sea menor a la cantidad de grupos necesarios.
        ON n.n <= CEILING(CAST(c.cantidad AS DECIMAL) / @tamanio_grupo)
    WHERE c.cantidad > 0;

    -- INSERTAR ENTRADAS Y TICKETS
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Limpiar nro_tickets negativos de corridas previas que hayan quedado colgados
        DELETE tv
        FROM ventas.TicketVisitante tv
        INNER JOIN ventas.Entrada e ON e.id_entrada = tv.id_entrada
        WHERE e.pto_venta = 0 AND e.nro_ticket < 0 AND e.origen = 'IMPORTADO';

        DELETE FROM ventas.Entrada
        WHERE pto_venta = 0 AND nro_ticket < 0 AND origen = 'IMPORTADO';

        -- insertar entradas
        INSERT INTO ventas.Entrada (id_parque, pto_venta, fecha, total, forma_pago, nro_ticket, origen)
        SELECT
            g.id_parque,
            0,
            g.fecha,
            0,
            'Efectivo',
            -g.orden,
            'IMPORTADO'
        FROM #grupos g;

        SET @entradas_insertadas = @@ROWCOUNT;

        -- insertar ticket visitante
        INSERT INTO ventas.TicketVisitante (id_entrada, id_tipo_visitante, cantidad, precio_unit, subtotal)
        SELECT
            e.id_entrada,
            g.id_tipo_visitante,
            g.cantidad,
            COALESCE(g.precio, 0),
            g.cantidad * COALESCE(g.precio, 0)
        FROM #grupos g
        INNER JOIN ventas.Entrada e
            ON e.nro_ticket = -g.orden
           AND e.pto_venta = 0
           AND e.origen = 'IMPORTADO'
           
        SET @tickets_insertados = @@ROWCOUNT;


        UPDATE ventas.Entrada
        SET total = (
            SELECT SUM(tv.subtotal) 
            FROM ventas.TicketVisitante tv 
            WHERE tv.id_entrada = ventas.Entrada.id_entrada
        )
        WHERE origen = 'IMPORTADO'
          AND pto_venta = 0
          AND nro_ticket < 0;

        -- actualizar nro_ticket a valores finales
        UPDATE ventas.Entrada
        SET nro_ticket = id_entrada
        WHERE pto_venta = 0
          AND origen = 'IMPORTADO'
          AND nro_ticket < 0;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        UPDATE importacion.LogImportacion
        SET detalle = 'Error en inserción: ' + LEFT(ERROR_MESSAGE(), 400),
            errores = @leidos
        WHERE id_log = @id_log;
        RETURN;
    END CATCH;

    -- LOG FINAL
    SET @errores = (SELECT COUNT(*) FROM importacion.ErroresImportacion WHERE id_log = @id_log);

    SET @detalle = CONCAT(
        'Leídos: ',                 @leidos,
        ' - Entradas insertadas: ', @entradas_insertadas,
        ' - Tickets insertados: ',  @tickets_insertados,
        ' - Errores: ',             @errores
    );

    UPDATE importacion.LogImportacion
    SET registros_ok = @entradas_insertadas,
        errores      = @errores,
        detalle      = @detalle
    WHERE id_log = @id_log;

END;
GO
