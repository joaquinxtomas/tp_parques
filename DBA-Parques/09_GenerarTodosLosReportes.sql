-- ============================================================
-- FECHA: 28/06/2026
-- INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
-- Descripción: Genera todos los reportes de la entrega 7
-- ============================================================

USE ParquesNacionales;
GO

-- ============================================================
--				REPORTE 1
-- ============================================================

CREATE OR ALTER PROCEDURE reportes.GenerarReporteVisitasMensual
	@id_parque INT = NULL,
	@Finic	DATE = NULL,
	@Ffin	DATE = NULL
AS
BEGIN
	 -- Validación: si pasan un parque, que exista
    SET NOCOUNT ON
	IF @id_parque IS NOT NULL AND NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @id_parque)
    BEGIN
        RAISERROR('El parque indicado no existe.', 16, 1);
        RETURN;
    END
	SELECT
        p.nombre              AS parque,
        YEAR(e.fecha)         AS anio,
        MONTH(e.fecha)        AS mes,
        SUM(tv.cantidad)      AS total_visitas
    FROM ventas.Entrada AS e
		INNER JOIN ventas.TicketVisitante AS tv
    ON e.id_entrada = tv.id_entrada
		INNER JOIN parques.Parque AS p
    ON e.id_parque = p.id_parque
	WHERE (@id_parque   IS NULL OR e.id_parque = @id_parque)
		AND (@Finic IS NULL OR e.fecha >= @Finic)
		AND (@Ffin IS NULL OR e.fecha <= @Ffin)
		AND e.estado = 0
	GROUP BY p.nombre, YEAR(e.fecha), MONTH(e.fecha)
    ORDER BY p.nombre, anio, mes;
END
go


CREATE OR ALTER PROCEDURE reportes.GenerarReporteVisitasAnual
    @id_parque INT  = NULL,
    @Finic     DATE = NULL,
    @Ffin      DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @id_parque IS NOT NULL AND NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @id_parque)
    BEGIN
        RAISERROR('El parque indicado no existe.', 16, 1);
        RETURN;
    END
    SELECT
        p.nombre              AS parque,
        YEAR(e.fecha)         AS anio,
        SUM(tv.cantidad)      AS total_visitas
    FROM ventas.Entrada AS e
        INNER JOIN ventas.TicketVisitante AS tv
            ON e.id_entrada = tv.id_entrada
        INNER JOIN parques.Parque AS p
            ON e.id_parque = p.id_parque
    WHERE (@id_parque IS NULL OR e.id_parque = @id_parque)
        AND (@Finic IS NULL OR e.fecha >= @Finic)
        AND (@Ffin  IS NULL OR e.fecha <= @Ffin)
		AND e.estado = 0
    GROUP BY p.nombre, YEAR(e.fecha)
    ORDER BY p.nombre, anio;
END
GO

CREATE OR ALTER PROCEDURE reportes.GenerarReporteVisitasSemanal
    @id_parque INT  = NULL,
    @Finic     DATE = NULL,
    @Ffin      DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @id_parque IS NOT NULL AND NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @id_parque)
    BEGIN
        RAISERROR('El parque indicado no existe.', 16, 1);
        RETURN;
    END

    SELECT
        p.nombre                  AS parque,
        YEAR(e.fecha)             AS anio,
        DATEPART(ISO_WEEK, e.fecha)   AS semana,
        SUM(tv.cantidad)          AS total_visitas
    FROM ventas.Entrada AS e
        INNER JOIN ventas.TicketVisitante AS tv
            ON e.id_entrada = tv.id_entrada
        INNER JOIN parques.Parque AS p
            ON e.id_parque = p.id_parque
    WHERE (@id_parque IS NULL OR e.id_parque = @id_parque)
        AND (@Finic IS NULL OR e.fecha >= @Finic)
        AND (@Ffin  IS NULL OR e.fecha <= @Ffin)
		AND e.estado = 0
    GROUP BY p.nombre, YEAR(e.fecha), DATEPART(ISO_WEEK, e.fecha)
    ORDER BY p.nombre, anio, semana;
END
GO

-- ============================================================
--				REPORTE 2
-- ============================================================

CREATE OR ALTER PROCEDURE reportes.GenerarReporteIngresosAnual
    @id_parque INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @id_parque IS NOT NULL AND NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @id_parque)
    BEGIN
        RAISERROR('El parque indicado no existe.', 16, 1);
        RETURN;
    END

    SELECT
        p.nombre AS parque,
        ingresos.anio,
        SUM(CASE WHEN concepto = 'Entradas'    THEN monto ELSE 0 END) AS ing_entradas,
        SUM(CASE WHEN concepto = 'Tours'       THEN monto ELSE 0 END) AS ing_tours,
        SUM(CASE WHEN concepto = 'Concesiones' THEN monto ELSE 0 END) AS ing_concesiones,
        SUM(monto) AS ingreso_total
    FROM (
        -- FUENTE 1: entradas
        SELECT e.id_parque AS id_parque, YEAR(e.fecha) AS anio,
               'Entradas' AS concepto, tv.subtotal AS monto
        FROM ventas.Entrada e
        INNER JOIN ventas.TicketVisitante tv ON tv.id_entrada = e.id_entrada
        WHERE e.estado = 0

        UNION ALL

        -- FUENTE 2: tours
        SELECT a.id_parque, YEAR(ta.fecha),
               'Tours', ta.subtotal
        FROM actividades.TicketsAtraccion ta
        INNER JOIN actividades.Atraccion a ON a.id_atraccion = ta.id_atraccion
        WHERE ta.estado = 0

        UNION ALL

        -- FUENTE 3: concesiones
        SELECT c.id_parque, YEAR(pc.periodo),
               'Concesiones', pc.monto
        FROM concesiones.PagoConcesion pc
        INNER JOIN concesiones.Concesion c ON c.id_concesion = pc.id_concesion
        WHERE pc.estado = 0
    ) AS ingresos
    INNER JOIN parques.Parque p ON p.id_parque = ingresos.id_parque
    WHERE (@id_parque IS NULL OR p.id_parque = @id_parque)
    GROUP BY p.nombre, ingresos.anio
    ORDER BY p.nombre, ingresos.anio;
END
GO

CREATE OR ALTER PROCEDURE reportes.GenerarReporteIngresosMensual
    @id_parque INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validación: si pasan un parque, que exista
    IF @id_parque IS NOT NULL AND NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @id_parque)
    BEGIN
        RAISERROR('El parque indicado no existe.', 16, 1);
        RETURN;
    END

    SELECT
        p.nombre AS parque,
        ingresos.anio,
        ingresos.mes,
        SUM(CASE WHEN concepto = 'Entradas'    THEN monto ELSE 0 END) AS ing_entradas,
        SUM(CASE WHEN concepto = 'Tours'       THEN monto ELSE 0 END) AS ing_tours,
        SUM(CASE WHEN concepto = 'Concesiones' THEN monto ELSE 0 END) AS ing_concesiones,
        SUM(monto) AS ingreso_total
    FROM (
        -- FUENTE 1: entradas
        SELECT e.id_parque AS id_parque, YEAR(e.fecha) AS anio, MONTH(e.fecha) AS mes,
               'Entradas' AS concepto, tv.subtotal AS monto
        FROM ventas.Entrada e
        INNER JOIN ventas.TicketVisitante tv ON tv.id_entrada = e.id_entrada
        WHERE e.estado = 0

        UNION ALL

        -- FUENTE 2: tours
        SELECT a.id_parque, YEAR(ta.fecha), MONTH(ta.fecha),
               'Tours', ta.subtotal
        FROM actividades.TicketsAtraccion ta
        INNER JOIN actividades.Atraccion a ON a.id_atraccion = ta.id_atraccion
        WHERE ta.estado = 0

        UNION ALL

        -- FUENTE 3: concesiones
        SELECT c.id_parque, YEAR(pc.periodo), MONTH(pc.periodo),
               'Concesiones', pc.monto
        FROM concesiones.PagoConcesion pc
        INNER JOIN concesiones.Concesion c ON c.id_concesion = pc.id_concesion
        WHERE pc.estado = 0
    ) AS ingresos
    INNER JOIN parques.Parque p ON p.id_parque = ingresos.id_parque
    WHERE (@id_parque IS NULL OR p.id_parque = @id_parque)   -- filtro opcional por parque
    GROUP BY p.nombre, ingresos.anio, ingresos.mes
    ORDER BY p.nombre, ingresos.anio, ingresos.mes;
END
GO

CREATE OR ALTER PROCEDURE reportes.GenerarReporteIngresosSemanal
    @id_parque INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @id_parque IS NOT NULL AND NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @id_parque)
    BEGIN
        RAISERROR('El parque indicado no existe.', 16, 1);
        RETURN;
    END

    SELECT
        p.nombre AS parque,
        ingresos.anio,
        ingresos.semana,
        SUM(CASE WHEN concepto = 'Entradas'    THEN monto ELSE 0 END) AS ing_entradas,
        SUM(CASE WHEN concepto = 'Tours'       THEN monto ELSE 0 END) AS ing_tours,
        SUM(CASE WHEN concepto = 'Concesiones' THEN monto ELSE 0 END) AS ing_concesiones,
        SUM(monto) AS ingreso_total
    FROM (
        -- FUENTE 1: entradas
        SELECT e.id_parque AS id_parque, YEAR(e.fecha) AS anio,
               DATEPART(ISO_WEEK, e.fecha) AS semana,
               'Entradas' AS concepto, tv.subtotal AS monto
        FROM ventas.Entrada e
        INNER JOIN ventas.TicketVisitante tv ON tv.id_entrada = e.id_entrada
        WHERE e.estado = 0

        UNION ALL

        -- FUENTE 2: tours
        SELECT a.id_parque, YEAR(ta.fecha),
               DATEPART(ISO_WEEK, ta.fecha),
               'Tours', ta.subtotal
        FROM actividades.TicketsAtraccion ta
        INNER JOIN actividades.Atraccion a ON a.id_atraccion = ta.id_atraccion
        WHERE ta.estado = 0

        UNION ALL

        -- FUENTE 3: concesiones
        SELECT c.id_parque, YEAR(pc.periodo),
               DATEPART(ISO_WEEK, pc.periodo),
               'Concesiones', pc.monto
        FROM concesiones.PagoConcesion pc
        INNER JOIN concesiones.Concesion c ON c.id_concesion = pc.id_concesion
        WHERE pc.estado = 0
    ) AS ingresos
    INNER JOIN parques.Parque p ON p.id_parque = ingresos.id_parque
    WHERE (@id_parque IS NULL OR p.id_parque = @id_parque)
    GROUP BY p.nombre, ingresos.anio, ingresos.semana
    ORDER BY p.nombre, ingresos.anio, ingresos.semana;
END
GO

-- ============================================================
--				REPORTE 3
-- ============================================================

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

-- ============================================================
--				REPORTE 4
-- ============================================================

CREATE OR ALTER PROCEDURE reportes.GenerarMatrizVisitas
    @anio INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validación del parámetro: no NULL, no años absurdos ni futuros lejanos
    IF @anio IS NULL OR @anio < 1900 OR @anio > YEAR(GETDATE()) + 1
    BEGIN
        RAISERROR('El año indicado no es válido.', 16, 1);
        RETURN;
    END

    SELECT
        parque,
        ISNULL([1], 0)  AS Ene,
        ISNULL([2], 0)  AS Feb,
        ISNULL([3], 0)  AS Mar,
        ISNULL([4], 0)  AS Abr,
        ISNULL([5], 0)  AS May,
        ISNULL([6], 0)  AS Jun,
        ISNULL([7], 0)  AS Jul,
        ISNULL([8], 0)  AS Ago,
        ISNULL([9], 0)  AS Sep,
        ISNULL([10], 0) AS Oct,
        ISNULL([11], 0) AS Nov,
        ISNULL([12], 0) AS Dic,
        ISNULL([1],0)+ISNULL([2],0)+ISNULL([3],0)+ISNULL([4],0)
        +ISNULL([5],0)+ISNULL([6],0)+ISNULL([7],0)+ISNULL([8],0)
        +ISNULL([9],0)+ISNULL([10],0)+ISNULL([11],0)+ISNULL([12],0) AS Total
    FROM (
        -- Tabla larga: una fila cruda por ticket (parque, mes, cantidad).
        -- El SUM lo realiza el operador PIVOT, por eso aquí no hay GROUP BY.
        SELECT
            p.nombre         AS parque,
            MONTH(e.fecha)   AS mes,
            tv.cantidad      AS visitantes
        FROM ventas.Entrada e
        INNER JOIN ventas.TicketVisitante tv ON tv.id_entrada = e.id_entrada
        INNER JOIN parques.Parque p          ON p.id_parque = e.id_parque
        WHERE YEAR(e.fecha) = @anio
          AND e.estado = 0
    ) AS fuente
    PIVOT (
        SUM(visitantes)
        FOR mes IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])
    ) AS pvt
    ORDER BY parque;
END
GO

-- ============================================================
--				REPORTE 5
-- ============================================================

CREATE OR ALTER PROCEDURE reportes.ReporteParquesConcesionesGenerar
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.nombre        AS nombre,
        p.provincia     AS provincia,
        p.region        AS region,
        (
            SELECT -- CARGO LAS CONSECIONES ACTIVAS PARA EL PARQUE
                e.razon_social    AS titular,
                c.tipo_actividad  AS servicio,
                c.fecha_inicio    AS fecha_inicio,
                c.fecha_fin       AS fecha_fin,
                c.valor_alquiler  AS valor_alquiler
            FROM concesiones.Concesion c
            INNER JOIN concesiones.Empresa e ON e.id_empresa = c.id_empresa
            WHERE c.id_parque = p.id_parque   -- correlación con el parque externo
              AND c.estado = 0
            ORDER BY c.fecha_inicio
            FOR XML PATH('Concesion'), TYPE
        ) AS Concesiones
	FROM parques.Parque p  --FILTRO los parques que tengan AL MENOS UNA CONSECION ACTIVA
    WHERE p.estado = 0
      AND EXISTS ( -- solo parques que tengan al menos una concesión activa
            SELECT 1 FROM concesiones.Concesion c
            WHERE c.id_parque = p.id_parque AND c.estado = 0
      )
    ORDER BY p.nombre
    FOR XML PATH('Parque'), ROOT('Parques');
END
GO