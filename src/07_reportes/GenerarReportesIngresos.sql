USE ParquesNacionales
GO


CREATE OR ALTER PROCEDURE reportes.GenerarReporteIngresosMensual
	@id_parque INT = NULL,
	@Finic	DATE = NULL,
	@Ffin	DATE = NULL
AS
BEGIN
	 -- Validación: si pasan un parque, que exista
    IF @id_parque IS NOT NULL AND NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @id_parque)
    BEGIN
        RAISERROR('El parque indicado no existe.', 16, 1);
        RETURN;
    END
	SELECT
        p.nombre              AS parque,
        YEAR(e.fecha)         AS anio,
        MONTH(e.fecha)        AS mes,
        SUM(subtotal)      AS inrgesos_visitas
    FROM ventas.Entrada AS e
		INNER JOIN ventas.TicketVisitante AS tv
    ON e.id_entrada = tv.id_ticket
		INNER JOIN parques.Parque AS p
    ON e.id_parque = p.id_parque
	WHERE (@id_parque   IS NULL OR e.id_parque = @id_parque)
		AND (@Finic IS NULL OR e.fecha >= @Finic)
		AND (@Ffin IS NULL OR e.fecha <= @Ffin)
	GROUP BY p.nombre, YEAR(e.fecha), MONTH(e.fecha)
    ORDER BY p.nombre, anio, mes;
	--IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE 
END
go


CREATE OR ALTER PROCEDURE reportes.GenerarReporteIngresosAnual
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
        SUM(subtotal)      AS inrgesos_visitas
    FROM ventas.Entrada AS e
        INNER JOIN ventas.TicketVisitante AS tv
            ON e.id_entrada = tv.id_ticket
        INNER JOIN parques.Parque AS p
            ON e.id_parque = p.id_parque
    WHERE (@id_parque IS NULL OR e.id_parque = @id_parque)
        AND (@Finic IS NULL OR e.fecha >= @Finic)
        AND (@Ffin  IS NULL OR e.fecha <= @Ffin)
    GROUP BY p.nombre, YEAR(e.fecha)
    ORDER BY p.nombre, anio;
END
GO

CREATE OR ALTER PROCEDURE reportes.GenerarReporteIngresosSemanal
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
        DATEPART(WEEK, e.fecha)   AS semana,
        SUM(subtotal)      AS inrgesos_visitas
    FROM ventas.Entrada AS e
        INNER JOIN ventas.TicketVisitante AS tv
            ON e.id_entrada = tv.id_ticket
        INNER JOIN parques.Parque AS p
            ON e.id_parque = p.id_parque
    WHERE (@id_parque IS NULL OR e.id_parque = @id_parque)
        AND (@Finic IS NULL OR e.fecha >= @Finic)
        AND (@Ffin  IS NULL OR e.fecha <= @Ffin)
    GROUP BY p.nombre, YEAR(e.fecha), DATEPART(WEEK, e.fecha)
    ORDER BY p.nombre, anio, semana;
END
GO

EXEC reportes.GenerarReporteIngresosMensual;
EXEC reportes.GenerarReporteVisitasMensual @id_parque = 1;
EXEC reportes.GenerarReporteVisitasMensual @Finic = '2026-03-01', @Ffin = '2026-04-30';