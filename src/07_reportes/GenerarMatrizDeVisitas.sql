--	21/06/2026
-- INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
-- Descripcion: Creacion de reporte de matriz de visitas por mes por parque

USE ParquesNacionales;
GO

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
