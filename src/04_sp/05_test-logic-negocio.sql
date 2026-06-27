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