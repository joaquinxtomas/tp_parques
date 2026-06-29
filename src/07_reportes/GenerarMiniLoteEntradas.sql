use ParquesNacionales
GO

-- CREO TIPO DE PARQUE
EXEC parques.InsertarTipoDeParque 'Reserva Nacional'
EXEC parques.InsertarTipoDeParque 'Parque de diversiones'
EXEC parques.InsertarTipoDeParque 'Parque Acuatico'

--CREO PARQUES
DECLARE @div INT, @act INT, @res INT;
SELECT @div = id_tipo_parque FROM parques.TipoParque WHERE descripcion = 'Parque De diversiones';
SELECT @act = id_tipo_parque FROM parques.TipoParque WHERE descripcion = 'Parque Acuatico';
SELECT @res = id_tipo_parque FROM parques.TipoParque WHERE descripcion = 'Reserva Nacional';
-- InsertarParque: @nombre, @id_tipo_parque, @region, @provincia, @latitud, @longitud, @superficie
EXEC parques.InsertarParque 'Iguazú',        @res, 'NEA',       'Misiones',  -25.687500, -54.437200, 67620.00;
EXEC parques.InsertarParque 'Nahuel Huapi',  @res, 'Patagonia', 'Río Negro', -41.066700, -71.500000, 717261.00;
EXEC parques.InsertarParque 'Mundo Marino',  @act, 'Costa',     'Buenos Aires', -36.318900, -56.770000, 200.00;

--CREO TIPODES DE VISITANTES
EXEC ventas.TipoVisitante_Nuevo 'Residente';
EXEC ventas.TipoVisitante_Nuevo 'No Residente';
EXEC ventas.TipoVisitante_Nuevo 'Estudiante';
EXEC ventas.TipoVisitante_Nuevo 'Jubilado';

--CREO PRECIOS ENTRADAS
DECLARE @iguazu INT, @rese INT, @nores INT, @est INT, @jub INT;
SELECT @iguazu = id_parque FROM parques.Parque WHERE nombre = 'Iguazú';
SELECT @rese  = id_tipo_visitante FROM ventas.TipoVisitante WHERE UPPER(descripcion) = UPPER('Residente');
SELECT @nores= id_tipo_visitante FROM ventas.TipoVisitante WHERE UPPER(descripcion) = UPPER('No Residente');
SELECT @est  = id_tipo_visitante FROM ventas.TipoVisitante WHERE UPPER(descripcion) = UPPER('Estudiante');
SELECT @jub  = id_tipo_visitante FROM ventas.TipoVisitante WHERE UPPER(descripcion) = UPPER('Jubilado');
-- PrecioEntrada_Nuevo_Normal: @id_parque, @id_tipo_visitante, @precio, @fecha_inicio
EXEC ventas.PrecioEntrada_Nuevo_Normal @iguazu, @rese,   8000.00,  '2025-01-01';
EXEC ventas.PrecioEntrada_Nuevo_Normal @iguazu, @nores, 25000.00, '2025-01-01';
EXEC ventas.PrecioEntrada_Nuevo_Normal @iguazu, @est,   4000.00,  '2025-01-01';
EXEC ventas.PrecioEntrada_Nuevo_Normal @iguazu, @jub,   3000.00,  '2025-01-01';

DECLARE @nahuel INT, @marino INT, @res INT, @nores INT, @est INT, @jub INT;

SELECT @nahuel = id_parque FROM parques.Parque WHERE nombre = 'Nahuel Huapi';
SELECT @marino = id_parque FROM parques.Parque WHERE nombre = 'Mundo Marino';
SELECT @res  = id_tipo_visitante FROM ventas.TipoVisitante WHERE UPPER(descripcion) = UPPER('Residente');
SELECT @nores= id_tipo_visitante FROM ventas.TipoVisitante WHERE UPPER(descripcion) = UPPER('No Residente');
SELECT @est  = id_tipo_visitante FROM ventas.TipoVisitante WHERE UPPER(descripcion) = UPPER('Estudiante');
SELECT @jub  = id_tipo_visitante FROM ventas.TipoVisitante WHERE UPPER(descripcion) = UPPER('Jubilado');

-- Nahuel Huapi
EXEC ventas.PrecioEntrada_Nuevo_Normal @nahuel, @res,   6000.00,  '2025-01-01';
EXEC ventas.PrecioEntrada_Nuevo_Normal @nahuel, @nores, 20000.00, '2025-01-01';
EXEC ventas.PrecioEntrada_Nuevo_Normal @nahuel, @est,   3000.00,  '2025-01-01';
EXEC ventas.PrecioEntrada_Nuevo_Normal @nahuel, @jub,   2500.00,  '2025-01-01';

-- Mundo Marino
EXEC ventas.PrecioEntrada_Nuevo_Normal @marino, @res,   10000.00, '2025-01-01';
EXEC ventas.PrecioEntrada_Nuevo_Normal @marino, @nores, 30000.00, '2025-01-01';
EXEC ventas.PrecioEntrada_Nuevo_Normal @marino, @est,   5000.00,  '2025-01-01';
EXEC ventas.PrecioEntrada_Nuevo_Normal @marino, @jub,   4000.00,  '2025-01-01';

SELECT id_precio, id_parque, id_tipo_visitante, precio, fecha_inicio, fecha_fin, estado FROM ventas.PrecioEntrada;
SELECT * FROM ventas.TipoVisitante
SELECT * FROM ventas.PrecioEntrada

SELECT p.id_tipo_visitante,tv.descripcion,p.precio FROM ventas.PrecioEntrada as p INNER JOIN ventas.TipoVisitante as tv ON p.id_tipo_visitante = tv.id_tipo_visitante

DECLARE @iguazu INT, @res INT, @nores INT, @est INT, @jub INT;

SELECT @iguazu = id_parque FROM parques.Parque WHERE nombre = 'Iguazú';
SELECT @res  = id_tipo_visitante FROM ventas.TipoVisitante WHERE UPPER(descripcion) = UPPER('Residente');
SELECT @nores= id_tipo_visitante FROM ventas.TipoVisitante WHERE UPPER(descripcion) = UPPER('No Residente');
SELECT @est  = id_tipo_visitante FROM ventas.TipoVisitante WHERE UPPER(descripcion) = UPPER('Estudiante');
SELECT @jub  = id_tipo_visitante FROM ventas.TipoVisitante WHERE UPPER(descripcion) = UPPER('Jubilado');
-- Entrada_Nuevo: @id_parque, @pto_venta, @fecha, @forma_pago, @id_tipo_1, @cantidad_1, [pares opcionales]
EXEC ventas.Entrada_Nuevo @iguazu, 1, '2026-03-05', 'Efectivo', @res, 4, @jub, 2;
EXEC ventas.Entrada_Nuevo @iguazu, 1, '2026-03-12', 'Crédito',  @nores, 3;
EXEC ventas.Entrada_Nuevo @iguazu, 2, '2026-04-02', 'QR',       @est, 5, @res, 2;

SELECT id_entrada, id_parque, fecha, forma_pago, total FROM ventas.Entrada;
SELECT id_ticket, id_tipo_visitante, cantidad, precio_unit, subtotal FROM ventas.TicketVisitante;
GO


DECLARE @iguazu INT, @nahuel INT, @marino INT, @res INT, @nores INT, @est INT, @jub INT;

SELECT @iguazu = id_parque FROM parques.Parque WHERE nombre = 'Iguazú';
SELECT @nahuel = id_parque FROM parques.Parque WHERE nombre = 'Nahuel Huapi';
SELECT @marino = id_parque FROM parques.Parque WHERE nombre = 'Mundo Marino';
SELECT @res  = id_tipo_visitante FROM ventas.TipoVisitante WHERE UPPER(descripcion) = UPPER('Residente');
SELECT @nores= id_tipo_visitante FROM ventas.TipoVisitante WHERE UPPER(descripcion) = UPPER('No Residente');
SELECT @est  = id_tipo_visitante FROM ventas.TipoVisitante WHERE UPPER(descripcion) = UPPER('Estudiante');
SELECT @jub  = id_tipo_visitante FROM ventas.TipoVisitante WHERE UPPER(descripcion) = UPPER('Jubilado');

-- NAHUEL HUAPI - enero 2026 (dos en la misma semana)
EXEC ventas.Entrada_Nuevo @nahuel, 1, '2026-01-08', 'Efectivo', @res, 6, @jub, 3;
EXEC ventas.Entrada_Nuevo @nahuel, 1, '2026-01-10', 'QR',       @nores, 2;
-- NAHUEL HUAPI - febrero 2026
EXEC ventas.Entrada_Nuevo @nahuel, 2, '2026-02-15', 'Crédito',  @est, 10, @res, 4;

-- MUNDO MARINO - marzo 2026
EXEC ventas.Entrada_Nuevo @marino, 1, '2026-03-20', 'Débito',   @res, 8, @nores, 5;
-- MUNDO MARINO - julio 2026 (temporada alta)
EXEC ventas.Entrada_Nuevo @marino, 1, '2026-07-05', 'Efectivo', @res, 15, @est, 20, @jub, 6;

-- IGUAZÚ - año anterior (2025) para probar separación por año
EXEC ventas.Entrada_Nuevo @iguazu, 1, '2025-12-28', 'Efectivo', @res, 3, @nores, 2;
GO


-- ============================================================
-- Descripción: Seed adicional de empresas, concesiones y pagos.
--              Cubre: concesión vencida, próxima a vencer, deudoras de
--              varios meses, al día, y deudor total (sin pagos).
-- ============================================================
USE ParquesNacionales;
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
GO

-- ------------------------------------------------------------
-- PAGOS
-- PagoConcesion_Nuevo: @id_concesion, @fecha_pago, @periodo, @monto
-- ------------------------------------------------------------
DECLARE @cA INT = (SELECT id_concesion FROM concesiones.Concesion WHERE id_parque=(SELECT id_parque FROM parques.Parque WHERE nombre='El Palmar') AND tipo_actividad='Restaurante' AND estado=0);
DECLARE @cB INT = (SELECT id_concesion FROM concesiones.Concesion WHERE id_parque=(SELECT id_parque FROM parques.Parque WHERE nombre='Lanín') AND tipo_actividad='Tienda de souvenirs' AND estado=0);
DECLARE @cC INT = (SELECT id_concesion FROM concesiones.Concesion WHERE id_parque=(SELECT id_parque FROM parques.Parque WHERE nombre='Iguazú') AND tipo_actividad='Cabalgatas' AND estado=0);
DECLARE @cD INT = (SELECT id_concesion FROM concesiones.Concesion WHERE id_parque=(SELECT id_parque FROM parques.Parque WHERE nombre='Calilegua') AND tipo_actividad='Camping' AND estado=0);

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

-- (E) deudor total: NO se cargan pagos a propósito
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