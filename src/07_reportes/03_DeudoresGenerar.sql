-- ============================================================
-- FECHA: 28/06/2026
-- INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
-- Descripción: Reporte 3 - Estado de pagos de concesiones (XML).
-- ============================================================
USE ParquesNacionales;
GO

CREATE OR ALTER PROCEDURE reportes.ReporteEstadoPagosGenerar
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @mesActual DATE = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1); --tomo el mes actual del año actual con el primer dia como referencia

    ;WITH MesesEsperados AS (
        -- Aca defino cuando arranco la concesion, osea desde cuando tiene q haber pagado
        SELECT
            c.id_concesion,
            c.id_empresa,
            c.tipo_actividad,
            c.valor_alquiler,
            c.fecha_inicio AS periodo,
            CASE WHEN c.fecha_fin IS NOT NULL AND c.fecha_fin < @mesActual  -- si la fecha de fin ya paso, toma la fecha en que finalizo como tope
                 THEN c.fecha_fin ELSE @mesActual END AS tope -- si no, toma el mes actual del año actual como tope hasta donde comparar
        FROM concesiones.Concesion c -- de la lista de concesiones
        WHERE c.estado = 0 -- y que sean registros validos 
        UNION ALL
        -- aca selecciono el periodo de inicio que cargue previamente y le sumo uno, luego se lo union all con el que ya tenia (mes++)
        SELECT
            id_concesion, id_empresa, tipo_actividad, valor_alquiler,
            DATEADD(MONTH, 1, periodo), tope
        FROM MesesEsperados
        WHERE DATEADD(MONTH, 1, periodo) <= tope -- hasta que llegue al tope definido antes
    ), -- aca llego con Meses esperados cargado con todos los meses que se deberia haber pagado esa concesion
    Calendario AS ( -- me armo un calendario para ir cargando adeudados y pagados
        -- cruzo los meses esperados con los pagos vivos para saber el estado de cada mes
        SELECT
            me.id_concesion,
            me.id_empresa,
            me.tipo_actividad,
            me.periodo,
            me.valor_alquiler,
            pc.monto       AS monto_pagado,
            pc.fecha_pago,
            CASE WHEN pc.id_pago IS NULL -- HAGO UN IF PARA ASIGNAR ADEUDAdo
                 THEN 'ADEUDADO'
                 ELSE 'PAGADO'
            END            AS estado_pago,
            CASE WHEN pc.id_pago IS NULL THEN 1 ELSE 0 END AS es_deuda -- bandera para contar/sumar deuda
        FROM MesesEsperados me
        LEFT JOIN concesiones.PagoConcesion pc
            ON pc.id_concesion = me.id_concesion
           AND pc.periodo      = me.periodo
           AND pc.estado       = 0
    )
    -- NIVEL EXTERNO: una <Concesion> por cada concesion activa
    SELECT
        e.razon_social                          AS empresa,
        cal.tipo_actividad                      AS concesion,
        SUM(cal.es_deuda)                       AS meses_adeudados, -- cuantos meses debe
        SUM(cal.es_deuda * cal.valor_alquiler)  AS deuda_total,     -- cuanto debe en total
        (
            -- NIVEL INTERNO: el calendario mes a mes de ESTA concesion (sub-xml anidado)
            SELECT
                CONVERT(VARCHAR(7), c2.periodo, 120) AS periodo, -- formato 'YYYY-MM'
                c2.estado_pago                        AS estado,
                c2.valor_alquiler                     AS monto_esperado,
                c2.monto_pagado                       AS monto_pagado,
                c2.fecha_pago                         AS fecha_pago
            FROM Calendario c2
            WHERE c2.id_concesion = cal.id_concesion -- correlaciono: solo los meses de esta concesion
            ORDER BY c2.periodo
            FOR XML PATH('Mes'), TYPE -- TYPE = inserta el sub-xml como xml real, no como texto
        ) AS Meses
    FROM Calendario cal
    INNER JOIN concesiones.Empresa e ON e.id_empresa = cal.id_empresa
    GROUP BY e.razon_social, cal.tipo_actividad, cal.id_concesion
    ORDER BY e.razon_social
    FOR XML PATH('Concesion'), ROOT('EstadoPagos'); -- cada fila -> <Concesion>, todo envuelto en <EstadoPagos>
END
GO
