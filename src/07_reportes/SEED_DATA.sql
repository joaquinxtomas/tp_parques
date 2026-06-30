use ParquesNacionales
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


-- ============================================================
--				Seed de empresas, concesiones y pagos.
--              Cubre: concesión vencida, próxima a vencer, deudoras de
--              varios meses, al día, y deudor total (sin pagos).
-- ============================================================
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