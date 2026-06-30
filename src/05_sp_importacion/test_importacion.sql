USE ParquesNacionales
GO

--TESTING IMPORTACION KML 

-- 1. ejecución básica
EXEC importacion.ImportarParquesKML
     @ruta_archivo = 'C:\datasets finales\parques.kml';
go

-- 2. Verificar resultado
SELECT * FROM parques.Parque
SELECT * FROM parques.TipoParque
SELECT COUNT(*) FROM parques.Parque;
SELECT COUNT(*) FROM parques.TipoParque;
GO

-- 3. verificar ultimo log y detalles de errores
DECLARE @ultimo_log INT = (
	SELECT MAX(id_log) FROM importacion.LogImportacion
	WHERE tipo_archivo = 'SIB_KML'
)
SELECT * FROM importacion.LogImportacion
WHERE id_log = @ultimo_log;
SELECT * FROM importacion.ErroresImportacion
WHERE id_log = @ultimo_log
GO

-- 4. verificar upsert, no debe duplicar nada
DECLARE @cantidad_antes INT = (SELECT COUNT(*) FROM parques.Parque);

EXEC importacion.ImportarParquesKML
	@ruta_archivo = 'C:\datasets finales\parques.kml';

SELECT COUNT(*) AS cantidad_actual, @cantidad_antes as cantidad_antes
FROM parques.Parque
GO

-- 5. verificar el upsert de tipo parque
DECLARE @cantidad_antes INT = (SELECT COUNT(*) FROM parques.TipoParque);

EXEC importacion.ImportarParquesKML
	@ruta_archivo = 'C:\datasets finales\parques.kml';

SELECT COUNT(*) AS cantidad_actual, @cantidad_antes as cantidad_antes
FROM parques.TipoParque
GO

-- 6. verificar que el sp realmente actualiza valores
DECLARE @nombre_parque_test VARCHAR(200) = (SELECT TOP 1 nombre FROM parques.Parque);

UPDATE parques.Parque
SET superficie = 1 --superficie 1 irreal
WHERE nombre = @nombre_parque_test

SELECT nombre, superficie FROM parques.Parque WHERE nombre = @nombre_parque_test

EXEC importacion.ImportarParquesKML
	@ruta_archivo = 'C:\datasets finales\parques.kml';

SELECT nombre as nombre_despues, superficie as superficie_despues 
FROM parques.Parque WHERE nombre = @nombre_parque_test --deberia volver a su superficie real
GO

-- 7. test con archivo controlado (test_parques.kml)
EXEC importacion.ImportarParquesKML
	@ruta_archivo = 'C:\datasets finales\test_parques.kml';

SELECT * FROM parques.Parque WHERE nombre = 'Parque Test Válido'

DECLARE @ultimo_log INT = (
	SELECT MAX(id_log) FROM importacion.LogImportacion
	WHERE tipo_archivo = 'SIB_KML'
)
SELECT * FROM importacion.LogImportacion
WHERE id_log = @ultimo_log;
SELECT * FROM importacion.ErroresImportacion
WHERE id_log = @ultimo_log
GO

-- 8. test con archivo que no existe
EXEC importacion.ImportarParquesKML
	@ruta_archivo = 'C:\datasets finales\inexistente.kml';

DECLARE @ultimo_log INT = (
	SELECT MAX(id_log) FROM importacion.LogImportacion
	WHERE tipo_archivo = 'SIB_KML'
)
SELECT * FROM importacion.LogImportacion
WHERE id_log = @ultimo_log;
GO

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- TESTING IMPORTACION CSV

--PRECONDICIONES (IMPORTACION DE PARQUES - DATA SEED)

-- 1. ejecucion basica
EXEC importacion.ImportarVisitasCSV
    @ruta_archivo = 'C:\datasets finales\areas_protegidas.csv';

-- 2. check de tablas de entrada y ticket visitante y sus cantidades
SELECT DISTINCT tv.id_tipo_visitante, t.descripcion FROM ventas.TicketVisitante tv
INNER JOIN ventas.TipoVisitante t ON tv.id_tipo_visitante = t.id_tipo_visitante 
SELECT * FROM ventas.Entrada

-- 3. verificar cantidades de cada uno
SELECT COUNT(*) as entradas_importadas
FROM ventas.Entrada
WHERE origen = 'importado';

SELECT COUNT(*) as tickets_importados
FROM ventas.Entrada e
INNER JOIN ventas.TicketVisitante tv ON tv.id_entrada = e.id_entrada
WHERE e.origen = 'importado';
GO

-- 4. check de logImportacion (solo visualiza log mas reciente)
DECLARE @ultimo_log INT = (SELECT MAX(id_log) FROM importacion.LogImportacion WHERE tipo_archivo = 'yvera_visitas')
SELECT * FROM importacion.LogImportacion
WHERE id_log = @ultimo_log;

SELECT motivo, COUNT(*) as cantidad FROM importacion.ErroresImportacion
WHERE id_log = @ultimo_log
GROUP BY motivo
ORDER BY cantidad DESC;
GO

-- 5. verificar que no duplica entradas
DECLARE @entradas_antes INT = (SELECT COUNT(*) FROM ventas.Entrada WHERE origen = 'importado');

EXEC importacion.ImportarVisitasCSV
     @ruta_archivo = 'c:\datasets finales\areas_protegidas.csv';

SELECT COUNT(*) AS entradas_despues, @entradas_antes AS entradas_antes
FROM ventas.Entrada WHERE origen = 'importado';
GO

-- 6. verificar que no duplica ticket visitante
DECLARE @tickets_antes INT = (
	SELECT COUNT(*) FROM ventas.Entrada e 
	INNER JOIN ventas.TicketVisitante tv ON tv.id_entrada = e.id_entrada
	WHERE e.origen = 'importado');

EXEC importacion.ImportarVisitasCSV
     @ruta_archivo = 'c:\datasets finales\areas_protegidas.csv';

SELECT COUNT(*) AS tickets_despues, @tickets_antes AS tickets_antes 
FROM ventas.Entrada e
INNER JOIN ventas.TicketVisitante tv ON tv.id_entrada = e.id_entrada
WHERE e.origen = 'importado';
GO

-- 7. test con archivo 
EXEC importacion.ImportarVisitasCSV
     @ruta_archivo = 'c:\datasets finales\test_parques.csv';

DECLARE @ultimo_log INT =(
	SELECT MAX(id_log) FROM importacion.LogImportacion
	WHERE tipo_archivo = 'yvera_visitas'
)

SELECT *
FROM importacion.ErroresImportacion
WHERE id_log = @ultimo_log
GO

-- 8. test con archivo que no existe
EXEC importacion.ImportarVisitasCSV
     @ruta_archivo = 'c:\datasets finales\inexistente.csv';

SELECT TOP 1 * FROM importacion.LogImportacion
WHERE tipo_archivo ='yvera_visitas'
ORDER BY id_log DESC

-- 9. test sin tipos de visitante cargados 
BEGIN TRANSACTION test_tipos_faltantes;

UPDATE ventas.tipoVisitante SET descripcion = 'testeo' WHERE descripcion = 'Adulto';

DECLARE @entradas_antes INT = (SELECT COUNT(*) FROM ventas.Entrada WHERE origen = 'importado');

EXEC importacion.ImportarVisitasCSV
     @ruta_archivo = 'c:\datasets finales\areas_protegidas.csv';

SELECT TOP 1 * FROM importacion.LogImportacion
WHERE tipo_archivo = 'YVERA_VISITAS'
ORDER BY id_log DESC;

SELECT COUNT(*) AS entradas_despues, @entradas_antes AS entradas_antes
FROM ventas.Entrada WHERE origen = 'IMPORTADO';

ROLLBACK TRANSACTION test_tipos_faltantes;
GO
