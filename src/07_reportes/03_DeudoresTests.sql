-- ============================================================
-- INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
-- Descripción: Testing del Reporte 3 - Estado de pagos de concesiones.
--              Verifica ejecución sin error y valida los montos de deuda
--              contra una consulta de control independiente.
-- ============================================================
USE ParquesNacionales;
GO

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