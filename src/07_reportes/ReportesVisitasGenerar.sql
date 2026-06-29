-- ============================================================
-- FECHA: 27/06/2026
-- INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
-- Descripción: Generacion de SP para reporte 1 (Visitas por parque semanales, mensuales y anuales
-- ============================================================

use ParquesNacionales
GO

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
