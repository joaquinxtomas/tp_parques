-- ============================================================
-- FECHA: 28/06/2026
-- INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
-- Descripción: Reporte 5 - Parques y concesiones (XML). Lista los parques
--              que tienen concesiones activas, con sus concesiones anidadas
--              (titular, servicio, fechas y valor del canon).
-- ============================================================
USE ParquesNacionales;
GO

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