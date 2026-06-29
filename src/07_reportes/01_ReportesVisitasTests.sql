-- ============================================================
-- FECHA: 27/06/2026
-- INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
-- Descripción: Testing de los reportes de visitas (mensual, anual, semanal).
--              Casos OK y de rechazo esperado.
-- ============================================================
USE ParquesNacionales;
GO

-- Referencia: parque con más visitas (para validar a ojo los casos OK)
SELECT TOP 1 e.id_parque, p.nombre, SUM(tv.cantidad) AS visitas
FROM ventas.Entrada e
INNER JOIN ventas.TicketVisitante tv ON tv.id_entrada = e.id_entrada
INNER JOIN parques.Parque p ON p.id_parque = e.id_parque
WHERE e.estado = 0
GROUP BY e.id_parque, p.nombre
ORDER BY visitas DESC;
GO

-- ============================================================
-- MENSUAL
-- ============================================================

-- CASO 1: sin parámetros -> todos los parques/fechas. Esperado: OK, devuelve filas
BEGIN TRY
    EXEC reportes.GenerarReporteVisitasMensual;
    PRINT 'CASO 1 OK: mensual sin filtros ejecutado';
END TRY
BEGIN CATCH
    PRINT 'CASO 1 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 2: filtrado por rango de fechas (2024). Esperado: OK, solo filas de 2024
BEGIN TRY
    EXEC reportes.GenerarReporteVisitasMensual
        @Finic = '2024-01-01', @Ffin = '2024-12-31';
    PRINT 'CASO 2 OK: mensual filtrado por año 2024';
END TRY
BEGIN CATCH
    PRINT 'CASO 2 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 3: parque existente con datos. Esperado: OK, solo ese parque
BEGIN TRY
    DECLARE @p INT = (
        SELECT TOP 1 e.id_parque
        FROM ventas.Entrada e
        INNER JOIN ventas.TicketVisitante tv ON tv.id_entrada = e.id_entrada
        WHERE e.estado = 0
        GROUP BY e.id_parque ORDER BY SUM(tv.cantidad) DESC
    );
    EXEC reportes.GenerarReporteVisitasMensual @id_parque = @p;
    PRINT 'CASO 3 OK: mensual filtrado por parque con datos';
END TRY
BEGIN CATCH
    PRINT 'CASO 3 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 4: parque inexistente. Esperado: RECHAZO ('El parque indicado no existe')
BEGIN TRY
    EXEC reportes.GenerarReporteVisitasMensual @id_parque = 999999;
    PRINT 'CASO 4 FALLO: no debería haber ejecutado';
END TRY
BEGIN CATCH
    PRINT 'CASO 4 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- ANUAL
-- ============================================================

-- CASO 5: sin parámetros -> serie por año de todos los parques. Esperado: OK
BEGIN TRY
    EXEC reportes.GenerarReporteVisitasAnual;
    PRINT 'CASO 5 OK: anual sin filtros ejecutado';
END TRY
BEGIN CATCH
    PRINT 'CASO 5 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 6: parque existente. Esperado: OK, evolución anual de ese parque
BEGIN TRY
    DECLARE @p2 INT = (
        SELECT TOP 1 e.id_parque
        FROM ventas.Entrada e
        INNER JOIN ventas.TicketVisitante tv ON tv.id_entrada = e.id_entrada
        WHERE e.estado = 0
        GROUP BY e.id_parque ORDER BY SUM(tv.cantidad) DESC
    );
    EXEC reportes.GenerarReporteVisitasAnual @id_parque = @p2;
    PRINT 'CASO 6 OK: anual filtrado por parque con datos';
END TRY
BEGIN CATCH
    PRINT 'CASO 6 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 7: parque inexistente. Esperado: RECHAZO
BEGIN TRY
    EXEC reportes.GenerarReporteVisitasAnual @id_parque = 999999;
    PRINT 'CASO 7 FALLO: no debería haber ejecutado';
END TRY
BEGIN CATCH
    PRINT 'CASO 7 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- SEMANAL
-- ============================================================

-- CASO 8: sin parámetros. Esperado: OK (datos importados se concentran en
--         pocas semanas por ser mensuales; las ventas transaccionales del
--         seed muestran el comportamiento semanal real)
BEGIN TRY
    EXEC reportes.GenerarReporteVisitasSemanal;
    PRINT 'CASO 8 OK: semanal sin filtros ejecutado';
END TRY
BEGIN CATCH
    PRINT 'CASO 8 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 9: filtrado por rango acotado (enero 2026, Nahuel Huapi tiene 2 ventas
--         en la misma semana en el seed). Esperado: OK, se ve agrupación semanal
BEGIN TRY
    EXEC reportes.GenerarReporteVisitasSemanal
        @Finic = '2026-01-01', @Ffin = '2026-01-31';
    PRINT 'CASO 9 OK: semanal filtrado enero 2026';
END TRY
BEGIN CATCH
    PRINT 'CASO 9 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 10: parque inexistente. Esperado: RECHAZO
BEGIN TRY
    EXEC reportes.GenerarReporteVisitasSemanal @id_parque = 999999;
    PRINT 'CASO 10 FALLO: no debería haber ejecutado';
END TRY
BEGIN CATCH
    PRINT 'CASO 10 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO