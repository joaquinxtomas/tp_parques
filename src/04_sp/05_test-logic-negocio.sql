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
DECLARE @id_ext INT = (SELECT id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'No residente');

BEGIN TRY 
    EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=1, @fecha='2026-05-01 08:30:00', @forma_pago='Efectivo', @id_tipo_1=@id_adu, @cantidad_1=3;
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
    EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=2, @fecha='2026-05-03 10:15:00', @forma_pago='Crédito', @id_tipo_1=@id_ext, @cantidad_1=4;
    PRINT 'Lote  3 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote  3 ERROR: '+ERROR_MESSAGE(); 
END CATCH

BEGIN TRY 
    EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=2, @fecha='2026-05-04 11:00:00', @forma_pago='QR', @id_tipo_1=@id_jub, @cantidad_1=2, @id_tipo_2=@id_adu, @cantidad_2=3;
    PRINT 'Lote  4 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote  4 ERROR: '+ERROR_MESSAGE(); 
END CATCH

BEGIN TRY 
    EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=1, @fecha='2026-05-05 13:00:00', @forma_pago='Transferencia', @id_tipo_1=@id_est, @cantidad_1=5;
    PRINT 'Lote  5 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote  5 ERROR: '+ERROR_MESSAGE(); 
END CATCH

BEGIN TRY 
    EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=3, @fecha='2026-05-05 09:30:00', @forma_pago='Efectivo', @id_tipo_1=@id_ext, @cantidad_1=2;
    PRINT 'Lote  6 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote  6 ERROR: '+ERROR_MESSAGE(); 
END CATCH

BEGIN TRY 
    EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=1, @fecha='2026-05-07 08:00:00', @forma_pago='Débito', @id_tipo_1=@id_est, @cantidad_1=2, @id_tipo_2=@id_ext, @cantidad_2=1;
    PRINT 'Lote  7 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote  7 ERROR: '+ERROR_MESSAGE(); 
END CATCH
BEGIN TRY 
    EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=2, @fecha='2026-05-08 14:00:00', @forma_pago='QR', @id_tipo_1=@id_jub, @cantidad_1=1;
    PRINT 'Lote  8 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote  8 ERROR: '+ERROR_MESSAGE(); 
END CATCH
BEGIN TRY 
    EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=3, @fecha='2026-05-09 16:30:00', @forma_pago='Crédito', @id_tipo_1=@id_ext, @cantidad_1=6;
    PRINT 'Lote  9 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote  9 ERROR: '+ERROR_MESSAGE(); 
END CATCH
BEGIN TRY 
    EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=1, @fecha='2026-05-10 10:00:00', @forma_pago='Efectivo', @id_tipo_1=@id_jub, @cantidad_1=3, @id_tipo_2=@id_ext, @cantidad_2=2, @id_tipo_3=@id_adu, @cantidad_3=2;
    PRINT 'Lote 10 OK'; 
END TRY 
BEGIN CATCH 
    PRINT 'Lote 10 ERROR: '+ERROR_MESSAGE(); 
END CATCH
GO

SELECT e.id_entrada, e.nro_ticket, e.fecha, e.forma_pago, e.total,
       tv.descripcion AS tipo_visitante, tv2.cantidad, tv2.precio_unit, tv2.subtotal
FROM   ventas.Entrada e
JOIN   ventas.TicketVisitante tv2 ON tv2.id_entrada = e.id_entrada
JOIN   ventas.TipoVisitante   tv  ON tv.id_tipo_visitante = tv2.id_tipo_visitante
WHERE  e.estado = 0
ORDER BY e.id_entrada, tv.descripcion;
GO

-- Entrada_Nuevo

-- CASO 28: parque inexistente → error
BEGIN TRY
    DECLARE @id_res INT = (SELECT id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    EXEC ventas.Entrada_Nuevo @id_parque = 9999, @pto_venta = 1, @fecha = '2026-06-23 10:00:00',
        @forma_pago = 'Efectivo', @id_tipo_1 = @id_res, @cantidad_1 = 1;
    PRINT 'CASO 28 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 28 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 29: forma de pago inválida → error
BEGIN TRY
    DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
    DECLARE @id_res INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    EXEC ventas.Entrada_Nuevo @id_parque = @id_p, @pto_venta = 1, @fecha = '2026-06-23 10:00:00',
        @forma_pago = 'Bitcoin', @id_tipo_1 = @id_res, @cantidad_1 = 1;
    PRINT 'CASO 29 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 29 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 30: cantidad_1 = 0 → error
BEGIN TRY
    DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
    DECLARE @id_res INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    EXEC ventas.Entrada_Nuevo @id_parque = @id_p, @pto_venta = 1, @fecha = '2026-06-23 10:00:00',
        @forma_pago = 'Efectivo', @id_tipo_1 = @id_res, @cantidad_1 = 0;
    PRINT 'CASO 30 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 30 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 31: tipo_1 inexistente → error
BEGIN TRY
    DECLARE @id_p INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Nahuel Huapi');
    EXEC ventas.Entrada_Nuevo @id_parque = @id_p, @pto_venta = 1, @fecha = '2026-06-23 10:00:00',
        @forma_pago = 'Efectivo', @id_tipo_1 = 9999, @cantidad_1 = 1;
    PRINT 'CASO 31 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 31 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 32: tipo_1 activo pero sin precio vigente para la fecha (Menor, precio dado de baja) → error
BEGIN TRY
    DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
    DECLARE @id_men INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Menor');
    EXEC ventas.Entrada_Nuevo @id_parque = @id_p, @pto_venta = 1, @fecha = '2026-06-23 10:00:00',
        @forma_pago = 'Efectivo', @id_tipo_1 = @id_men, @cantidad_1 = 1;
    PRINT 'CASO 32 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 32 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 33: alta correcta con 1 tipo de visitante
BEGIN TRY
    DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
    DECLARE @id_res INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    EXEC ventas.Entrada_Nuevo @id_parque = @id_p, @pto_venta = 1, @fecha = '2026-06-23 10:00:00',
        @forma_pago = 'Efectivo', @id_tipo_1 = @id_res, @cantidad_1 = 2;
    PRINT 'CASO 33 OK: entrada con 1 tipo insertada (2 residentes)';
END TRY
BEGIN CATCH
    PRINT 'CASO 33 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 34: tipo_2 sin precio vigente → error acumulado junto a tipo_1 válido
BEGIN TRY
    DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
    DECLARE @id_res INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    DECLARE @id_men INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Menor');
    EXEC ventas.Entrada_Nuevo @id_parque = @id_p, @pto_venta = 1, @fecha = '2026-06-23 11:00:00',
        @forma_pago = 'Débito', @id_tipo_1 = @id_res, @cantidad_1 = 1, @id_tipo_2 = @id_men, @cantidad_2 = 1;
    PRINT 'CASO 34 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 34 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 35: alta correcta con 2 tipos de visitante
BEGIN TRY
    DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
    DECLARE @id_res INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    DECLARE @id_ext INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Extranjero');
    EXEC ventas.Entrada_Nuevo @id_parque = @id_p, @pto_venta = 1, @fecha = '2026-06-23 11:00:00',
        @forma_pago = 'Crédito', @id_tipo_1 = @id_res, @cantidad_1 = 1, @id_tipo_2 = @id_ext, @cantidad_2 = 2;
    PRINT 'CASO 35 OK: entrada con 2 tipos insertada';
END TRY
BEGIN CATCH
    PRINT 'CASO 35 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

SELECT e.id_entrada, e.nro_ticket, e.fecha, e.total, e.forma_pago,
       tv.descripcion AS tipo_visitante, tv2.cantidad, tv2.precio_unit, tv2.subtotal
FROM   ventas.Entrada e
JOIN   ventas.TicketVisitante tv2 ON tv2.id_entrada = e.id_entrada
JOIN   ventas.TipoVisitante   tv  ON tv.id_tipo_visitante = tv2.id_tipo_visitante
ORDER BY e.id_entrada, tv.descripcion;
GO


-- Ticket_Eliminar

-- CASO 36: ticket inexistente → error
BEGIN TRY
    EXEC ventas.Ticket_Eliminar @id_ticket = 9999;
    PRINT 'CASO 36 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 36 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 37: baja correcta (primer ticket activo)
BEGIN TRY
    DECLARE @id_tk INT = (SELECT MIN(id_entrada) FROM ventas.Entrada WHERE estado = 0);
    EXEC ventas.Ticket_Eliminar @id_ticket = @id_tk;
    PRINT 'CASO 37 OK: ticket dado de baja';
END TRY
BEGIN CATCH
    PRINT 'CASO 37 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 38: ya dado de baja → error
BEGIN TRY
    DECLARE @id_tk INT = (SELECT MIN(id_entrada) FROM ventas.Entrada WHERE estado = 1);
    EXEC ventas.Ticket_Eliminar @id_ticket = @id_tk;
    PRINT 'CASO 38 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 38 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO



--====================================================================================
--					TEST LOGICA DE NEGOCIO REGISTRO DE ACTIVIDADES
--====================================================================================
-- ------------------------------------------------------------
-- PRECONDICIONES: parque + atracciones de prueba (con turno)
-- ------------------------------------------------------------
BEGIN TRY EXEC parques.InsertarTipoDeParque 'Tipo Test Tickets'; END TRY BEGIN CATCH PRINT 'tipo: '+ERROR_MESSAGE(); END CATCH
GO
DECLARE @id_tipo INT = (SELECT id_tipo_parque FROM parques.TipoParque WHERE descripcion='Tipo Test Tickets');
IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE nombre='Parque Test Tickets')
    EXEC parques.InsertarParque @nombre='Parque Test Tickets', @id_tipo_parque=@id_tipo;
GO

DECLARE @idp INT = (SELECT id_parque FROM parques.Parque WHERE nombre='Parque Test Tickets');

-- atraccion con cupo 10, turno 09:00
BEGIN TRY EXEC actividades.InsertarAtraccion @id_parque=@idp, @nombre='TEST_Cupo10',
    @costo=1000, @duracion=60, @cupo_maximo=10, @tipo='paga', @turno='09:00'; END TRY
BEGIN CATCH PRINT 'pre Cupo10: '+ERROR_MESSAGE(); END CATCH
-- atraccion dada de baja
BEGIN TRY EXEC actividades.InsertarAtraccion @id_parque=@idp, @nombre='TEST_DeBaja',
    @costo=500, @duracion=30, @cupo_maximo=20, @tipo='paga', @turno='10:00'; END TRY
BEGIN CATCH PRINT 'pre DeBaja: '+ERROR_MESSAGE(); END CATCH
-- atraccion sin limite de cupo
BEGIN TRY EXEC actividades.InsertarAtraccion @id_parque=@idp, @nombre='TEST_SinLimite',
    @costo=0, @duracion=NULL, @cupo_maximo=NULL, @tipo='gratuita', @turno='11:00'; END TRY
BEGIN CATCH PRINT 'pre SinLimite: '+ERROR_MESSAGE(); END CATCH
GO

select * from actividades.Atraccion

-- doy de baja la atraccion TEST_DeBaja para el caso 6
DECLARE @idBaja INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre='TEST_DeBaja');
EXEC actividades.EliminarAtraccion @id_atraccion = @idBaja;   -- ajustá el nombre si tu SP de baja se llama distinto
GO

PRINT 'Precondiciones cargadas.';
GO

-- Fecha futura fija para los casos de cupo (no se vence)
DECLARE @fut DATE = '2026-12-15';

-- ============================================================
-- CASO 1: contratacion valida (4 sobre cupo 10) -> OK
-- ============================================================
BEGIN TRY
    DECLARE @a1 INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre='TEST_Cupo10');
    EXEC actividades.RegistrarTicketActividad @id_atraccion=@a1, @cantidad=4, @fecha_actividad='2026-12-15';
    PRINT 'CASO 1 OK: registro insertado (4 de 10)';
END TRY BEGIN CATCH PRINT 'CASO 1 ERROR inesperado: '+ERROR_MESSAGE(); END CATCH
GO

-- ============================================================
-- CASO 2: completar cupo justo (6 mas, mismo dia -> 10 de 10) -> OK
-- ============================================================
BEGIN TRY
    DECLARE @a2 INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre='TEST_Cupo10');
    EXEC actividades.RegistrarTicketActividad @id_atraccion=@a2, @cantidad=6, @fecha_actividad='2026-12-15';
    PRINT 'CASO 2 OK: cupo completado justo (10 de 10)';
END TRY BEGIN CATCH PRINT 'CASO 2 ERROR inesperado: '+ERROR_MESSAGE(); END CATCH
GO

-- ============================================================
-- CASO 3: pasarse del cupo (1 mas, mismo dia con 10/10) -> RECHAZO
-- ============================================================
BEGIN TRY
    DECLARE @a3 INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre='TEST_Cupo10');
    EXEC actividades.RegistrarTicketActividad @id_atraccion=@a3, @cantidad=1, @fecha_actividad='2026-12-15';
    PRINT 'CASO 3 FALLO: no deberia haber registrado';
END TRY BEGIN CATCH PRINT 'CASO 3 OK (rechazo esperado): '+ERROR_MESSAGE(); END CATCH
GO

-- ============================================================
-- CASO 3b: mismo cupo pero OTRO dia -> OK (el cupo es por turno/dia)
-- ============================================================
BEGIN TRY
    DECLARE @a3b INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre='TEST_Cupo10');
    EXEC actividades.RegistrarTicketActividad @id_atraccion=@a3b, @cantidad=8, @fecha_actividad='2026-12-16';
    PRINT 'CASO 3b OK: otro dia tiene su propio cupo';
END TRY BEGIN CATCH PRINT 'CASO 3b ERROR inesperado: '+ERROR_MESSAGE(); END CATCH
GO

-- ============================================================
-- CASO 4: atraccion inexistente -> RECHAZO
-- ============================================================
BEGIN TRY
    EXEC actividades.RegistrarTicketActividad @id_atraccion=999999, @cantidad=2, @fecha_actividad='2026-12-15';
    PRINT 'CASO 4 FALLO';
END TRY BEGIN CATCH PRINT 'CASO 4 OK (rechazo esperado): '+ERROR_MESSAGE(); END CATCH
GO

-- ============================================================
-- CASO 5: cantidad invalida (cero) -> RECHAZO
-- ============================================================
BEGIN TRY
    DECLARE @a5 INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre='TEST_Cupo10');
    EXEC actividades.RegistrarTicketActividad @id_atraccion=@a5, @cantidad=0, @fecha_actividad='2026-12-15';
    PRINT 'CASO 5 FALLO';
END TRY BEGIN CATCH PRINT 'CASO 5 OK (rechazo esperado): '+ERROR_MESSAGE(); END CATCH
GO

-- ============================================================
-- CASO 6: atraccion dada de baja -> RECHAZO
-- ============================================================
BEGIN TRY
    DECLARE @a6 INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre='TEST_DeBaja');
    EXEC actividades.RegistrarTicketActividad @id_atraccion=@a6, @cantidad=2, @fecha_actividad='2026-12-15';
    PRINT 'CASO 6 FALLO';
END TRY BEGIN CATCH PRINT 'CASO 6 OK (rechazo esperado): '+ERROR_MESSAGE(); END CATCH
GO

-- ============================================================
-- CASO 7: cupo NULL (sin limite) -> OK
-- ============================================================
BEGIN TRY
    DECLARE @a7 INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre='TEST_SinLimite');
    EXEC actividades.RegistrarTicketActividad @id_atraccion=@a7, @cantidad=9999, @fecha_actividad='2026-12-15';
    PRINT 'CASO 7 OK: registrado sin limite de cupo';
END TRY BEGIN CATCH PRINT 'CASO 7 ERROR inesperado: '+ERROR_MESSAGE(); END CATCH
GO

-- ============================================================
-- CASO 8 (NUEVO): actividad ya comenzo (fecha pasada) -> RECHAZO
-- ============================================================
BEGIN TRY
    DECLARE @a8 INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre='TEST_Cupo10');
    EXEC actividades.RegistrarTicketActividad @id_atraccion=@a8, @cantidad=2, @fecha_actividad='2020-01-01';
    PRINT 'CASO 8 FALLO: no deberia registrar una actividad pasada';
END TRY BEGIN CATCH PRINT 'CASO 8 OK (rechazo esperado): '+ERROR_MESSAGE(); END CATCH
GO

-- ============================================================
-- CASO 9: cancelar un registro existente -> OK
-- ============================================================
BEGIN TRY
    DECLARE @tk INT = (SELECT MIN(id_ticket_atraccion) FROM actividades.TicketsAtraccion
        WHERE id_atraccion=(SELECT id_atraccion FROM actividades.Atraccion WHERE nombre='TEST_Cupo10') AND estado=0);
    EXEC actividades.CancelarTicketActividad @id_ticketAtraccion=@tk;
    PRINT 'CASO 9 OK: registro cancelado';
END TRY BEGIN CATCH PRINT 'CASO 9 ERROR inesperado: '+ERROR_MESSAGE(); END CATCH
GO

-- ============================================================
-- CASO 10: cancelar inexistente -> RECHAZO
-- ============================================================
BEGIN TRY
    EXEC actividades.CancelarTicketActividad @id_ticketAtraccion=999999;
    PRINT 'CASO 10 FALLO';
END TRY BEGIN CATCH PRINT 'CASO 10 OK (rechazo esperado): '+ERROR_MESSAGE(); END CATCH
GO

-- Verificacion final
SELECT id_ticket_atraccion, id_atraccion, fecha, fecha_actividad, cantidad, subtotal, estado
FROM   actividades.TicketsAtraccion
ORDER BY id_atraccion, fecha_actividad, id_ticket_atraccion;
GO

-- Cancelar un registro ya dado de baja -> RECHAZO
BEGIN TRY
    DECLARE @tk2 INT = (
        SELECT MIN(id_ticket_atraccion)
        FROM actividades.TicketsAtraccion
        WHERE estado = 1
    );

    EXEC actividades.CancelarTicketActividad @id_ticketAtraccion = @tk2;

    PRINT 'CASO FALLO: no deberia haber cancelado';
END TRY
BEGIN CATCH
    PRINT 'CASO OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
