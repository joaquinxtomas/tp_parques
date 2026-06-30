-- 29/06/2026
-- INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
-- Descripción: Carga inicial de tipos de visitante y precio de entradas.


USE ParquesNacionales;
GO

-- TIPOS DE VISITANTES

IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE descripcion = 'Adulto')
    INSERT INTO ventas.TipoVisitante (descripcion) VALUES ('Adulto');

IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE descripcion = 'Estudiante')
    INSERT INTO ventas.TipoVisitante (descripcion) VALUES ('Estudiante');

IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE descripcion = 'Jubilado')
    INSERT INTO ventas.TipoVisitante (descripcion) VALUES ('Jubilado');

IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE descripcion = 'Discapacitado')
    INSERT INTO ventas.TipoVisitante (descripcion) VALUES ('Discapacitado');

IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE descripcion = 'No residente')
    INSERT INTO ventas.TipoVisitante (descripcion) VALUES ('No residente');
GO

-- PRECIO ENTRADAS

-- Precios base 2008 (en pesos):
--   Adulto:        $50    Estudiante: $25    Jubilado:  $20
--   Discapacitado: $25    No residente: $100
--
-- Redondeo hacia arriba al múltiplo más cercano de:
--   $5   si precio_raw < $100
--   $50  si precio_raw está entre $100 y $999
--   $100 si precio_raw >= $1000

USE ParquesNacionales;
GO

IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE estado = 0)
BEGIN
    RAISERROR(
        'No hay parques activos en parques.Parque. Ejecutar este script después de importar los parques.',
        16, 1
    );
    RETURN;
END
GO

IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE descripcion = 'Adulto' AND estado = 0)
BEGIN
    RAISERROR(
        'Faltan tipos de visitante. Ejecutar 01_tipos_visitante.sql primero.',
        16, 1
    );
    RETURN;
END
GO

; WITH anos AS (
    SELECT 2008 AS anio
    UNION ALL
    SELECT anio + 1 FROM anos WHERE anio < 2026
),
base_precios AS (
    SELECT
        id_tipo_visitante,
        CAST(
            CASE descripcion
                WHEN 'Adulto'        THEN 50.0
                WHEN 'Estudiante'    THEN 25.0
                WHEN 'Jubilado'      THEN 20.0
                WHEN 'Discapacitado' THEN 25.0
                WHEN 'No residente'  THEN 100.0
            END
        AS FLOAT) AS base_precio
    FROM ventas.TipoVisitante
    WHERE descripcion IN ('Adulto', 'Estudiante', 'Jubilado', 'Discapacitado', 'No residente')
      AND estado = 0
),
calculos AS (
    SELECT
        p.id_parque,
        bp.id_tipo_visitante,
        a.anio,
        bp.base_precio * POWER(1.2, CAST(a.anio - 2008 AS FLOAT)) AS precio_raw
    FROM parques.Parque     p
    CROSS JOIN base_precios bp
    CROSS JOIN anos         a
    WHERE p.estado = 0
)
INSERT INTO ventas.PrecioEntrada (id_parque, id_tipo_visitante, precio, fecha_inicio, fecha_fin)
SELECT
    c.id_parque,
    c.id_tipo_visitante,
    CAST(
        CASE
            WHEN c.precio_raw < 100  THEN CEILING(c.precio_raw / 5.0)   * 5
            WHEN c.precio_raw < 1000 THEN CEILING(c.precio_raw / 50.0)  * 50
            ELSE                          CEILING(c.precio_raw / 100.0) * 100
        END
    AS DECIMAL(10, 2)),
    DATEFROMPARTS(c.anio, 1, 1),
    CASE c.anio WHEN 2026 THEN DATEFROMPARTS(2026, 5, 31) ELSE DATEFROMPARTS(c.anio, 12, 31) END
FROM calculos c
WHERE NOT EXISTS (
    SELECT 1
    FROM   ventas.PrecioEntrada pe
    WHERE  pe.id_parque         = c.id_parque
      AND  pe.id_tipo_visitante = c.id_tipo_visitante
      AND  pe.fecha_inicio      = DATEFROMPARTS(c.anio, 1, 1)
)
OPTION (MAXRECURSION 20);
GO