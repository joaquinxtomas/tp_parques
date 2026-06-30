-- 29/06/2026
-- INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
-- Descripción: Carga inicial de tipos de visitante y precio de entradas.
USE ParquesNacionales;
GO

-- ============================================================
--		EJECUTAR EXCLUSIVAMENTE LUEGO DE IMPORTACION DE PARQUES
-- ============================================================

DECLARE @amp INT, @mn INT, @pi INT, @pn INT, @rn INT, @rnat INT, @rne INT;

SELECT @amp  = id_tipo_parque FROM parques.TipoParque WHERE descripcion = 'ÁREA MARINA PROTEGIDA';
SELECT @mn   = id_tipo_parque FROM parques.TipoParque WHERE descripcion = 'MONUMENTO NATURAL';
SELECT @pi   = id_tipo_parque FROM parques.TipoParque WHERE descripcion = 'PARQUE INTERJURISDICCIONAL';
SELECT @pn   = id_tipo_parque FROM parques.TipoParque WHERE descripcion = 'PARQUE NACIONAL';
SELECT @rn   = id_tipo_parque FROM parques.TipoParque WHERE descripcion = 'RESERVA NACIONAL';
SELECT @rnat = id_tipo_parque FROM parques.TipoParque WHERE descripcion = 'RESERVA NATURAL';
SELECT @rne  = id_tipo_parque FROM parques.TipoParque WHERE descripcion = 'RESERVA NATURAL EDUCATIVA';

EXEC parques.InsertarParque 'Sierra Verde',            @pn,   'Centro',    'Córdoba',          -31.845200, -64.912400, 42500.00;
EXEC parques.InsertarParque 'Valle del Cóndor',        @rn,   'NOA',       'Catamarca',        -27.856300, -66.431200, 68150.00;
EXEC parques.InsertarParque 'Laguna Esmeralda',        @rnat, 'Patagonia', 'Neuquén',          -39.764200, -70.943500, 58200.00;
EXEC parques.InsertarParque 'Monte Azul',              @pi,   'Cuyo',      'San Luis',         -33.214600, -66.874300, 31400.00;
EXEC parques.InsertarParque 'Cóndor Andino',           @mn,   'NOA',       'Jujuy',            -23.615400, -65.382100, 8700.00;
EXEC parques.InsertarParque 'Golfo Escondido',         @amp,  'Patagonia', 'Chubut',           -42.786500, -64.912700, 125000.00;
EXEC parques.InsertarParque 'Bosque del Alba',         @rne,  'Patagonia', 'Río Negro',        -41.223400, -71.442300, 9200.00;
EXEC parques.InsertarParque 'Quebrada Blanca',         @pn,   'NOA',       'Salta',            -24.753800, -65.412600, 48700.00;
EXEC parques.InsertarParque 'Río de los Sauces',       @rn,   'Centro',    'Córdoba',          -32.041500, -64.511400, 24100.00;
EXEC parques.InsertarParque 'Estepa Dorada',           @rnat, 'Patagonia', 'Santa Cruz',       -48.152600, -70.514200, 119800.00;
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

-- ------------------------------------------------------------
-- EMPRESAS NUEVAS (CUITs distintos a los ya cargados)
-- ------------------------------------------------------------
BEGIN TRY EXEC concesiones.Empresa_Nueva 'Gastronomia del Litoral SA', '30715000011', 'info@litoral.com';   PRINT 'Empresa 1 OK'; END TRY BEGIN CATCH PRINT 'Empresa 1: ' + ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.Empresa_Nueva 'Souvenirs del Sur SRL',      '30715000022', 'ventas@souvsur.com';  PRINT 'Empresa 2 OK'; END TRY BEGIN CATCH PRINT 'Empresa 2: ' + ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.Empresa_Nueva 'Cabalgatas Andinas SA',      '30715000033', 'hola@cabalgatas.com'; PRINT 'Empresa 3 OK'; END TRY BEGIN CATCH PRINT 'Empresa 3: ' + ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.Empresa_Nueva 'Camping El Bosque SRL',      '30715000044', 'reservas@elbosque.com'; PRINT 'Empresa 4 OK'; END TRY BEGIN CATCH PRINT 'Empresa 4: ' + ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.Empresa_Nueva 'Cafeteria de Montaña SA',    '30715000055', 'cafe@montania.com';   PRINT 'Empresa 5 OK'; END TRY BEGIN CATCH PRINT 'Empresa 5: ' + ERROR_MESSAGE(); END CATCH
GO

-- ------------------------------------------------------------
-- CONCESIONES NUEVAS
-- Resuelvo ids de empresa (por CUIT) y parque (por nombre)
-- ------------------------------------------------------------
DECLARE @e1 INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit='30715000011');
DECLARE @e2 INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit='30715000022');
DECLARE @e3 INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit='30715000033');
DECLARE @e4 INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit='30715000044');
DECLARE @e5 INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit='30715000055');

DECLARE @p_iguazu INT = (SELECT id_parque FROM parques.Parque WHERE nombre='Iguazú');
DECLARE @p_palmar INT = (SELECT id_parque FROM parques.Parque WHERE nombre='El Palmar');
DECLARE @p_lanin  INT = (SELECT id_parque FROM parques.Parque WHERE nombre='Lanín');
DECLARE @p_calil  INT = (SELECT id_parque FROM parques.Parque WHERE nombre='Calilegua');
DECLARE @p_chaco  INT = (SELECT id_parque FROM parques.Parque WHERE nombre='Chaco');

-- Concesion_Nueva: @id_empresa, @id_parque, @tipo_actividad, @fecha_inicio, @valor_alquiler, @fecha_fin

-- (A) VENCIDA - terminó en 2024 (caso obligatorio)
BEGIN TRY EXEC concesiones.Concesion_Nueva @e1, @p_palmar, 'Restaurante', '2022-01-01', 70000.00, '2024-12-31'; PRINT 'Conc A OK'; END TRY BEGIN CATCH PRINT 'Conc A: '+ERROR_MESSAGE(); END CATCH
-- (B) PRÓXIMA A VENCER - termina en ~2 meses
BEGIN TRY EXEC concesiones.Concesion_Nueva @e2, @p_lanin, 'Tienda de souvenirs', '2024-01-01', 40000.00, '2026-08-31'; PRINT 'Conc B OK'; END TRY BEGIN CATCH PRINT 'Conc B: '+ERROR_MESSAGE(); END CATCH
-- (C) VIGENTE, deudora de VARIOS meses - empezó ene 2026, no paga desde marzo
BEGIN TRY EXEC concesiones.Concesion_Nueva @e3, @p_iguazu, 'Cabalgatas', '2026-01-01', 60000.00, '2028-12-31'; PRINT 'Conc C OK'; END TRY BEGIN CATCH PRINT 'Conc C: '+ERROR_MESSAGE(); END CATCH
-- (D) VIGENTE, al día - paga todo
BEGIN TRY EXEC concesiones.Concesion_Nueva @e4, @p_calil, 'Camping', '2026-01-01', 50000.00, '2027-12-31'; PRINT 'Conc D OK'; END TRY BEGIN CATCH PRINT 'Conc D: '+ERROR_MESSAGE(); END CATCH
-- (E) VIGENTE, deudor TOTAL - sin ningún pago
BEGIN TRY EXEC concesiones.Concesion_Nueva @e5, @p_chaco, 'Cafetería', '2026-01-01', 30000.00, NULL; PRINT 'Conc E OK'; END TRY BEGIN CATCH PRINT 'Conc E: '+ERROR_MESSAGE(); END CATCH

BEGIN TRY EXEC concesiones.Concesion_Nueva @e4, @p_calil, 'Alquiler Reposeras', '2026-01-01', 40000.00, '2027-12-31'; PRINT 'Conc F OK'; END TRY BEGIN CATCH PRINT 'Conc D: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.Concesion_Nueva @e3, @p_iguazu, 'Alquiler Parrillas', '2026-01-01', 80000.00, '2027-12-31'; PRINT 'Conc F OK'; END TRY BEGIN CATCH PRINT 'Conc D: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.Concesion_Nueva @e5, @p_iguazu, 'Kermes', '2026-01-01', 100000.00, '2027-12-31'; PRINT 'Conc F OK'; END TRY BEGIN CATCH PRINT 'Conc D: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.Concesion_Nueva @e1, @p_iguazu, 'Venta Souvenirs', '2026-01-01', 85000.00, '2027-12-31'; PRINT 'Conc F OK'; END TRY BEGIN CATCH PRINT 'Conc D: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.Concesion_Nueva @e2, @p_chaco, 'Alquiler de bicicletas', '2026-01-01', 35000.00, '2027-06-30'; PRINT 'Conc J OK'; END TRY BEGIN CATCH PRINT 'Conc J: '+ERROR_MESSAGE(); END CATCH

-- ------------------------------------------------------------
-- PAGOS
-- PagoConcesion_Nuevo: @id_concesion, @fecha_pago, @periodo, @monto
-- ------------------------------------------------------------
DECLARE @cA INT = (SELECT id_concesion FROM concesiones.Concesion WHERE id_parque=(SELECT id_parque FROM parques.Parque WHERE nombre='El Palmar') AND tipo_actividad='Restaurante' AND estado=0);
DECLARE @cB INT = (SELECT id_concesion FROM concesiones.Concesion WHERE id_parque=(SELECT id_parque FROM parques.Parque WHERE nombre='Lanín') AND tipo_actividad='Tienda de souvenirs' AND estado=0);
DECLARE @cC INT = (SELECT id_concesion FROM concesiones.Concesion WHERE id_parque=(SELECT id_parque FROM parques.Parque WHERE nombre='Iguazú') AND tipo_actividad='Cabalgatas' AND estado=0);
DECLARE @cD INT = (SELECT id_concesion FROM concesiones.Concesion WHERE id_parque=(SELECT id_parque FROM parques.Parque WHERE nombre='Calilegua') AND tipo_actividad='Camping' AND estado=0);

DECLARE @cF INT = (SELECT id_concesion FROM concesiones.Concesion WHERE id_parque=(SELECT id_parque FROM parques.Parque WHERE nombre='Calilegua') AND tipo_actividad='Alquiler Reposeras' AND estado=0);
DECLARE @cG INT = (SELECT id_concesion FROM concesiones.Concesion WHERE id_parque=(SELECT id_parque FROM parques.Parque WHERE nombre='Iguazú') AND tipo_actividad='Alquiler Parrillas' AND estado=0);
DECLARE @cH INT = (SELECT id_concesion FROM concesiones.Concesion WHERE id_parque=(SELECT id_parque FROM parques.Parque WHERE nombre='Iguazú') AND tipo_actividad='Kermes' AND estado=0);
DECLARE @cI INT = (SELECT id_concesion FROM concesiones.Concesion WHERE id_parque=(SELECT id_parque FROM parques.Parque WHERE nombre='Iguazú') AND tipo_actividad='Venta Souvenirs' AND estado=0);
DECLARE @cJ INT = (SELECT id_concesion FROM concesiones.Concesion WHERE id_parque=(SELECT id_parque FROM parques.Parque WHERE nombre='Chaco') AND tipo_actividad='Alquiler de bicicletas' AND estado=0);

-- (A) Vencida: pagó todo su contrato hasta 2024-12 (cierro los últimos meses)
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cA, '2024-12-05', '2024-11-01', 70000.00; PRINT 'Pago A1 OK'; END TRY BEGIN CATCH PRINT 'Pago A1: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cA, '2025-01-05', '2024-12-01', 70000.00; PRINT 'Pago A2 OK'; END TRY BEGIN CATCH PRINT 'Pago A2: '+ERROR_MESSAGE(); END CATCH

-- (B) Próxima a vencer: al día ene-jun 2026
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cB, '2026-02-05', '2026-01-01', 40000.00; PRINT 'Pago B1 OK'; END TRY BEGIN CATCH PRINT 'Pago B1: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cB, '2026-03-05', '2026-02-01', 40000.00; PRINT 'Pago B2 OK'; END TRY BEGIN CATCH PRINT 'Pago B2: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cB, '2026-04-05', '2026-03-01', 40000.00; PRINT 'Pago B3 OK'; END TRY BEGIN CATCH PRINT 'Pago B3: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cB, '2026-05-05', '2026-04-01', 40000.00; PRINT 'Pago B4 OK'; END TRY BEGIN CATCH PRINT 'Pago B4: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cB, '2026-06-05', '2026-05-01', 40000.00; PRINT 'Pago B5 OK'; END TRY BEGIN CATCH PRINT 'Pago B5: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cB, '2026-07-05', '2026-06-01', 40000.00; PRINT 'Pago B6 OK'; END TRY BEGIN CATCH PRINT 'Pago B6: '+ERROR_MESSAGE(); END CATCH

-- (C) Deudora de varios meses: pagó solo ene y feb 2026, debe mar-abr-may-jun (4 meses)
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cC, '2026-02-05', '2026-01-01', 60000.00; PRINT 'Pago C1 OK'; END TRY BEGIN CATCH PRINT 'Pago C1: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cC, '2026-03-05', '2026-02-01', 60000.00; PRINT 'Pago C2 OK'; END TRY BEGIN CATCH PRINT 'Pago C2: '+ERROR_MESSAGE(); END CATCH

-- (D) Al día: paga ene-jun 2026 completo
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cD, '2026-02-05', '2026-01-01', 50000.00; PRINT 'Pago D1 OK'; END TRY BEGIN CATCH PRINT 'Pago D1: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cD, '2026-03-05', '2026-02-01', 50000.00; PRINT 'Pago D2 OK'; END TRY BEGIN CATCH PRINT 'Pago D2: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cD, '2026-04-05', '2026-03-01', 50000.00; PRINT 'Pago D3 OK'; END TRY BEGIN CATCH PRINT 'Pago D3: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cD, '2026-05-05', '2026-04-01', 50000.00; PRINT 'Pago D4 OK'; END TRY BEGIN CATCH PRINT 'Pago D4: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cD, '2026-06-05', '2026-05-01', 50000.00; PRINT 'Pago D5 OK'; END TRY BEGIN CATCH PRINT 'Pago D5: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cD, '2026-07-05', '2026-06-01', 50000.00; PRINT 'Pago D6 OK'; END TRY BEGIN CATCH PRINT 'Pago D6: '+ERROR_MESSAGE(); END CATCH

BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cF, '2026-02-05', '2026-01-01', 40000.00; PRINT 'Pago F1 OK'; END TRY BEGIN CATCH PRINT 'Pago F1: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cF, '2026-03-05', '2026-02-01', 40000.00; PRINT 'Pago F2 OK'; END TRY BEGIN CATCH PRINT 'Pago F2: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cF, '2026-04-05', '2026-03-01', 40000.00; PRINT 'Pago F3 OK'; END TRY BEGIN CATCH PRINT 'Pago F3: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cF, '2026-05-05', '2026-04-01', 40000.00; PRINT 'Pago F4 OK'; END TRY BEGIN CATCH PRINT 'Pago F4: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cF, '2026-06-05', '2026-05-01', 40000.00; PRINT 'Pago F5 OK'; END TRY BEGIN CATCH PRINT 'Pago F5: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cF, '2026-07-05', '2026-06-01', 40000.00; PRINT 'Pago F6 OK'; END TRY BEGIN CATCH PRINT 'Pago F6: '+ERROR_MESSAGE(); END CATCH

BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cG, '2026-02-05', '2026-01-01', 80000.00; PRINT 'Pago G1 OK'; END TRY BEGIN CATCH PRINT 'Pago G1: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cG, '2026-03-05', '2026-02-01', 80000.00; PRINT 'Pago G2 OK'; END TRY BEGIN CATCH PRINT 'Pago G2: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cG, '2026-04-05', '2026-03-01', 80000.00; PRINT 'Pago G3 OK'; END TRY BEGIN CATCH PRINT 'Pago G3: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cG, '2026-05-05', '2026-04-01', 80000.00; PRINT 'Pago G4 OK'; END TRY BEGIN CATCH PRINT 'Pago G4: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cG, '2026-06-05', '2026-05-01', 80000.00; PRINT 'Pago G5 OK'; END TRY BEGIN CATCH PRINT 'Pago G5: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cG, '2026-07-05', '2026-06-01', 80000.00; PRINT 'Pago G6 OK'; END TRY BEGIN CATCH PRINT 'Pago G6: '+ERROR_MESSAGE(); END CATCH

BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cH, '2026-02-05', '2026-01-01', 100000.00; PRINT 'Pago H1 OK'; END TRY BEGIN CATCH PRINT 'Pago H1: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cH, '2026-03-05', '2026-02-01', 100000.00; PRINT 'Pago H2 OK'; END TRY BEGIN CATCH PRINT 'Pago H2: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cH, '2026-04-05', '2026-03-01', 100000.00; PRINT 'Pago H3 OK'; END TRY BEGIN CATCH PRINT 'Pago H3: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cH, '2026-05-05', '2026-04-01', 100000.00; PRINT 'Pago H4 OK'; END TRY BEGIN CATCH PRINT 'Pago H4: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cH, '2026-06-05', '2026-05-01', 100000.00; PRINT 'Pago H5 OK'; END TRY BEGIN CATCH PRINT 'Pago H5: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cH, '2026-07-05', '2026-06-01', 100000.00; PRINT 'Pago H6 OK'; END TRY BEGIN CATCH PRINT 'Pago H6: '+ERROR_MESSAGE(); END CATCH

BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cI, '2026-02-05', '2026-01-01', 35000.00; PRINT 'Pago J1 OK'; END TRY BEGIN CATCH PRINT 'Pago J1: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cI, '2026-03-05', '2026-02-01', 35000.00; PRINT 'Pago J2 OK'; END TRY BEGIN CATCH PRINT 'Pago J2: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cI, '2026-04-05', '2026-03-01', 35000.00; PRINT 'Pago J3 OK'; END TRY BEGIN CATCH PRINT 'Pago J3: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cI, '2026-05-05', '2026-04-01', 35000.00; PRINT 'Pago J4 OK'; END TRY BEGIN CATCH PRINT 'Pago J4: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cI, '2026-06-05', '2026-05-01', 35000.00; PRINT 'Pago J5 OK'; END TRY BEGIN CATCH PRINT 'Pago J5: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @cI, '2026-07-05', '2026-06-01', 35000.00; PRINT 'Pago J6 OK'; END TRY BEGIN CATCH PRINT 'Pago J6: '+ERROR_MESSAGE(); END CATCH

GO

-- ------------------------------------------------------------
-- VERIFICACIÓN
-- ------------------------------------------------------------
SELECT e.razon_social, c.id_concesion, p.nombre AS parque, c.tipo_actividad,
       c.fecha_inicio, c.fecha_fin, c.valor_alquiler,
       COUNT(pc.id_pago) AS pagos_vivos
FROM concesiones.Concesion c
INNER JOIN concesiones.Empresa e ON e.id_empresa = c.id_empresa
INNER JOIN parques.Parque p ON p.id_parque = c.id_parque
LEFT JOIN concesiones.PagoConcesion pc ON pc.id_concesion = c.id_concesion AND pc.estado = 0
WHERE c.estado = 0
GROUP BY e.razon_social, c.id_concesion, p.nombre, c.tipo_actividad,
         c.fecha_inicio, c.fecha_fin, c.valor_alquiler
ORDER BY c.id_concesion;
GO

-- DELETE FROM actividades.Atraccion  RESETEAR TABLA

INSERT INTO actividades.Atraccion
    (id_parque, nombre, costo, duracion, cupo_maximo, tipo, turno)
SELECT
    p.id_parque,
    a.nombre,
    a.costo,
    a.duracion,
    a.cupo_maximo,
    a.tipo,
    a.turno
FROM parques.Parque p
CROSS JOIN (
    VALUES
        ('Senderismo',             0.00,   120, NULL, 'Aventura',    CAST('09:00' AS TIME)),
        ('Avistaje de aves',       0.00,    90, NULL, 'Naturaleza',  CAST('09:00' AS TIME)),  -- mismo horario
        ('Safari fotográfico',  1500.00,  180, 15, 'Fotografía',  CAST('10:30' AS TIME)),
        ('Caminata guiada',      800.00,  120, 25, 'Senderismo',  CAST('12:00' AS TIME)),
        ('Recorrido histórico',  500.00,   60, 40, 'Cultural',    CAST('14:00' AS TIME)),
        ('Paseo en bicicleta',  1000.00,  120, 15, 'Deportivo',   CAST('15:30' AS TIME)),
        ('Charla educativa',       0.00,   45, NULL, 'Educativa',   CAST('16:30' AS TIME)),
        ('Picnic guiado',        300.00,   90, 35, 'Recreativa',  CAST('18:00' AS TIME)),
        ('Observación nocturna',1200.00,  150, 20, 'Naturaleza',  CAST('20:00' AS TIME)),
        ('Observación de flora',   0.00,   75, NULL, 'Naturaleza',  CAST('20:00' AS TIME))   -- mismo horario
) AS a(nombre, costo, duracion, cupo_maximo, tipo, turno)
WHERE p.estado = 0;

select * from actividades.Atraccion
--======================================================
--				ALTA DE GUIAS
--======================================================

-- Seed: 20 guías autorizados via personal.guiaAutorizado_alta
EXEC personal.guiaAutorizado_alta 'Martín Acuña',        '28456789', 'Trekking de montaña',      'Guía de Montaña UNComahue',        '2022-03-01', '2026-03-01';
EXEC personal.guiaAutorizado_alta 'Lucía Ferreyra',      '30112233', 'Observación de aves',       'Licenciada en Biología',           '2021-06-15', '2025-06-15';
EXEC personal.guiaAutorizado_alta 'Diego Sosa',          '27889900', 'Espeleología',              'Técnico en Turismo',               '2023-01-10', '2027-01-10';
EXEC personal.guiaAutorizado_alta 'Carla Méndez',        '32556677', 'Interpretación ambiental',  'Guía de Naturaleza',               '2020-09-01', '2024-09-01';
EXEC personal.guiaAutorizado_alta 'Federico Ramírez',    '29334455', 'Kayak y rafting',           NULL,                               '2022-11-20', '2026-11-20';
EXEC personal.guiaAutorizado_alta 'Sofía Domínguez',     '31778899', 'Flora patagónica',          'Ingeniera Forestal',               '2021-02-05', '2025-02-05';
EXEC personal.guiaAutorizado_alta 'Joaquín Vega',        '26445566', 'Alta montaña',              'Guía de Alta Montaña AAGM',        '2019-07-12', '2024-07-12';
EXEC personal.guiaAutorizado_alta 'Valentina Rojas',     '33667788', 'Senderismo familiar',       NULL,                               '2023-05-01', '2027-05-01';
EXEC personal.guiaAutorizado_alta 'Tomás Herrera',       '28990011', 'Cabalgatas',                'Técnico en Turismo Rural',         '2020-04-18', '2024-04-18';
EXEC personal.guiaAutorizado_alta 'Agustina Paredes',    '34112244', 'Fotografía de naturaleza',  'Guía de Naturaleza',               '2022-08-09', '2026-08-09';

EXEC personal.guiaAutorizado_alta 'Nicolás Castro',      '27556688', 'Glaciología',               'Licenciado en Geología',           '2021-10-30', '2025-10-30';
EXEC personal.guiaAutorizado_alta 'Florencia Aguirre',   '32889900', 'Educación ambiental',       'Profesora de Cs. Naturales',       '2023-03-22', '2027-03-22';
EXEC personal.guiaAutorizado_alta 'Mateo Giménez',       '29001122', 'Buceo en lagos',            'Guía de Buceo',                    '2020-12-01', '2024-12-01';
EXEC personal.guiaAutorizado_alta 'Camila Núñez',        '33445599', 'Observación de fauna',      'Licenciada en Cs. Biológicas',     '2022-06-14', '2026-06-14';
EXEC personal.guiaAutorizado_alta 'Lautaro Medina',      '28334477', 'Montañismo invernal',       'Guía de Montaña',                  '2021-01-08', '2025-01-08';
EXEC personal.guiaAutorizado_alta 'Julieta Romero',      '34556600', 'Botánica nativa',           NULL,                               '2023-09-15', '2027-09-15';
EXEC personal.guiaAutorizado_alta 'Bruno Ortiz',         '27778822', 'Trekking glaciar',          'Guía de Hielo',                    '2020-05-25', '2024-05-25';
EXEC personal.guiaAutorizado_alta 'Antonella Silva',     '32112255', 'Avistaje de ballenas',      'Técnica en Turismo',               '2022-02-11', '2026-02-11';
EXEC personal.guiaAutorizado_alta 'Ramiro Fernández',    '29667733', 'Escalada en roca',          'Guía de Escalada',                 '2021-08-03', '2025-08-03';
EXEC personal.guiaAutorizado_alta 'Micaela Torres',      '33990044', 'Interpretación geológica',  'Licenciada en Geología',           '2023-07-19', '2027-07-19';
GO
select * from personal.GuiaAutorizado
select * from actividades.TourGuia
--======================================================
--				ASIGNACION DE GUIAS
--======================================================
-- Resuelve id_atraccion por nombre+parque+turno; id_guia por dni.

DECLARE @g_sosa    INT = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni='27889900'); -- Espeleología, 2027
DECLARE @g_rojas   INT = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni='33667788'); -- Senderismo, 2027
DECLARE @g_paredes INT = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni='34112244'); -- Fotografía, 2026-08
DECLARE @g_aguirre INT = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni='32889900'); -- Educación, 2027
DECLARE @g_romero  INT = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni='34556600'); -- Botánica, 2027
DECLARE @g_torres  INT = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni='33990044'); -- Geología, 2027

DECLARE @p_iguazu INT = (SELECT id_parque FROM parques.Parque WHERE nombre='Iguazú');
DECLARE @p_lanin  INT = (SELECT id_parque FROM parques.Parque WHERE nombre='Lanín');
DECLARE @p_sierra INT = (SELECT id_parque FROM parques.Parque WHERE nombre='Sierra Verde');

DECLARE @a INT;

-- Safari fotográfico @ Iguazú 10:30 -> Paredes (fotografía, 2026-08)
SET @a = (SELECT id_atraccion FROM actividades.Atraccion WHERE id_parque=@p_iguazu AND nombre='Safari fotográfico' AND turno='10:30');
EXEC actividades.InsertarTourGuia @a, @g_paredes;

-- Caminata guiada @ Iguazú 12:00 -> Rojas (senderismo, 2027)
SET @a = (SELECT id_atraccion FROM actividades.Atraccion WHERE id_parque=@p_iguazu AND nombre='Caminata guiada' AND turno='12:00');
EXEC actividades.InsertarTourGuia @a, @g_rojas;

-- Recorrido histórico @ Iguazú 14:00 -> Aguirre (educación, 2027)
SET @a = (SELECT id_atraccion FROM actividades.Atraccion WHERE id_parque=@p_iguazu AND nombre='Recorrido histórico' AND turno='14:00');
EXEC actividades.InsertarTourGuia @a, @g_aguirre;

-- Observación nocturna @ Iguazú 20:00 -> Torres (geología, 2027)
SET @a = (SELECT id_atraccion FROM actividades.Atraccion WHERE id_parque=@p_iguazu AND nombre='Observación nocturna' AND turno='20:00');
EXEC actividades.InsertarTourGuia @a, @g_torres;

-- Safari fotográfico @ Lanín 10:30 -> Paredes (2026-08)
SET @a = (SELECT id_atraccion FROM actividades.Atraccion WHERE id_parque=@p_lanin AND nombre='Safari fotográfico' AND turno='10:30');
EXEC actividades.InsertarTourGuia @a, @g_paredes;

-- Caminata guiada @ Lanín 12:00 -> Sosa (2027)
SET @a = (SELECT id_atraccion FROM actividades.Atraccion WHERE id_parque=@p_lanin AND nombre='Caminata guiada' AND turno='12:00');
EXEC actividades.InsertarTourGuia @a, @g_sosa;

-- Observación de flora @ Lanín 20:00 -> Romero (botánica, 2027)
SET @a = (SELECT id_atraccion FROM actividades.Atraccion WHERE id_parque=@p_lanin AND nombre='Observación de flora' AND turno='20:00');
EXEC actividades.InsertarTourGuia @a, @g_romero;

-- Avistaje de aves @ Sierra Verde 09:00 -> Torres (2027)
SET @a = (SELECT id_atraccion FROM actividades.Atraccion WHERE id_parque=@p_sierra AND nombre='Avistaje de aves' AND turno='09:00');
EXEC actividades.InsertarTourGuia @a, @g_torres;

-- Recorrido histórico @ Sierra Verde 14:00 -> Aguirre (2027)
SET @a = (SELECT id_atraccion FROM actividades.Atraccion WHERE id_parque=@p_sierra AND nombre='Recorrido histórico' AND turno='14:00');
EXEC actividades.InsertarTourGuia @a, @g_aguirre;

-- Caminata guiada @ Sierra Verde 12:00 -> Rojas (2027)
SET @a = (SELECT id_atraccion FROM actividades.Atraccion WHERE id_parque=@p_sierra AND nombre='Caminata guiada' AND turno='12:00');
EXEC actividades.InsertarTourGuia @a, @g_rojas;
GO

/*
SELECT tg.id_tour_guia, p.nombre AS parque, a.nombre AS atraccion, a.turno,
       g.nombre AS guia, g.especialidad, g.vigencia_hasta
FROM actividades.TourGuia tg
INNER JOIN actividades.Atraccion a ON a.id_atraccion = tg.id_atraccion
INNER JOIN parques.Parque p ON p.id_parque = a.id_parque
INNER JOIN personal.GuiaAutorizado g ON g.id_guia = tg.id_guia
WHERE tg.estado = 0
ORDER BY p.nombre, a.turno;
GO
*/
--======================================================
--				ALTA DE GUARDAPARQUES
--======================================================
-- Seed: 20 guardaparques via personal.guardaparque_alta
EXEC personal.guardaparque_alta 'Esteban Quiroga',     '24556677', '2015-03-01', NULL;
EXEC personal.guardaparque_alta 'Marcela Ibáñez',      '26778899', '2016-07-15', NULL;
EXEC personal.guardaparque_alta 'Hernán Lucero',       '23445566', '2014-01-10', '2023-12-31';
EXEC personal.guardaparque_alta 'Patricia Vera',       '27889911', '2017-09-01', NULL;
EXEC personal.guardaparque_alta 'Gustavo Maldonado',   '22334455', '2013-05-20', NULL;
EXEC personal.guardaparque_alta 'Silvina Cabrera',     '28990022', '2018-02-05', NULL;
EXEC personal.guardaparque_alta 'Ricardo Peralta',     '21556688', '2012-07-12', '2022-06-30';
EXEC personal.guardaparque_alta 'Noelia Figueroa',     '29112233', '2019-05-01', NULL;
EXEC personal.guardaparque_alta 'Daniel Sandoval',     '25667700', '2015-04-18', NULL;
EXEC personal.guardaparque_alta 'Verónica Molina',     '27223344', '2017-08-09', NULL;

--EJECUTAR O NO SP DE CIFRADO

EXEC personal.guardaparque_alta'Alejandro Ríos',      '23778822', '2014-10-30', NULL;
EXEC personal.guardaparque_alta 'Gabriela Suárez',     '28445599', '2018-03-22', NULL;
EXEC personal.guardaparque_alta 'Sergio Cáceres',      '22667733', '2013-12-01', '2021-11-30';
EXEC personal.guardaparque_alta 'Lorena Benítez',      '29334466', '2019-06-14', NULL;
EXEC personal.guardaparque_alta 'Fabián Acosta',       '24990077', '2016-01-08', NULL;
EXEC personal.guardaparque_alta 'Mónica Ledesma',      '27556601', '2017-09-15', NULL;
EXEC personal.guardaparque_alta 'Pablo Miranda',       '23001144', '2014-05-25', NULL;
EXEC personal.guardaparque_alta 'Andrea Ojeda',        '28112266', '2018-02-11', NULL;
EXEC personal.guardaparque_alta 'Marcelo Villalba',    '22778844', '2013-08-03', '2023-07-31';
EXEC personal.guardaparque_alta 'Carolina Espinoza',   '29990055', '2019-07-19', NULL;
GO
/*
SELECT * FROM personal.Guardaparque
*/

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- TESTING IMPORTACION CSV

--PRECONDICIONES (IMPORTACION DE PARQUES - DATA SEED)

-- 1. ejecucion basica
EXEC importacion.ImportarVisitasCSV
    @ruta_archivo = 'C:\datasets finales\areas_protegidas.csv';

-- 2. check de tablas de entrada y ticket visitante y sus cantidades
SELECT DISTINCT tv.id_tipo_visitante, t.descripcion FROM ventas.TicketVisitante tv
INNER JOIN ventas.TipoVisitante t ON tv.id_tipo_visitante = t.id_tipo_visitante 
SELECT * FROM ventas.Entrada

-- 3. verificar cantidades de cada uno
SELECT COUNT(*) as entradas_importadas
FROM ventas.Entrada
WHERE origen = 'importado';

SELECT COUNT(*) as tickets_importados
FROM ventas.Entrada e
INNER JOIN ventas.TicketVisitante tv ON tv.id_entrada = e.id_entrada
WHERE e.origen = 'importado';
GO

-- 4. check de logImportacion (solo visualiza log mas reciente)
DECLARE @ultimo_log INT = (SELECT MAX(id_log) FROM importacion.LogImportacion WHERE tipo_archivo = 'yvera_visitas')
SELECT * FROM importacion.LogImportacion
WHERE id_log = @ultimo_log;

SELECT motivo, COUNT(*) as cantidad FROM importacion.ErroresImportacion
WHERE id_log = @ultimo_log
GROUP BY motivo
ORDER BY cantidad DESC;
GO

-- 5. verificar que no duplica entradas
DECLARE @entradas_antes INT = (SELECT COUNT(*) FROM ventas.Entrada WHERE origen = 'importado');

EXEC importacion.ImportarVisitasCSV
     @ruta_archivo = 'c:\datasets finales\areas_protegidas.csv';

SELECT COUNT(*) AS entradas_despues, @entradas_antes AS entradas_antes
FROM ventas.Entrada WHERE origen = 'importado';
GO

-- 6. verificar que no duplica ticket visitante
DECLARE @tickets_antes INT = (
	SELECT COUNT(*) FROM ventas.Entrada e 
	INNER JOIN ventas.TicketVisitante tv ON tv.id_entrada = e.id_entrada
	WHERE e.origen = 'importado');

EXEC importacion.ImportarVisitasCSV
     @ruta_archivo = 'c:\datasets finales\areas_protegidas.csv';

SELECT COUNT(*) AS tickets_despues, @tickets_antes AS tickets_antes 
FROM ventas.Entrada e
INNER JOIN ventas.TicketVisitante tv ON tv.id_entrada = e.id_entrada
WHERE e.origen = 'importado';
GO

-- 7. test con archivo 
EXEC importacion.ImportarVisitasCSV
     @ruta_archivo = 'c:\datasets finales\test_parques.csv';

DECLARE @ultimo_log INT =(
	SELECT MAX(id_log) FROM importacion.LogImportacion
	WHERE tipo_archivo = 'yvera_visitas'
)

SELECT *
FROM importacion.ErroresImportacion
WHERE id_log = @ultimo_log
GO

-- 8. test con archivo que no existe
EXEC importacion.ImportarVisitasCSV
     @ruta_archivo = 'c:\datasets finales\inexistente.csv';

SELECT TOP 1 * FROM importacion.LogImportacion
WHERE tipo_archivo ='yvera_visitas'
ORDER BY id_log DESC

-- 9. test sin tipos de visitante cargados 
BEGIN TRANSACTION test_tipos_faltantes;

UPDATE ventas.tipoVisitante SET descripcion = 'testeo' WHERE descripcion = 'Adulto';

DECLARE @entradas_antes INT = (SELECT COUNT(*) FROM ventas.Entrada WHERE origen = 'importado');

EXEC importacion.ImportarVisitasCSV
     @ruta_archivo = 'c:\datasets finales\areas_protegidas.csv';

SELECT TOP 1 * FROM importacion.LogImportacion
WHERE tipo_archivo = 'YVERA_VISITAS'
ORDER BY id_log DESC;

SELECT COUNT(*) AS entradas_despues, @entradas_antes AS entradas_antes
FROM ventas.Entrada WHERE origen = 'IMPORTADO';

ROLLBACK TRANSACTION test_tipos_faltantes;
GO
