USE ParquesNacionales
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

    DECLARE @id_tipo_residente INT;
    DECLARE @id_tipo_no_residente INT;
    DECLARE @tamanio_grupo INT = 100;
    DECLARE @tipo_archivo VARCHAR(50) = 'YVERA_VISITAS';

    -- LOG INICIAL
    INSERT INTO importacion.LogImportacion (tipo_archivo, nombre_archivo, detalle)
    VALUES (@tipo_archivo, @ruta_archivo, 'En proceso');

    SET @id_log = SCOPE_IDENTITY();

    -- OBTENER IDS TIPO VISITANTE (RESIDENTE Y NO RESIDENTE SON LOS UNICOS QUE VIENEN EN EL ARCHIVO)

    SELECT @id_tipo_residente = id_tipo_visitante
    FROM ventas.TipoVisitante WHERE descripcion = 'Residente';

    SELECT @id_tipo_no_residente = id_tipo_visitante
    FROM ventas.TipoVisitante WHERE descripcion = 'No residente';

    IF @id_tipo_residente IS NULL OR @id_tipo_no_residente IS NULL
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


    -- GENERAR GRUPOS
    CREATE TABLE #nums (n INT PRIMARY KEY);
    INSERT INTO #nums (n)
    SELECT TOP 2500 ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
    FROM sys.all_objects a CROSS JOIN sys.all_objects b;

    CREATE TABLE #grupos (
        orden             INT IDENTITY(1,1) PRIMARY KEY,
        id_parque         INT,
        fecha             DATE,
        id_tipo_visitante INT,
        cantidad          INT
    );

    -- grupos de residentes
    INSERT INTO #grupos (id_parque, fecha, id_tipo_visitante, cantidad)
    SELECT
        v.id_parque,
        v.fecha,
        @id_tipo_residente,
        CASE
            WHEN n.n * @tamanio_grupo <= v.residentes THEN @tamanio_grupo
            ELSE v.residentes - ((n.n - 1) * @tamanio_grupo)
        END
    FROM #validos v
    INNER JOIN #nums n
        ON n.n <= CEILING(CAST(v.residentes AS DECIMAL) / @tamanio_grupo)
    WHERE v.residentes > 0;

    -- grupos de no residentes
    INSERT INTO #grupos (id_parque, fecha, id_tipo_visitante, cantidad)
    SELECT
        v.id_parque,
        v.fecha,
        @id_tipo_no_residente,
        CASE
            WHEN n.n * @tamanio_grupo <= v.no_residentes THEN @tamanio_grupo
            ELSE v.no_residentes - ((n.n - 1) * @tamanio_grupo)
        END
    FROM #validos v
    INNER JOIN #nums n
        ON n.n <= CEILING(CAST(v.no_residentes AS DECIMAL) / @tamanio_grupo)
    WHERE v.no_residentes > 0;

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
            0,
            0
        FROM #grupos g
        INNER JOIN ventas.Entrada e
            ON e.nro_ticket = -g.orden
           AND e.pto_venta = 0
           AND e.origen = 'IMPORTADO';

        SET @tickets_insertados = @@ROWCOUNT;

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