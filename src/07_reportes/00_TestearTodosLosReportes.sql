-- ============================================================
-- FECHA: 27/06/2026
-- INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
-- Descripción: Testing de todos los reportes
-- ============================================================
USE ParquesNacionales;
GO

-- ============================================================
--					TEST REPORTE 1
-- ============================================================


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

-- ============================================================
--					TEST REPORTE 2
-- ============================================================

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

-- ============================================================
--					TEST REPORTE 3
-- ============================================================

-- ============================================================
-- CASO 1: el reporte ejecuta sin error y devuelve XML
-- Esperado: OK, se muestra el XML de estado de pagos
-- ============================================================
BEGIN TRY
    EXEC reportes.ReporteEstadoPagosGenerar;
    PRINT 'CASO 1 OK: el reporte se ejecutó y devolvió resultado';
END TRY
BEGIN CATCH
    PRINT 'CASO 1 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- CASO 2: CONTROL de la lógica de deuda por vía independiente
-- Calcula meses esperados vs pagados con una resta directa
-- (sin CTE recursiva), para contrastar con el meses_adeudados
-- que informa el reporte.
-- Esperado: los meses_adeudados_control deben coincidir con
-- los <meses_adeudados> del XML (Restaurante=1, Souvenirs=1).
-- ============================================================
DECLARE @hoy DATE = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);

SELECT
    c.id_concesion,
    e.razon_social                                    AS empresa,
    c.tipo_actividad                                  AS concesion,
    -- meses que debería haber pagado: desde el inicio hasta hoy
    -- (o hasta fecha_fin si ya venció), inclusive
    DATEDIFF(MONTH, c.fecha_inicio,
        CASE WHEN c.fecha_fin IS NOT NULL AND c.fecha_fin < @hoy
             THEN c.fecha_fin ELSE @hoy END) + 1      AS meses_esperados,
    -- meses efectivamente pagados (solo pagos vivos)
    COUNT(pc.id_pago)                                 AS meses_pagados,
    -- diferencia = lo adeudado segun este control
    DATEDIFF(MONTH, c.fecha_inicio,
        CASE WHEN c.fecha_fin IS NOT NULL AND c.fecha_fin < @hoy
             THEN c.fecha_fin ELSE @hoy END) + 1
        - COUNT(pc.id_pago)                           AS meses_adeudados_control
FROM concesiones.Concesion c
INNER JOIN concesiones.Empresa e ON e.id_empresa = c.id_empresa
LEFT JOIN concesiones.PagoConcesion pc
    ON pc.id_concesion = c.id_concesion AND pc.estado = 0
WHERE c.estado = 0
GROUP BY c.id_concesion, e.razon_social, c.tipo_actividad, c.fecha_inicio, c.fecha_fin
ORDER BY c.id_concesion;
GO

-- ============================================================
-- CASO 3: EVIDENCIA - pagos vivos cargados (datos manipulados)
-- Muestra los pagos reales que alimentan el reporte, para
-- corroborar a ojo los estados PAGADO/ADEUDADO del XML.
-- ============================================================
SELECT
    e.razon_social   AS empresa,
    c.tipo_actividad AS concesion,
    pc.periodo,
    pc.monto,
    pc.fecha_pago,
    pc.estado
FROM concesiones.PagoConcesion pc
INNER JOIN concesiones.Concesion c ON c.id_concesion = pc.id_concesion
INNER JOIN concesiones.Empresa e   ON e.id_empresa   = c.id_empresa
WHERE c.estado = 0
ORDER BY c.id_concesion, pc.periodo;
GO

-- ============================================================
--					TEST REPORTE 4
-- ============================================================

-- CASO 1: anio con datos -> debe devolver filas
BEGIN TRY
    EXEC reportes.GenerarMatrizVisitas @anio = 2025;
    PRINT 'CASO 1 OK: matriz generada para 2024';
END TRY
BEGIN CATCH
    PRINT 'CASO 1 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 2: anio sin datos -> debe devolver vacio (no error)
BEGIN TRY
    EXEC reportes.GenerarMatrizVisitas @anio = 1995;
    PRINT 'CASO 2 OK: ejecuta sin error (resultado vacío esperado)';
END TRY
BEGIN CATCH
    PRINT 'CASO 2 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 3: anio invalido (NULL) -> RECHAZO
BEGIN TRY
    EXEC reportes.GenerarMatrizVisitas @anio = NULL;
    PRINT 'CASO 3 FALLO: no debería haber ejecutado';
END TRY
BEGIN CATCH
    PRINT 'CASO 3 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 4: anio absurdo -> RECHAZO
BEGIN TRY
    EXEC reportes.GenerarMatrizVisitas @anio = 1850;
    PRINT 'CASO 4 FALLO: no debería haber ejecutado';
END TRY
BEGIN CATCH
    PRINT 'CASO 4 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
--					TEST REPORTE 5
-- ============================================================

-- ============================================================
-- CASO 1: el reporte ejecuta sin error y devuelve XML
-- Esperado: OK, se muestra el XML de parques y concesiones
-- ============================================================
BEGIN TRY
    EXEC reportes.ReporteParquesConcesionesGenerar;
    PRINT 'CASO 1 OK: el reporte se ejecutó y devolvió resultado';
END TRY
BEGIN CATCH
    PRINT 'CASO 1 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- CASO 2: CONTROL - cuántos parques deberían aparecer
-- El reporte solo lista parques con al menos una concesión activa.
-- Esperado: este número debe coincidir con la cantidad de <Parque>
-- del XML (con tus datos: 6 parques).
-- ============================================================
SELECT COUNT(DISTINCT c.id_parque) AS parques_con_concesiones_esperados
FROM concesiones.Concesion c
WHERE c.estado = 0;
GO

-- ============================================================
-- CASO 3: CONTROL / EVIDENCIA - detalle plano de lo que debe
-- mostrar el XML (parque + sus concesiones activas).
-- Sirve para corroborar a ojo contra el XML: mismos parques,
-- mismos titulares, mismas concesiones.
-- Nahuel Huapi debe aparecer con 2 filas (vector de 2 elementos).
-- ============================================================
SELECT
    p.nombre          AS parque,
    e.razon_social    AS titular,
    c.tipo_actividad  AS servicio,
    c.fecha_inicio,
    c.fecha_fin,
    c.valor_alquiler
FROM parques.Parque p
INNER JOIN concesiones.Concesion c ON c.id_parque  = p.id_parque AND c.estado = 0
INNER JOIN concesiones.Empresa e   ON e.id_empresa = c.id_empresa
WHERE p.estado = 0
ORDER BY p.nombre, c.fecha_inicio;
GO

-- ============================================================
-- CASO 4: CONTROL - parques con MÁS de una concesión
-- Verifica que el "vector anidado" realmente agrupe varios
-- elementos bajo un mismo parque.
-- Esperado: Nahuel Huapi con 2 concesiones.
-- ============================================================
SELECT
    p.nombre                AS parque,
    COUNT(*)                AS cant_concesiones
FROM parques.Parque p
INNER JOIN concesiones.Concesion c ON c.id_parque = p.id_parque AND c.estado = 0
WHERE p.estado = 0
GROUP BY p.nombre
HAVING COUNT(*) > 1
ORDER BY p.nombre;
GO