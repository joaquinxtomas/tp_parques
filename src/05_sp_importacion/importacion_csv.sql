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