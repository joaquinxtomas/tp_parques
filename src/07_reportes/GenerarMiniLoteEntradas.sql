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
