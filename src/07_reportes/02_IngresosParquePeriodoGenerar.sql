-- ============================================================
-- FECHA: 29/06/2026
-- INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
-- Descripción: Reporte 2 - Ingresos mensuales por parque. Suma entradas,
--              tours/actividades y canon de concesiones cobradas.
-- ============================================================
USE ParquesNacionales;
GO

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
