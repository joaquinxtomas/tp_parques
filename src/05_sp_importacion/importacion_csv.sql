USE ParquesNacionales
GO

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

--TESTEANDO CON CSV CRUDO SIN NADA 
--modifico estructura de meses solo por ahora (creo que lo voy a dejar)
/*ALTER TABLE ventas.RegistroVentas
DROP CONSTRAINT CK_RegistroVentas_Mes;

ALTER TABLE ventas.RegistroVentas
ALTER COLUMN mes VARCHAR(20) NOT NULL;*/

--tabla de staging
IF EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'importacion' AND TABLE_NAME = 'CSVCrudoVisitas'
)
DROP TABLE importacion.CSVCrudoVisitas;
GO

CREATE TABLE importacion.CSVCrudoVisitas (
    anio             VARCHAR(10),
    region           VARCHAR(100),
    mes              VARCHAR(20),
    provincia        VARCHAR(100),
    nombre_parque    VARCHAR(200),
    total_visitantes VARCHAR(50),
    residentes       VARCHAR(50),
    no_residentes    VARCHAR(50)
);
GO

CREATE OR ALTER PROCEDURE importacion.ImportarVisitasCSV
	@ruta_archivo VARCHAR(500)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @id_log INT;
	DECLARE @leidos INT = 0;

	INSERT INTO importacion.LogImportacion(tipo_archivo, nombre_archivo, detalle)
	VALUES('YVERA_VISITAS', @ruta_archivo, 'En proceso');

	SET @id_log = SCOPE_IDENTITY();

	DELETE FROM importacion.CSVCrudoVisitas;

	BEGIN TRY
		DECLARE @sql VARCHAR(MAX) = '
			BULK INSERT importacion.CSVCrudoVisitas
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
		SET detalle = 'Error al leer el archivo: ' + LEFT(ERROR_MESSAGE(), 400),
		errores = 1
		WHERE id_log = @id_log;
		RETURN;
	END CATCH;

	SELECT @leidos = COUNT(*) FROM importacion.CSVCrudoVisitas;

	INSERT INTO ventas.RegistroVentas (
		id_parque, region, anio, mes,total_visitantes, residentes, no_residentes
	)
	SELECT
		p.id_parque,
		TRIM(s.region),
		TRY_CAST(TRIM(s.anio) AS INT),
		TRIM(s.mes),
		TRY_CAST(TRIM(s.total_visitantes) AS INT),
		TRY_CAST(TRIM(s.residentes) AS INT),
		TRY_CAST(TRIM(s.no_residentes) AS INT)
	FROM importacion.CSVCrudoVisitas s
	LEFT JOIN parques.Parque p
		ON p.nombre = TRIM(s.nombre_parque) COLLATE DATABASE_DEFAULT
	WHERE TRIM(ISNULL(s.nombre_parque, '')) <> '';

	DECLARE @insertados INT = @@ROWCOUNT;

	UPDATE importacion.LogImportacion
	SET registros_ok = @insertados,
	errores = @leidos - @insertados,
	detalle = CONCAT('Leidos: ', @leidos, '- Insertados: ', @insertados)
	WHERE id_log = @id_log;
END;
GO

-- probando 
EXEC importacion.ImportarVisitasCSV
	@ruta_archivo = 'C:\datasets finales\areas_protegidas.csv';

SELECT * FROM importacion.LogImportacion ORDER BY fecha DESC;
SELECT * FROM ventas.RegistroVentas

DELETE FROM ventas.RegistroVentas

SELECT COUNT(*) AS sin_parque
FROM ventas.RegistroVentas
WHERE id_parque IS NULL

SELECT DISTINCT s.nombre_parque
FROM importacion.CSVCrudoVisitas s
LEFT JOIN parques.Parque p
	ON p.nombre = TRIM(s.nombre_parque) COLLATE DATABASE_DEFAULT
WHERE p.id_parque IS NULL
AND TRIM(ISNULL(s.nombre_parque, '')) <> ''
ORDER BY s.nombre_parque;


---------------------------------------------------------------------------
--------------------------INSERTANDO REALMENTE
---------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE descripcion = 'Residente')
    INSERT INTO ventas.TipoVisitante (descripcion) VALUES ('Residente');

IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE descripcion = 'No residente')
    INSERT INTO ventas.TipoVisitante (descripcion) VALUES ('No residente');
GO

SELECT * FROM ventas.TipoVisitante;

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
	DECLARE @id_tipo_no_residente INT; --extranjero
	DECLARE @tamanio_grupo INT = 100;

	-- LOG INICIAL
	INSERT INTO importacion.LogImportacion(tipo_archivo, nombre_archivo, detalle)
	VALUES('YVERA_VISITAS', @ruta_archivo, 'En proceso');

	SET @id_log = SCOPE_IDENTITY();

	SELECT @id_tipo_residente = id_tipo_visitante 
		FROM ventas.TipoVisitante WHERE descripcion = 'Residente'; --obtener id tipo residente

	SELECT @id_tipo_no_residente = id_tipo_visitante 
		FROM ventas.TipoVisitante WHERE descripcion = 'No residente'; -- obtener id tipo no residente

	IF @id_tipo_residente IS NULL OR @id_tipo_no_residente IS NULL
	BEGIN
		UPDATE importacion.LogImportacion
		SET detalle = 'Faltan tipos de visitante (TipoVisitante)', errores = 1
		WHERE id_log = @id_log
		RETURN;
	END

	-- TABLA STAGING (INTERMEDIA) TEMPORAL
	CREATE TABLE #staging (
		anio VARCHAR(10),
		region VARCHAR(100),
		mes VARCHAR(20),
		provincia VARCHAR(100),
		nombre_parque VARCHAR(200),
		total_visitantes VARCHAR(50),
		residentes VARCHAR(50),
		no_residentes VARCHAR(50)
	);

	--LECTURA DE ARCHIVO
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
		UPDATE importacion.LogImportacion --actualizo log si hay un error al abrir el archivo
		SET detalle = 'Error al abrir el archivo: ' + LEFT(ERROR_MESSAGE(), 400), errores = 1
		WHERE id_log = @id_log;
		RETURN;
	END CATCH;

	SELECT @leidos = COUNT(*) FROM #staging;

	--CREACION DE TABLA TEMPORAL DE ERRORES 
	CREATE TABLE #errores (
		nombre_parque VARCHAR(200),
		anio VARCHAR(10),
		mes VARCHAR(20),
		motivo VARCHAR(200)
	);

	--ERRORES AL LEER
	INSERT INTO #errores (nombre_parque, anio, mes, motivo)
	SELECT nombre_parque, anio, mes, 'No posee nombre de parque' --Error si no hay nombre de parque
	FROM #staging
	WHERE TRIM(ISNULL(nombre_parque, '')) = '';
	
	INSERT INTO #errores(nombre_parque, anio, mes, motivo)
	SELECT nombre_parque, anio, mes, 'Año o mes inválido'
	FROM #staging
	WHERE TRIM(ISNULL(nombre_parque, '')) <> ''
	  AND (TRY_CAST(anio AS INT) IS NULL OR ventas.nombreMesANro(mes) IS NULL);

	INSERT INTO #errores(nombre_parque, anio, mes, motivo) --Error si no encuentra el parque en parques.Parque
	SELECT s.nombre_parque, s.anio, s.mes, 
			CONCAT('Parque no encontrado: ', s.nombre_parque)
	FROM #staging s
	LEFT JOIN parques.Parque p
		ON p.nombre = TRIM(s.nombre_parque) COLLATE DATABASE_DEFAULT
	WHERE TRIM(ISNULL(s.nombre_parque, '')) <> ''
	AND TRY_CAST(s.anio AS INT) IS NOT NULL
	AND ventas.nombreMesANro(s.mes) IS NOT NULL
	AND p.id_parque IS NULL;

	--REGISTROS VALIDOS
	CREATE TABLE #validos (
		id_parque INT,
		fecha DATE,
		residentes INT,
		no_residentes INT
	);

	INSERT INTO #validos(id_parque,fecha,residentes, no_residentes)
	SELECT
		p.id_parque,
		DATEFROMPARTS(TRY_CAST(s.anio AS INT), ventas.nombreMesANro(s.mes),1), -- setea primer parametro año, segundo mes, tercero primer dia de mes
		ISNULL(TRY_CAST(s.residentes AS INT), 0),
		ISNULL(TRY_CAST(s.no_residentes AS INT),0)
	FROM #staging s
	INNER JOIN parques.Parque p
		ON p.nombre = TRIM(s.nombre_parque) COLLATE DATABASE_DEFAULT
	WHERE TRIM(ISNULL(s.nombre_parque, '')) <> ''
	AND TRY_CAST(s.anio AS INT ) IS NOT NULL
	AND ventas.nombreMesANro(s.mes) IS NOT NULL
	AND NOT EXISTS(
		SELECT 1 FROM ventas.Entrada e
		WHERE e.id_parque = p.id_parque
		AND e.fecha = DATEFROMPARTS(TRY_CAST(s.anio AS INT), ventas.nombreMesANro(mes), 1)
		AND e.origen = 'IMPORTADO'
	);

	-- GENERACION DE ENTRADAS Y TICKETS VISITANTE
	--numeros auxiliares
	CREATE TABLE #nums (n INT PRIMARY KEY);
	INSERT INTO #nums(n)
	SELECT TOP 1000 ROW_NUMBER() OVER (ORDER BY(SELECT NULL))
	FROM sys.all_objects a CROSS JOIN sys.all_objects b;

	--tabla de grupos para dividir entradas y tickets
	CREATE TABLE #grupos (
		orden INT IDENTITY(1,1) PRIMARY KEY,
		id_parque INT,
		fecha DATE,
		id_tipo_visitante INT,
		cantidad INT
	);
	---------------------------------------------------------------------- ????
	--grupo de residentes
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

	--grupo de no residentes
	INSERT INTO #grupos(id_parque,fecha,id_tipo_visitante,cantidad)
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
	-----------------------------------------------------------------------------???

	--captura ids insertados recien
	DECLARE @ids_entrada TABLE(
		orden INT IDENTITY(1,1) PRIMARY KEY,
		id_entrada INT
	);

	--INSERTAR ENTRADAS
	INSERT INTO ventas.Entrada(id_parque, pto_venta, fecha, total, forma_pago, nro_ticket, origen)
	OUTPUT inserted.id_entrada INTO @ids_entrada (id_entrada)
	SELECT 
		g.id_parque,
		1,
		g.fecha,
		0,
		'Efectivo',
		-g.orden,
		'IMPORTADO'
	FROM #grupos g
	ORDER BY g.orden;

	--ACTUALIZAR TICKET
	UPDATE e
	SET nro_ticket = e.id_parque  * 1000000 + e.id_entrada
	FROM ventas.Entrada e
	WHERE EXISTS(
		SELECT 1 
		FROM @ids_entrada i
		WHERE i.id_entrada = e.id_entrada
	);

	--INSERTAR TICKETS
	INSERT INTO ventas.TicketVisitante(id_entrada, id_tipo_visitante, cantidad, precio_unit, subtotal)
	SELECT 
		i.id_entrada,
		g.id_tipo_visitante,
		g.cantidad,
		0,
		0
	FROM #grupos g
	INNER JOIN @ids_entrada i ON g.orden = i.orden;

	--info final
	SELECT @entradas_insertadas = COUNT(*) FROM #grupos;
	SELECT @tickets_insertados = @@ROWCOUNT;
	SELECT @errores = COUNT(*) FROM #errores;

	--LOG FINAL
	UPDATE importacion.LogImportacion
	SET 
		registros_ok = @entradas_insertadas,
		errores = @errores,
		detalle = CASE WHEN @errores > 0 THEN 'Completado con ' + CAST(@errores AS VARCHAR) + 'errores' ELSE 'Completado con exito' END
	WHERE id_log = @id_log;

	if @errores > 0
		SELECT * FROM #errores;
END;
GO

EXEC importacion.ImportarVisitasCSV
	@ruta_archivo = 'C:\datasets finales\areas_protegidas.csv'

SELECT * FROM ventas.Entrada
SELECT * FROM ventas.TicketVisitante

SELECT @@TRANCOUNT