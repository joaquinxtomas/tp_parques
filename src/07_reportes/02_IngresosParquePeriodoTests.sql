-- ============================================================
-- UTN - 3641 Bases de Datos Aplicada
-- Sistema de Gestión para Parques Nacionales
-- FECHA: 29/06/2026
-- INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
-- Descripción: Testing del Reporte 2 - Ingresos por parque (mensual, anual, semanal).
--              Verifica ejecución, filtro por parque, rechazo de parque inexistente,
--              y contrasta los totales contra una consulta de control independiente.
-- ============================================================
USE ParquesNacionales;
GO

-- Referencia: parque con ingresos por concesiones (para casos OK con datos)
SELECT TOP 1 c.id_parque, p.nombre, SUM(pc.monto) AS ingreso_concesiones
FROM concesiones.PagoConcesion pc
INNER JOIN concesiones.Concesion c ON c.id_concesion = pc.id_concesion
INNER JOIN parques.Parque p ON p.id_parque = c.id_parque
WHERE pc.estado = 0
GROUP BY c.id_parque, p.nombre
ORDER BY ingreso_concesiones DESC;
GO

-- ============================================================
-- MENSUAL
-- ============================================================

-- CASO 1: sin parámetro -> todos los parques. Esperado: OK con filas
BEGIN TRY
    EXEC reportes.GenerarReporteIngresosMensual;
    PRINT 'CASO 1 OK: ingresos mensual sin filtro ejecutado';
END TRY
BEGIN CATCH
    PRINT 'CASO 1 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 2: filtrado por un parque con concesiones. Esperado: OK, solo ese parque
BEGIN TRY
    DECLARE @p INT = (
        SELECT TOP 1 c.id_parque
        FROM concesiones.PagoConcesion pc
        INNER JOIN concesiones.Concesion c ON c.id_concesion = pc.id_concesion
        WHERE pc.estado = 0
        GROUP BY c.id_parque ORDER BY SUM(pc.monto) DESC
    );
    EXEC reportes.GenerarReporteIngresosMensual @id_parque = @p;
    PRINT 'CASO 2 OK: ingresos mensual filtrado por parque con datos';
END TRY
BEGIN CATCH
    PRINT 'CASO 2 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 3: parque inexistente. Esperado: RECHAZO
BEGIN TRY
    EXEC reportes.GenerarReporteIngresosMensual @id_parque = 999999;
    PRINT 'CASO 3 FALLO: no debería haber ejecutado';
END TRY
BEGIN CATCH
    PRINT 'CASO 3 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- ANUAL
-- ============================================================

-- CASO 4: sin parámetro. Esperado: OK
BEGIN TRY
    EXEC reportes.GenerarReporteIngresosAnual;
    PRINT 'CASO 4 OK: ingresos anual sin filtro ejecutado';
END TRY
BEGIN CATCH
    PRINT 'CASO 4 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 5: parque inexistente. Esperado: RECHAZO
BEGIN TRY
    EXEC reportes.GenerarReporteIngresosAnual @id_parque = 999999;
    PRINT 'CASO 5 FALLO: no debería haber ejecutado';
END TRY
BEGIN CATCH
    PRINT 'CASO 5 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- SEMANAL
-- ============================================================

-- CASO 6: sin parámetro. Esperado: OK (datos de período se concentran
--         en pocas semanas por ser mensuales)
BEGIN TRY
    EXEC reportes.GenerarReporteIngresosSemanal;
    PRINT 'CASO 6 OK: ingresos semanal sin filtro ejecutado';
END TRY
BEGIN CATCH
    PRINT 'CASO 6 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 7: parque inexistente. Esperado: RECHAZO
BEGIN TRY
    EXEC reportes.GenerarReporteIngresosSemanal @id_parque = 999999;
    PRINT 'CASO 7 FALLO: no debería haber ejecutado';
END TRY
BEGIN CATCH
    PRINT 'CASO 7 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- CASO 8: CONTROL - el total de concesiones del reporte debe coincidir
-- con la suma directa de PagoConcesion (vía independiente).
-- ============================================================
SELECT
    p.nombre                AS parque,
    SUM(pc.monto)           AS total_concesiones_control
FROM concesiones.PagoConcesion pc
INNER JOIN concesiones.Concesion c ON c.id_concesion = pc.id_concesion
INNER JOIN parques.Parque p ON p.id_parque = c.id_parque
WHERE pc.estado = 0
GROUP BY p.nombre
ORDER BY p.nombre;
GO