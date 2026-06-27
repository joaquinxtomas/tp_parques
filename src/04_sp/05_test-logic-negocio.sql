-- PARQUESNACIONALES

USE ParquesNacionales;
GO

-- Lote de pruebas

-- Actividades de concesiones

DECLARE @id_p     INT = (SELECT id_parque  FROM parques.Parque           WHERE nombre = 'Nahuel Huapi');
DECLARE @id_emp_b INT = (SELECT id_empresa FROM concesiones.Empresa       WHERE cuit   = '30714591241');
DECLARE @id_c1    INT = (SELECT MIN(id_concesion) FROM concesiones.Concesion WHERE estado = 0);
DECLARE @id_c2    INT;

IF NOT EXISTS (
    SELECT 1 FROM concesiones.Concesion
    WHERE id_empresa = @id_emp_b AND tipo_actividad = 'Tienda de souvenirs' AND estado = 0
)
    EXEC concesiones.Concesion_Nueva
        @id_empresa = @id_emp_b, @id_parque = @id_p,
        @tipo_actividad = 'Tienda de souvenirs', @fecha_inicio = '2026-01-01', @valor_alquiler = 35000.00;

SET @id_c2 = (
    SELECT id_concesion FROM concesiones.Concesion
    WHERE id_empresa = @id_emp_b AND tipo_actividad = 'Tienda de souvenirs' AND estado = 0
);

-- 5 pagos Restaurante (feb-jun 2026; enero ya ocupado por CASOS 30/36)
BEGIN TRY 
    EXEC concesiones.PagoConcesion_Nuevo @id_concesion=@id_c1, @fecha_pago='2026-03-05', @periodo='2026-02-01', @monto=90000.00;
    PRINT 'Lote  1 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote  1 ERROR: '+ERROR_MESSAGE(); 
END CATCH
BEGIN TRY 
    EXEC concesiones.PagoConcesion_Nuevo @id_concesion=@id_c1, @fecha_pago='2026-04-05', @periodo='2026-03-01', @monto=90000.00; 
    PRINT 'Lote  2 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote  2 ERROR: '+ERROR_MESSAGE();
END CATCH
BEGIN TRY 
    EXEC concesiones.PagoConcesion_Nuevo @id_concesion=@id_c1, @fecha_pago='2026-05-05', @periodo='2026-04-01', @monto=90000.00; 
    PRINT 'Lote  3 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote  3 ERROR: '+ERROR_MESSAGE(); 
END CATCH
BEGIN TRY 
    EXEC concesiones.PagoConcesion_Nuevo @id_concesion=@id_c1, @fecha_pago='2026-06-05', @periodo='2026-05-01', @monto=90000.00; 
    PRINT 'Lote  4 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote  4 ERROR: '+ERROR_MESSAGE(); 
END CATCH
BEGIN TRY 
    EXEC concesiones.PagoConcesion_Nuevo @id_concesion=@id_c1, @fecha_pago='2026-07-05', @periodo='2026-06-01', @monto=90000.00; 
    PRINT 'Lote  5 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote  5 ERROR: '+ERROR_MESSAGE(); 
END CATCH
-- 5 pagos Tienda de souvenirs (ene-may 2026)
BEGIN TRY 
    EXEC concesiones.PagoConcesion_Nuevo @id_concesion=@id_c2, @fecha_pago='2026-02-05', @periodo='2026-01-01', @monto=35000.00; 
    PRINT 'Lote  6 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote  6 ERROR: '+ERROR_MESSAGE(); 
END CATCH
BEGIN TRY 
    EXEC concesiones.PagoConcesion_Nuevo @id_concesion=@id_c2, @fecha_pago='2026-03-05', @periodo='2026-02-01', @monto=35000.00; 
    PRINT 'Lote  7 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote  7 ERROR: '+ERROR_MESSAGE(); 
END CATCH
BEGIN TRY 
    EXEC concesiones.PagoConcesion_Nuevo @id_concesion=@id_c2, @fecha_pago='2026-04-05', @periodo='2026-03-01', @monto=35000.00; 
    PRINT 'Lote  8 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote  8 ERROR: '+ERROR_MESSAGE(); 
END CATCH
BEGIN TRY 
    EXEC concesiones.PagoConcesion_Nuevo @id_concesion=@id_c2, @fecha_pago='2026-05-05', @periodo='2026-04-01', @monto=35000.00; 
    PRINT 'Lote  9 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote  9 ERROR: '+ERROR_MESSAGE(); 
END CATCH
BEGIN TRY 
    EXEC concesiones.PagoConcesion_Nuevo @id_concesion=@id_c2, @fecha_pago='2026-06-05', @periodo='2026-05-01', @monto=35000.00; 
    PRINT 'Lote 10 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote 10 ERROR: '+ERROR_MESSAGE(); 
END CATCH
GO

SELECT pc.id_pago, c.tipo_actividad, e.razon_social, pc.periodo, pc.fecha_pago, pc.monto, pc.estado
FROM concesiones.PagoConcesion pc
JOIN concesiones.Concesion c  ON c.id_concesion = pc.id_concesion JOIN concesiones.Empresa e  ON e.id_empresa   = c.id_empresa
WHERE pc.estado = 0 ORDER BY pc.id_concesion, pc.periodo;
GO

-- Venta de tickets

DECLARE @id_p   INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Nahuel Huapi');
DECLARE @id_adu INT = (SELECT id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Adulto');
DECLARE @id_est INT = (SELECT id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Estudiante');
DECLARE @id_jub INT = (SELECT id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Jubilado');
DECLARE @id_ext INT = (SELECT id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Extranjero');

BEGIN TRY 
    EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=1, @fecha='2026-06-01 08:30:00', @forma_pago='Efectivo', @id_tipo_1=@id_adu, @cantidad_1=3;
    PRINT 'Lote  1 OK';
END TRY 
BEGIN CATCH 
    PRINT 'Lote  1 ERROR: '+ERROR_MESSAGE(); 
END CATCH

BEGIN TRY 
    EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=1, @fecha='2026-06-02 09:00:00', @forma_pago='Débito', @id_tipo_1=@id_est, @cantidad_1=1, @id_tipo_2=@id_jub, @cantidad_2=1;
    PRINT 'Lote  2 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote  2 ERROR: '+ERROR_MESSAGE(); 
END CATCH

BEGIN TRY 
    EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=2, @fecha='2026-06-03 10:15:00', @forma_pago='Crédito', @id_tipo_1=@id_ext, @cantidad_1=4;
    PRINT 'Lote  3 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote  3 ERROR: '+ERROR_MESSAGE(); 
END CATCH

BEGIN TRY 
    EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=2, @fecha='2026-06-04 11:00:00', @forma_pago='QR', @id_tipo_1=@id_jub, @cantidad_1=2, @id_tipo_2=@id_adu, @cantidad_2=3;
    PRINT 'Lote  4 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote  4 ERROR: '+ERROR_MESSAGE(); 
END CATCH

BEGIN TRY 
    EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=1, @fecha='2026-06-05 13:00:00', @forma_pago='Transferencia', @id_tipo_1=@id_est, @cantidad_1=5;
    PRINT 'Lote  5 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote  5 ERROR: '+ERROR_MESSAGE(); 
END CATCH

BEGIN TRY 
    EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=3, @fecha='2026-06-06 09:30:00', @forma_pago='Efectivo', @id_tipo_1=@id_ext, @cantidad_1=2;
    PRINT 'Lote  6 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote  6 ERROR: '+ERROR_MESSAGE(); 
END CATCH

BEGIN TRY 
    EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=1, @fecha='2026-06-07 08:00:00', @forma_pago='Débito', @id_tipo_1=@id_est, @cantidad_1=2, @id_tipo_2=@id_ext, @cantidad_2=1;
    PRINT 'Lote  7 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote  7 ERROR: '+ERROR_MESSAGE(); 
END CATCH
BEGIN TRY 
    EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=2, @fecha='2026-06-08 14:00:00', @forma_pago='QR', @id_tipo_1=@id_jub, @cantidad_1=1;
    PRINT 'Lote  8 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote  8 ERROR: '+ERROR_MESSAGE(); 
END CATCH
BEGIN TRY 
    EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=3, @fecha='2026-06-09 16:30:00', @forma_pago='Crédito', @id_tipo_1=@id_ext, @cantidad_1=6;
    PRINT 'Lote  9 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote  9 ERROR: '+ERROR_MESSAGE(); 
END CATCH
BEGIN TRY 
    EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=1, @fecha='2026-06-10 10:00:00', @forma_pago='Efectivo', @id_tipo_1=@id_jub, @cantidad_1=3, @id_tipo_2=@id_ext, @cantidad_2=2, @id_tipo_3=@id_adu, @cantidad_3=2;
    PRINT 'Lote 10 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote 10 ERROR: '+ERROR_MESSAGE(); 
END CATCH
GO

SELECT e.id_entrada, e.nro_ticket, e.fecha, e.forma_pago, e.total,
       tv.descripcion AS tipo_visitante, tv2.cantidad, tv2.precio_unit, tv2.subtotal
FROM   ventas.Entrada e
JOIN   ventas.TicketVisitante tv2 ON tv2.id_ticket = e.id_entrada
JOIN   ventas.TipoVisitante   tv  ON tv.id_tipo_visitante = tv2.id_tipo_visitante
WHERE  e.estado = 0
ORDER BY e.id_entrada, tv.descripcion;
GO

--====================================================================================
--					TEST LOGICA DE NEGOCIO REGISTRO DE ACTIVIDADES
--====================================================================================

EXEC parques.InsertarTipoDeParque @descripcion = 'Tipo Test Tickets'; -- creo un tipo de parque de prueba
GO

DECLARE @id_tipo INT = (SELECT id_tipo_parque FROM parques.TipoParque
                        WHERE descripcion = 'Tipo Test Tickets');

IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = 'Parque Test Tickets') -- creo un parque de preuba 
    EXEC parques.InsertarParque
        @nombre = 'Parque Test Tickets',
        @id_tipo_parque = @id_tipo;
GO

DECLARE @id_parque INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Test Tickets'); -- almaceno el id del parque

IF NOT EXISTS (SELECT 1 FROM actividades.Atraccion WHERE nombre = 'TEST_Cupo10')
    INSERT INTO actividades.Atraccion (id_parque, nombre, costo, duracion, cupo_maximo, tipo)
    VALUES (@id_parque, 'TEST_Cupo10', 1000.00, 60, 10, 'paga');

IF NOT EXISTS (SELECT 1 FROM actividades.Atraccion WHERE nombre = 'TEST_DeBaja')
    INSERT INTO actividades.Atraccion (id_parque, nombre, costo, duracion, cupo_maximo, tipo, estado)
    VALUES (@id_parque, 'TEST_DeBaja', 500.00, 30, 20, 'paga', 1);

IF NOT EXISTS (SELECT 1 FROM actividades.Atraccion WHERE nombre = 'TEST_SinLimite')
    INSERT INTO actividades.Atraccion (id_parque, nombre, costo, duracion, cupo_maximo, tipo)
    VALUES (@id_parque, 'TEST_SinLimite', 0.00, NULL, NULL, 'gratuita');



PRINT 'Precondiciones cargadas.';
GO

SELECT * FROM actividades.Atraccion;
-- ============================================================
-- CASO 1: Contratacion valida (4 sobre cupo 10) -> OK
-- ============================================================
BEGIN TRY
    DECLARE @a1 INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Cupo10');
    EXEC actividades.RegistrarTicketActividad @id_atraccion = @a1, @cantidad = 4;
    PRINT 'CASO 1 OK: registro insertado (4 de 10)';
END TRY
BEGIN CATCH
    PRINT 'CASO 1 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO
-- ============================================================
-- CASO 2: Completar cupo justo (6 mas, total 10 de 10) -> OK
-- ============================================================
BEGIN TRY
    DECLARE @a2 INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Cupo10');
    EXEC actividades.RegistrarTicketActividad @id_atraccion = @a2, @cantidad = 6;
    PRINT 'CASO 2 OK: cupo completado justo (10 de 10)';
END TRY
BEGIN CATCH
    PRINT 'CASO 2 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- CASO 3: Pasarse del cupo (1 mas con 10 de 10) -> RECHAZO
-- ============================================================
BEGIN TRY
    DECLARE @a3 INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Cupo10');
    EXEC actividades.RegistrarTicketActividad @id_atraccion = @a3, @cantidad = 1;
    PRINT 'CASO 3 FALLO: no deberia haber registrado';
END TRY
BEGIN CATCH
    PRINT 'CASO 3 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- CASO 4: Atraccion inexistente -> RECHAZO
-- ============================================================
BEGIN TRY
    EXEC actividades.RegistrarTicketActividad @id_atraccion = 999999, @cantidad = 2;
    PRINT 'CASO 4 FALLO: no deberia haber registrado';
END TRY
BEGIN CATCH
    PRINT 'CASO 4 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- CASO 5: Cantidad invalida (cero) -> RECHAZO
-- ============================================================
BEGIN TRY
    DECLARE @a5 INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Cupo10');
    EXEC actividades.RegistrarTicketActividad @id_atraccion = @a5, @cantidad = 0;
    PRINT 'CASO 5 FALLO: no deberia haber registrado';
END TRY
BEGIN CATCH
    PRINT 'CASO 5 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- CASO 6: Atraccion dada de baja -> RECHAZO
-- ============================================================
BEGIN TRY
    DECLARE @a6 INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_DeBaja');
    EXEC actividades.RegistrarTicketActividad @id_atraccion = @a6, @cantidad = 2;
    PRINT 'CASO 6 FALLO: no deberia haber registrado';
END TRY
BEGIN CATCH
    PRINT 'CASO 6 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- CASO 7: Atraccion con cupo NULL (sin limite) -> OK
-- ============================================================
BEGIN TRY
    DECLARE @a7 INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_SinLimite');
    EXEC actividades.RegistrarTicketActividad @id_atraccion = @a7, @cantidad = 9999;
    PRINT 'CASO 7 OK: registrado sin limite de cupo';
END TRY
BEGIN CATCH
    PRINT 'CASO 7 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

select * from actividades.TicketsAtraccion

-- Verificacion intermedia: registros de la atraccion con cupo 10
SELECT id_ticket_atraccion, id_atraccion, fecha, cantidad, subtotal, estado
FROM   actividades.TicketsAtraccion
WHERE  id_atraccion = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Cupo10')
ORDER BY id_ticket_atraccion;
GO

-- ============================================================
-- CASO 8: Cancelar un registro existente -> OK
-- ============================================================
BEGIN TRY
    DECLARE @tk INT = (
        SELECT MIN(id_ticket_atraccion) FROM actividades.TicketsAtraccion
        WHERE id_atraccion = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Cupo10')
          AND estado = 0
    );
    EXEC actividades.CancelarTicketActividad @id_ticketAtraccion = @tk;
    PRINT 'CASO 8 OK: registro cancelado (estado = 1)';
END TRY
BEGIN CATCH
    PRINT 'CASO 8 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- CASO 9: Cancelar un registro ya dado de baja -> RECHAZO
-- ============================================================
BEGIN TRY
    DECLARE @tk2 INT = (
        SELECT MIN(id_ticket_atraccion) FROM actividades.TicketsAtraccion
        WHERE id_atraccion = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Cupo10')
          AND estado = 1
    );
    EXEC actividades.CancelarTicketActividad @id_ticketAtraccion = @tk2;
    PRINT 'CASO 9 FALLO: no deberia haber cancelado';
END TRY
BEGIN CATCH
    PRINT 'CASO 9 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- CASO 10: Cancelar un registro inexistente -> RECHAZO
-- ============================================================
BEGIN TRY
    EXEC actividades.CancelarTicketActividad @id_ticketAtraccion = 999999;
    PRINT 'CASO 10 FALLO: no deberia haber cancelado';
END TRY
BEGIN CATCH
    PRINT 'CASO 10 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- Verificacion final
SELECT id_ticket_atraccion, id_atraccion, cantidad, subtotal, estado
FROM   actividades.TicketsAtraccion
WHERE  id_atraccion IN (
        SELECT id_atraccion FROM actividades.Atraccion
        WHERE nombre IN ('TEST_Cupo10', 'TEST_SinLimite'))
ORDER BY id_ticket_atraccion;
GO
