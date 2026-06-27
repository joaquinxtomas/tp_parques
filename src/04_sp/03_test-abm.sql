--              PARQUESNACIONALES

USE ParquesNacionales;
GO

--              Concesiones

-- PRECONDICIONES

BEGIN TRY
    EXEC parques.InsertarTipoDeParque @descripcion = 'Nacional';
END TRY
BEGIN CATCH
    PRINT 'Precondicion tipo parque: ' + ERROR_MESSAGE();
END CATCH
GO

DECLARE @id_tipo INT = (SELECT id_tipo_parque FROM parques.TipoParque WHERE descripcion = 'Nacional');
IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = 'Nahuel Huapi')
    EXEC parques.InsertarParque
        @nombre         = 'Nahuel Huapi',
        @id_tipo_parque = @id_tipo,
        @provincia      = 'Neuquén',
        @region         = 'Patagonia',
        @superficie     = 717261.00;
GO


-- Empresa_Nueva

-- CASO 1: razon_social vacía → error
BEGIN TRY
    EXEC concesiones.Empresa_Nueva @razon_social = '', @cuit = '30714591230', @contacto = 'info@empresa.com';
    PRINT 'CASO 1 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 1 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 2: cuit NULL → error
BEGIN TRY
    EXEC concesiones.Empresa_Nueva @razon_social = 'Empresa Test', @cuit = NULL, @contacto = 'info@empresa.com';
    PRINT 'CASO 2 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 2 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 3: contacto NULL → error
BEGIN TRY
    EXEC concesiones.Empresa_Nueva @razon_social = 'Empresa Test', @cuit = '30714591230', @contacto = NULL;
    PRINT 'CASO 3 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 3 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 4: altas correctas (3 empresas para los tests siguientes)
BEGIN TRY
    EXEC concesiones.Empresa_Nueva @razon_social = 'Patagonia Aventuras SA',    @cuit = '30714591230', @contacto = 'info@aventuras.com';
    PRINT 'CASO 4a OK';
END TRY
BEGIN CATCH
    PRINT 'CASO 4a: ' + ERROR_MESSAGE();
END CATCH
GO
BEGIN TRY
    EXEC concesiones.Empresa_Nueva @razon_social = 'Servicios Turisticos SRL',  @cuit = '30714591241', @contacto = 'servicios@turismo.com';
    PRINT 'CASO 4b OK';
END TRY
BEGIN CATCH
    PRINT 'CASO 4b: ' + ERROR_MESSAGE();
END CATCH
GO
BEGIN TRY
    EXEC concesiones.Empresa_Nueva @razon_social = 'Gastronomia del Sur SA',    @cuit = '30714591252', @contacto = 'admin@gastrosur.com';
    PRINT 'CASO 4c OK';
END TRY
BEGIN CATCH
    PRINT 'CASO 4c: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 5: cuit duplicado → error
BEGIN TRY
    EXEC concesiones.Empresa_Nueva @razon_social = 'Otra Empresa SRL', @cuit = '30714591230', @contacto = 'otro@empresa.com';
    PRINT 'CASO 5 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 5 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

SELECT id_empresa, razon_social, cuit, estado FROM concesiones.Empresa;
GO


-- Empresa_Modificar

-- CASO 6: empresa inexistente → error
BEGIN TRY
    EXEC concesiones.Empresa_Modificar @id_empresa = 9999, @razon_social = 'X';
    PRINT 'CASO 6 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 6 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 7: razon_social ya usada por otra empresa → error
BEGIN TRY
    DECLARE @id INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit = '30714591241');
    EXEC concesiones.Empresa_Modificar @id_empresa = @id, @razon_social = 'Patagonia Aventuras SA';
    PRINT 'CASO 7 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 7 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 8: cuit ya usado por otra empresa → error
BEGIN TRY
    DECLARE @id INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit = '30714591241');
    EXEC concesiones.Empresa_Modificar @id_empresa = @id, @cuit = '30714591230';
    PRINT 'CASO 8 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 8 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 9: modificación correcta (actualizar contacto)
BEGIN TRY
    DECLARE @id INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit = '30714591252');
    EXEC concesiones.Empresa_Modificar @id_empresa = @id, @contacto = 'nuevo@gastrosur.com';
    PRINT 'CASO 9 OK: contacto actualizado';
END TRY
BEGIN CATCH
    PRINT 'CASO 9 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO


-- ============================================================
-- Empresa_Eliminar
-- ============================================================

-- CASO 10: empresa inexistente → error
BEGIN TRY
    EXEC concesiones.Empresa_Eliminar @id_empresa = 9999;
    PRINT 'CASO 10 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 10 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 11: baja correcta (Gastronomia del Sur)
BEGIN TRY
    DECLARE @id INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit = '30714591252');
    EXEC concesiones.Empresa_Eliminar @id_empresa = @id;
    PRINT 'CASO 11 OK: empresa dada de baja';
END TRY
BEGIN CATCH
    PRINT 'CASO 11 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 12: ya deshabilitada → error
BEGIN TRY
    DECLARE @id INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit = '30714591252');
    EXEC concesiones.Empresa_Eliminar @id_empresa = @id;
    PRINT 'CASO 12 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 12 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO


-- ============================================================
-- Concesion_Nueva
-- ============================================================

-- CASO 13: empresa inactiva → error
BEGIN TRY
    DECLARE @id_emp INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit = '30714591252');
    DECLARE @id_p   INT = (SELECT id_parque  FROM parques.Parque          WHERE nombre = 'Nahuel Huapi');
    EXEC concesiones.Concesion_Nueva @id_empresa = @id_emp, @id_parque = @id_p,
        @tipo_actividad = 'Restaurante', @fecha_inicio = '2026-01-01', @valor_alquiler = 50000.00;
    PRINT 'CASO 13 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 13 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 14: parque inexistente → error
BEGIN TRY
    DECLARE @id_emp INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit = '30714591230');
    EXEC concesiones.Concesion_Nueva @id_empresa = @id_emp, @id_parque = 9999,
        @tipo_actividad = 'Restaurante', @fecha_inicio = '2026-01-01', @valor_alquiler = 50000.00;
    PRINT 'CASO 14 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 14 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 15: tipo_actividad vacío → error
BEGIN TRY
    DECLARE @id_emp INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit = '30714591230');
    DECLARE @id_p   INT = (SELECT id_parque  FROM parques.Parque          WHERE nombre = 'Nahuel Huapi');
    EXEC concesiones.Concesion_Nueva @id_empresa = @id_emp, @id_parque = @id_p,
        @tipo_actividad = '', @fecha_inicio = '2026-01-01', @valor_alquiler = 50000.00;
    PRINT 'CASO 15 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 15 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 16: fecha_inicio NULL → error
BEGIN TRY
    DECLARE @id_emp INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit = '30714591230');
    DECLARE @id_p   INT = (SELECT id_parque  FROM parques.Parque          WHERE nombre = 'Nahuel Huapi');
    EXEC concesiones.Concesion_Nueva @id_empresa = @id_emp, @id_parque = @id_p,
        @tipo_actividad = 'Restaurante', @fecha_inicio = NULL, @valor_alquiler = 50000.00;
    PRINT 'CASO 16 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 16 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 17: fecha_fin < fecha_inicio → error
BEGIN TRY
    DECLARE @id_emp INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit = '30714591230');
    DECLARE @id_p   INT = (SELECT id_parque  FROM parques.Parque          WHERE nombre = 'Nahuel Huapi');
    EXEC concesiones.Concesion_Nueva @id_empresa = @id_emp, @id_parque = @id_p,
        @tipo_actividad = 'Restaurante', @fecha_inicio = '2026-06-01', @valor_alquiler = 50000.00, @fecha_fin = '2026-05-31';
    PRINT 'CASO 17 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 17 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 18: valor_alquiler = 0 → error
BEGIN TRY
    DECLARE @id_emp INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit = '30714591230');
    DECLARE @id_p   INT = (SELECT id_parque  FROM parques.Parque          WHERE nombre = 'Nahuel Huapi');
    EXEC concesiones.Concesion_Nueva @id_empresa = @id_emp, @id_parque = @id_p,
        @tipo_actividad = 'Restaurante', @fecha_inicio = '2026-01-01', @valor_alquiler = 0;
    PRINT 'CASO 18 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 18 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 19: altas correctas (2 concesiones para los tests siguientes)
BEGIN TRY
    DECLARE @id_emp INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit = '30714591230');
    DECLARE @id_p   INT = (SELECT id_parque  FROM parques.Parque          WHERE nombre = 'Nahuel Huapi');
    EXEC concesiones.Concesion_Nueva @id_empresa = @id_emp, @id_parque = @id_p,
        @tipo_actividad = 'Restaurante', @fecha_inicio = '2026-01-01', @valor_alquiler = 80000.00;
    PRINT 'CASO 19a OK: concesion Restaurante insertada';
END TRY
BEGIN CATCH
    PRINT 'CASO 19a ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO
BEGIN TRY
    DECLARE @id_emp INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit = '30714591241');
    DECLARE @id_p   INT = (SELECT id_parque  FROM parques.Parque          WHERE nombre = 'Nahuel Huapi');
    EXEC concesiones.Concesion_Nueva @id_empresa = @id_emp, @id_parque = @id_p,
        @tipo_actividad = 'Alquiler de equipos', @fecha_inicio = '2026-01-01', @valor_alquiler = 45000.00;
    PRINT 'CASO 19b OK: concesion Alquiler de equipos insertada';
END TRY
BEGIN CATCH
    PRINT 'CASO 19b ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO


-- Concesion_Modificar

-- CASO 20: concesion inexistente → error
BEGIN TRY
    EXEC concesiones.Concesion_Modificar @id_concesion = 9999, @tipo_actividad = 'X';
    PRINT 'CASO 20 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 20 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 21: fecha_fin < fecha_inicio → error
BEGIN TRY
    DECLARE @id INT = (SELECT MIN(id_concesion) FROM concesiones.Concesion WHERE estado = 0);
    EXEC concesiones.Concesion_Modificar @id_concesion = @id, @fecha_inicio = '2026-06-01', @fecha_fin = '2026-05-01';
    PRINT 'CASO 21 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 21 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 22: valor_alquiler negativo → error
BEGIN TRY
    DECLARE @id INT = (SELECT MIN(id_concesion) FROM concesiones.Concesion WHERE estado = 0);
    EXEC concesiones.Concesion_Modificar @id_concesion = @id, @valor_alquiler = -1000.00;
    PRINT 'CASO 22 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 22 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 23: modificación correcta
BEGIN TRY
    DECLARE @id INT = (SELECT MIN(id_concesion) FROM concesiones.Concesion WHERE estado = 0);
    EXEC concesiones.Concesion_Modificar @id_concesion = @id, @valor_alquiler = 90000.00, @fecha_fin = '2027-12-31';
    PRINT 'CASO 23 OK: valor_alquiler y fecha_fin actualizados';
END TRY
BEGIN CATCH
    PRINT 'CASO 23 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO


-- Concesion_Eliminar

-- CASO 24: concesion inexistente → error
BEGIN TRY
    EXEC concesiones.Concesion_Eliminar @id_concesion = 9999;
    PRINT 'CASO 24 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 24 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 25: baja correcta (segunda concesion, Alquiler de equipos)
BEGIN TRY
    DECLARE @id INT = (SELECT MAX(id_concesion) FROM concesiones.Concesion WHERE estado = 0);
    EXEC concesiones.Concesion_Eliminar @id_concesion = @id;
    PRINT 'CASO 25 OK: concesion dada de baja';
END TRY
BEGIN CATCH
    PRINT 'CASO 25 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 26: ya deshabilitada → error
BEGIN TRY
    DECLARE @id INT = (SELECT MAX(id_concesion) FROM concesiones.Concesion WHERE estado = 1);
    EXEC concesiones.Concesion_Eliminar @id_concesion = @id;
    PRINT 'CASO 26 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 26 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO


-- PagoConcesion_Nuevo

-- CASO 27: concesion inactiva → error
BEGIN TRY
    DECLARE @id INT = (SELECT MAX(id_concesion) FROM concesiones.Concesion WHERE estado = 1);
    EXEC concesiones.PagoConcesion_Nuevo @id_concesion = @id, @fecha_pago = '2026-02-05', @periodo = '2026-01-01', @monto = 45000.00;
    PRINT 'CASO 27 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 27 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 28: fecha_pago NULL → error
BEGIN TRY
    DECLARE @id INT = (SELECT MIN(id_concesion) FROM concesiones.Concesion WHERE estado = 0);
    EXEC concesiones.PagoConcesion_Nuevo @id_concesion = @id, @fecha_pago = NULL, @periodo = '2026-01-01', @monto = 90000.00;
    PRINT 'CASO 28 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 28 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 29: monto = 0 → error
BEGIN TRY
    DECLARE @id INT = (SELECT MIN(id_concesion) FROM concesiones.Concesion WHERE estado = 0);
    EXEC concesiones.PagoConcesion_Nuevo @id_concesion = @id, @fecha_pago = '2026-02-05', @periodo = '2026-01-01', @monto = 0;
    PRINT 'CASO 29 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 29 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 30: pago correcto
BEGIN TRY
    DECLARE @id INT = (SELECT MIN(id_concesion) FROM concesiones.Concesion WHERE estado = 0);
    EXEC concesiones.PagoConcesion_Nuevo @id_concesion = @id, @fecha_pago = '2026-02-05', @periodo = '2026-01-01', @monto = 90000.00;
    PRINT 'CASO 30 OK: pago enero 2026 insertado';
END TRY
BEGIN CATCH
    PRINT 'CASO 30 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 31: periodo duplicado para la misma concesion → error
-- (el SP normaliza cualquier fecha del mes al dia 1, por lo que '2026-01-15' = enero)
BEGIN TRY
    DECLARE @id INT = (SELECT MIN(id_concesion) FROM concesiones.Concesion WHERE estado = 0);
    EXEC concesiones.PagoConcesion_Nuevo @id_concesion = @id, @fecha_pago = '2026-02-10', @periodo = '2026-01-15', @monto = 90000.00;
    PRINT 'CASO 31 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 31 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO


-- PagoConcesion_Modificar

-- CASO 32: pago inexistente → error
BEGIN TRY
    EXEC concesiones.PagoConcesion_Modificar @id_pago = 9999, @monto = 90000.00;
    PRINT 'CASO 32 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 32 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 33: monto negativo → error
BEGIN TRY
    DECLARE @id INT = (SELECT MIN(id_pago) FROM concesiones.PagoConcesion WHERE estado = 0);
    EXEC concesiones.PagoConcesion_Modificar @id_pago = @id, @monto = -500.00;
    PRINT 'CASO 33 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 33 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 34: modificación correcta
BEGIN TRY
    DECLARE @id INT = (SELECT MIN(id_pago) FROM concesiones.PagoConcesion WHERE estado = 0);
    EXEC concesiones.PagoConcesion_Modificar @id_pago = @id, @monto = 85000.00;
    PRINT 'CASO 34 OK: monto actualizado a $85000';
END TRY
BEGIN CATCH
    PRINT 'CASO 34 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO


-- PagoConcesion_Eliminar

-- CASO 35: pago inexistente → error
BEGIN TRY
    EXEC concesiones.PagoConcesion_Eliminar @id_pago = 9999;
    PRINT 'CASO 35 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 35 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 36: baja correcta
BEGIN TRY
    DECLARE @id INT = (SELECT MIN(id_pago) FROM concesiones.PagoConcesion WHERE estado = 0);
    EXEC concesiones.PagoConcesion_Eliminar @id_pago = @id;
    PRINT 'CASO 36 OK: pago dado de baja';
END TRY
BEGIN CATCH
    PRINT 'CASO 36 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 37: ya deshabilitado → error
BEGIN TRY
    DECLARE @id INT = (SELECT MIN(id_pago) FROM concesiones.PagoConcesion WHERE estado = 1);
    EXEC concesiones.PagoConcesion_Eliminar @id_pago = @id;
    PRINT 'CASO 37 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 37 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO


-- Ventas

-- PRECONDICIONES

BEGIN TRY
    EXEC parques.InsertarTipoDeParque @descripcion = 'Nacional';
END TRY
BEGIN CATCH
    PRINT 'Precondicion tipo parque: ' + ERROR_MESSAGE();
END CATCH
GO

DECLARE @id_tipo INT = (SELECT id_tipo_parque FROM parques.TipoParque WHERE descripcion = 'Nacional');
IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = 'Nahuel Huapi')
    EXEC parques.InsertarParque
        @nombre         = 'Nahuel Huapi',
        @id_tipo_parque = @id_tipo,
        @provincia      = 'Neuquén',
        @region         = 'Patagonia',
        @superficie     = 717261.00;
GO


-- TipoVisitante_Nuevo

-- CASO 1: descripcion NULL → error
BEGIN TRY
    EXEC ventas.TipoVisitante_Nuevo @descripcion = NULL;
    PRINT 'CASO 1 FALLO: no debería insertar';
END TRY
BEGIN CATCH
    PRINT 'CASO 1 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 2: descripcion vacía → error
BEGIN TRY
    EXEC ventas.TipoVisitante_Nuevo @descripcion = '   ';
    PRINT 'CASO 2 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 2 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 3: altas correctas (3 tipos)
BEGIN TRY
    EXEC ventas.TipoVisitante_Nuevo @descripcion = 'Residente';
    PRINT 'CASO 3a OK';
END TRY
BEGIN CATCH
    PRINT 'CASO 3a: ' + ERROR_MESSAGE();
END CATCH
GO
BEGIN TRY
    EXEC ventas.TipoVisitante_Nuevo @descripcion = 'Extranjero';
    PRINT 'CASO 3b OK';
END TRY
BEGIN CATCH
    PRINT 'CASO 3b: ' + ERROR_MESSAGE();
END CATCH
GO
BEGIN TRY
    EXEC ventas.TipoVisitante_Nuevo @descripcion = 'Jubilado';
    PRINT 'CASO 3c OK';
END TRY
BEGIN CATCH
    PRINT 'CASO 3c: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 4: descripcion duplicada → error
BEGIN TRY
    EXEC ventas.TipoVisitante_Nuevo @descripcion = 'Residente';
    PRINT 'CASO 4 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 4 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

SELECT id_tipo_visitante, descripcion, estado FROM ventas.TipoVisitante;
GO


-- TipoVisitante_Modificar

-- CASO 5: ID inexistente → error
BEGIN TRY
    EXEC ventas.TipoVisitante_Modificar @id_tipo_visitante = 9999, @descripcion = 'X';
    PRINT 'CASO 5 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 5 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 6: descripcion vacía → error
BEGIN TRY
    DECLARE @id INT = (SELECT id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    EXEC ventas.TipoVisitante_Modificar @id_tipo_visitante = @id, @descripcion = '';
    PRINT 'CASO 6 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 6 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 7: descripcion ya usada por otro tipo → error
BEGIN TRY
    DECLARE @id INT = (SELECT id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    EXEC ventas.TipoVisitante_Modificar @id_tipo_visitante = @id, @descripcion = 'Extranjero';
    PRINT 'CASO 7 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 7 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 8: modificación correcta
BEGIN TRY
    DECLARE @id INT = (SELECT id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Jubilado');
    EXEC ventas.TipoVisitante_Modificar @id_tipo_visitante = @id, @descripcion = 'Jubilado / Pensionado';
    PRINT 'CASO 8 OK: descripcion actualizada';
END TRY
BEGIN CATCH
    PRINT 'CASO 8 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO


-- TipoVisitante_Eliminar

-- CASO 9: ID inexistente → error
BEGIN TRY
    EXEC ventas.TipoVisitante_Eliminar @id_tipo_visitante = 9999;
    PRINT 'CASO 9 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 9 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 10: baja correcta ('Jubilado / Pensionado', sin precios asociados)
BEGIN TRY
    DECLARE @id INT = (SELECT id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Jubilado / Pensionado');
    EXEC ventas.TipoVisitante_Eliminar @id_tipo_visitante = @id;
    PRINT 'CASO 10 OK: tipo dado de baja';
END TRY
BEGIN CATCH
    PRINT 'CASO 10 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 11: ya dado de baja → error
BEGIN TRY
    DECLARE @id INT = (SELECT id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Jubilado / Pensionado');
    EXEC ventas.TipoVisitante_Eliminar @id_tipo_visitante = @id;
    PRINT 'CASO 11 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 11 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 12: modificar tipo dado de baja → error
BEGIN TRY
    DECLARE @id INT = (SELECT id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Jubilado / Pensionado');
    EXEC ventas.TipoVisitante_Modificar @id_tipo_visitante = @id, @descripcion = 'Jubilado';
    PRINT 'CASO 12 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 12 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO


-- PrecioEntrada_Nuevo_Normal

-- CASO 13: parque inexistente → error
BEGIN TRY
    DECLARE @id_res INT = (SELECT id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    EXEC ventas.PrecioEntrada_Nuevo_Normal @id_parque = 9999, @id_tipo_visitante = @id_res, @precio = 1500.00, @fecha_inicio = '2026-01-01';
    PRINT 'CASO 13 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 13 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 14: tipo visitante inexistente → error
BEGIN TRY
    DECLARE @id_p INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Nahuel Huapi');
    EXEC ventas.PrecioEntrada_Nuevo_Normal @id_parque = @id_p, @id_tipo_visitante = 9999, @precio = 1500.00, @fecha_inicio = '2026-01-01';
    PRINT 'CASO 14 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 14 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 15: precio negativo → error
BEGIN TRY
    DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
    DECLARE @id_res INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    EXEC ventas.PrecioEntrada_Nuevo_Normal @id_parque = @id_p, @id_tipo_visitante = @id_res, @precio = -100.00, @fecha_inicio = '2026-01-01';
    PRINT 'CASO 15 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 15 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 16: altas correctas Residente y Extranjero (precios vigentes desde 2026-01-01)
BEGIN TRY
    DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
    DECLARE @id_res INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    EXEC ventas.PrecioEntrada_Nuevo_Normal @id_parque = @id_p, @id_tipo_visitante = @id_res, @precio = 1500.00, @fecha_inicio = '2026-01-01';
    PRINT 'CASO 16a OK: precio Residente $1500 desde 2026-01-01';
END TRY
BEGIN CATCH
    PRINT 'CASO 16a ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO
BEGIN TRY
    DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
    DECLARE @id_ext INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Extranjero');
    EXEC ventas.PrecioEntrada_Nuevo_Normal @id_parque = @id_p, @id_tipo_visitante = @id_ext, @precio = 5000.00, @fecha_inicio = '2026-01-01';
    PRINT 'CASO 16b OK: precio Extranjero $5000 desde 2026-01-01';
END TRY
BEGIN CATCH
    PRINT 'CASO 16b ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 17: precio activo ya existe para ese parque + tipo → error
BEGIN TRY
    DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
    DECLARE @id_res INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    EXEC ventas.PrecioEntrada_Nuevo_Normal @id_parque = @id_p, @id_tipo_visitante = @id_res, @precio = 2000.00, @fecha_inicio = '2026-06-01';
    PRINT 'CASO 17 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 17 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO


-- PrecioEntrada_Nuevo_Temporada

-- CASO 18: fecha_fin < fecha_inicio → error
BEGIN TRY
    DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
    DECLARE @id_res INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    EXEC ventas.PrecioEntrada_Nuevo_Temporada @id_parque = @id_p, @id_tipo_visitante = @id_res,
        @precio = 2000.00, @fecha_inicio = '2026-08-01', @fecha_fin = '2026-07-31';
    PRINT 'CASO 18 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 18 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 19: fecha_inicio = fecha_fin → error (requiere estrictamente menor)
BEGIN TRY
    DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
    DECLARE @id_res INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    EXEC ventas.PrecioEntrada_Nuevo_Temporada @id_parque = @id_p, @id_tipo_visitante = @id_res,
        @precio = 2000.00, @fecha_inicio = '2026-07-01', @fecha_fin = '2026-07-01';
    PRINT 'CASO 19 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 19 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- Precondición: tipo 'Menor' sin precio activo (para tests de Entrada_Nuevo y temporada)
BEGIN TRY
    EXEC ventas.TipoVisitante_Nuevo @descripcion = 'Menor';
    PRINT 'Precondicion tipo Menor OK';
END TRY
BEGIN CATCH
    PRINT 'Precondicion tipo Menor: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 20: alta de temporada correcta (Menor, invierno 2026)
BEGIN TRY
    DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
    DECLARE @id_men INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Menor');
    EXEC ventas.PrecioEntrada_Nuevo_Temporada @id_parque = @id_p, @id_tipo_visitante = @id_men,
        @precio = 750.00, @fecha_inicio = '2026-07-01', @fecha_fin = '2026-08-31';
    PRINT 'CASO 20 OK: precio de temporada Menor $750 (jul-ago 2026)';
END TRY
BEGIN CATCH
    PRINT 'CASO 20 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO


-- PrecioEntrada_Modificar_Precio

-- CASO 21: id_precio inexistente → error
BEGIN TRY
    EXEC ventas.PrecioEntrada_Modificar_Precio @id_precio = 9999, @precio = 2000.00;
    PRINT 'CASO 21 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 21 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 22: precio negativo → error
BEGIN TRY
    DECLARE @id_prec INT = (
        SELECT pe.id_precio FROM ventas.PrecioEntrada pe
        JOIN ventas.TipoVisitante tv ON tv.id_tipo_visitante = pe.id_tipo_visitante
        WHERE tv.descripcion = 'Residente' AND pe.estado = 0
    );
    EXEC ventas.PrecioEntrada_Modificar_Precio @id_precio = @id_prec, @precio = -1.00;
    PRINT 'CASO 22 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 22 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 23: modificación correcta
BEGIN TRY
    DECLARE @id_prec INT = (
        SELECT pe.id_precio FROM ventas.PrecioEntrada pe
        JOIN ventas.TipoVisitante tv ON tv.id_tipo_visitante = pe.id_tipo_visitante
        WHERE tv.descripcion = 'Residente' AND pe.estado = 0
    );
    EXEC ventas.PrecioEntrada_Modificar_Precio @id_precio = @id_prec, @precio = 1800.00;
    PRINT 'CASO 23 OK: precio Residente actualizado a $1800';
END TRY
BEGIN CATCH
    PRINT 'CASO 23 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO


-- PrecioEntrada_Eliminar

-- CASO 24: id_precio inexistente → error
BEGIN TRY
    EXEC ventas.PrecioEntrada_Eliminar @id_precio = 9999;
    PRINT 'CASO 24 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 24 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 25: baja correcta (precio de temporada Menor)
BEGIN TRY
    DECLARE @id_prec INT = (
        SELECT pe.id_precio FROM ventas.PrecioEntrada pe
        JOIN ventas.TipoVisitante tv ON tv.id_tipo_visitante = pe.id_tipo_visitante
        WHERE tv.descripcion = 'Menor' AND pe.estado = 0
    );
    EXEC ventas.PrecioEntrada_Eliminar @id_precio = @id_prec;
    PRINT 'CASO 25 OK: precio Menor dado de baja';
END TRY
BEGIN CATCH
    PRINT 'CASO 25 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 26: ya dado de baja → error
BEGIN TRY
    DECLARE @id_prec INT = (
        SELECT pe.id_precio FROM ventas.PrecioEntrada pe
        JOIN ventas.TipoVisitante tv ON tv.id_tipo_visitante = pe.id_tipo_visitante
        WHERE tv.descripcion = 'Menor' AND pe.estado = 1
    );
    EXEC ventas.PrecioEntrada_Eliminar @id_precio = @id_prec;
    PRINT 'CASO 26 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 26 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 27: eliminar tipo visitante con precios activos → error
BEGIN TRY
    DECLARE @id INT = (SELECT id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    EXEC ventas.TipoVisitante_Eliminar @id_tipo_visitante = @id;
    PRINT 'CASO 27 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 27 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

SELECT id_precio, id_parque, id_tipo_visitante, precio, fecha_inicio, fecha_fin, estado
FROM ventas.PrecioEntrada ORDER BY id_precio;
GO

--====================================================================================
--								TEST ABM TIPOS DE PARQUES
--====================================================================================

-- CASO 1: Alta correcta
-- Esperado: inserta sin error
BEGIN TRY
    EXEC parques.InsertarTipoDeParque @descripcion = 'Parque Nacional';
    PRINT 'CASO 1 OK: tipo de parque insertado';
END TRY
BEGIN CATCH
    PRINT 'CASO 1 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO
SELECT * FROM parques.tipoParque WHERE descripcion = 'Parque Nacional';
GO

-- CASO 2: Alta con descripcion vacia
-- Esperado: RECHAZO 'La descripcion es obligatoria'
BEGIN TRY
    EXEC parques.InsertarTipoDeParque @descripcion = '';
    PRINT 'CASO 2 FALLO: no deberia haber insertado';
END TRY
BEGIN CATCH
    PRINT 'CASO 2 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 3: Alta duplicada
-- Esperado: RECHAZO 'Ya existe un tipo de parque con esa descripcion'
BEGIN TRY
    EXEC parques.InsertarTipoDeParque @descripcion = 'Parque Nacional';
    PRINT 'CASO 3 FALLO: no deberia haber insertado';
END TRY
BEGIN CATCH
    PRINT 'CASO 3 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 4: Modificacion correcta
-- Esperado: actualiza la descripcion
BEGIN TRY
    EXEC parques.ModificarTipoDeParque @id_tipo_parque = 1, @descripcion = 'Parque Acuatico';
    PRINT 'CASO 4 OK: tipo de parque modificado';
END TRY
BEGIN CATCH
    PRINT 'CASO 4 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO
SELECT * FROM parques.TipoParque WHERE id_tipo_parque = 1;
GO

-- CASO 5: Modificar un tipo inexistente
-- Esperado: RECHAZO 'El tipo de parque no existe o esta dado de baja'
BEGIN TRY
    EXEC parques.ModificarTipoDeParque @id_tipo_parque = 9999, @descripcion = 'Cualquiera';
    PRINT 'CASO 5 FALLO: no deberia haber modificado';
END TRY
BEGIN CATCH
    PRINT 'CASO 5 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 6: Baja logica de un tipo de parque
-- Esperado: marca estado = 1 (no borra fisicamente)
BEGIN TRY
    EXEC parques.EliminarTipoDeParque @id_tipo_parque = 1;
    PRINT 'CASO 6 OK: tipo de parque dado de baja';
END TRY
BEGIN CATCH
    PRINT 'CASO 6 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO
SELECT id_tipo_parque, descripcion, estado FROM parques.TipoParque WHERE id_tipo_parque = 1;
GO

-- CASO 7: Eliminar un tipo ya dado de baja
-- Esperado: RECHAZO 'El tipo de parque ya esta dado de baja'
BEGIN TRY
    EXEC parques.EliminarTipoDeParque @id_tipo_parque = 1;
    PRINT 'CASO 7 FALLO: no deberia haber eliminado';
END TRY
BEGIN CATCH
    PRINT 'CASO 7 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

--====================================================================================
--								TEST ABM PARQUES
--====================================================================================

-- PRECONDICIONES: tipos de parque necesarios para las pruebas
BEGIN TRY
    EXEC parques.InsertarTipoDeParque @descripcion = 'Parque Acuatico';
END TRY 
BEGIN CATCH 
	PRINT 'Precondicion 1: ' + ERROR_MESSAGE(); 
	END CATCH
GO
BEGIN TRY
    EXEC parques.InsertarTipoDeParque @descripcion = 'Reserva Natural';
END TRY 
BEGIN CATCH 
	PRINT 'Precondicion 2: ' + ERROR_MESSAGE(); 
END CATCH
GO

-- CASO 1: Alta correcta con coordenadas
-- Esperado: inserta sin error
BEGIN TRY
    EXEC parques.InsertarParque
        @nombre = 'Los Glaciares', @id_tipo_parque = 1, @provincia = 'Salta',
        @region = 'Santa Cruz', @latitud = -50.476100,
        @longitud = -73.037700, @superficie = 726927.00;
    PRINT 'CASO 1 OK: parque insertado con coordenadas';
END TRY
BEGIN CATCH
    PRINT 'CASO 1 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO
SELECT * FROM parques.Parque WHERE nombre = 'Los Glaciares';
GO

-- CASO 2: Alta correcta sin coordenadas (opcionales)
-- Esperado: inserta sin error (lat y long en NULL)
BEGIN TRY
    EXEC parques.InsertarParque
        @nombre = 'Iguazu', @id_tipo_parque = 1,
        @region = 'Misiones', @superficie = 67000.00;
    PRINT 'CASO 2 OK: parque insertado sin coordenadas';
END TRY
BEGIN CATCH
    PRINT 'CASO 2 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 3: Alta con nombre vacio + tipo inexistente
-- Esperado: RECHAZO con 2 mensajes acumulados
BEGIN TRY
    EXEC parques.InsertarParque @nombre = '', @id_tipo_parque = 9999;
    PRINT 'CASO 3 FALLO: no deberia haber insertado';
END TRY
BEGIN CATCH
    PRINT 'CASO 3 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 4: Alta con nombre duplicado
-- Esperado: RECHAZO 'Ya existe un parque con ese nombre'
BEGIN TRY
    EXEC parques.InsertarParque @nombre = 'Los Glaciares', @id_tipo_parque = 1;
    PRINT 'CASO 4 FALLO: no deberia haber insertado';
END TRY
BEGIN CATCH
    PRINT 'CASO 4 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 5: Alta con superficie negativa
-- Esperado: RECHAZO 'La superficie debe ser mayor a cero'
BEGIN TRY
    EXEC parques.InsertarParque
        @nombre = 'Parque Test', @id_tipo_parque = 1, @superficie = -500;
    PRINT 'CASO 5 FALLO: no deberia haber insertado';
END TRY
BEGIN CATCH
    PRINT 'CASO 5 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 6: Alta con solo una coordenada
-- Esperado: RECHAZO 'Debe indicar latitud y longitud juntas, o ninguna'
BEGIN TRY
    EXEC parques.InsertarParque
        @nombre = 'Parque Coordenada', @id_tipo_parque = 1,
        @latitud = -34.6, @longitud = NULL;
    PRINT 'CASO 6 FALLO: no deberia haber insertado';
END TRY
BEGIN CATCH
    PRINT 'CASO 6 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 7: Modificacion correcta
-- Esperado: actualiza el parque
BEGIN TRY
    EXEC parques.ModificarParque
        @id_parque = 1, @nombre = 'Los Glaciares', @id_tipo_parque = 2,
        @region = 'Santa Cruz - Patagonia', @superficie = 726927.00;
    PRINT 'CASO 7 OK: parque modificado';
END TRY
BEGIN CATCH
    PRINT 'CASO 7 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO
SELECT * FROM parques.Parque WHERE id_parque = 1;
GO

-- CASO 8: Modificar nombre a uno que ya usa OTRO parque
-- Esperado: RECHAZO 'Otro parque ya usa ese nombre'
BEGIN TRY
    EXEC parques.ModificarParque
        @id_parque = 1, @nombre = 'Iguazu', @id_tipo_parque = 1;
    PRINT 'CASO 8 FALLO: no deberia haber modificado';
END TRY
BEGIN CATCH
    PRINT 'CASO 8 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 9: Baja logica de un parque sin dependencias
-- Esperado: marca estado = 1 (no borra fisicamente)
BEGIN TRY
    EXEC parques.EliminarParque @id_parque = 2;
    PRINT 'CASO 9 OK: parque dado de baja logicamente';
END TRY
BEGIN CATCH
    PRINT 'CASO 9 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO
SELECT id_parque, nombre, estado FROM parques.Parque WHERE id_parque = 2;
GO

-- CASO 10: Eliminar un parque ya dado de baja
-- Esperado: RECHAZO 'El parque ya esta dado de baja'
BEGIN TRY
    EXEC parques.EliminarParque @id_parque = 2;
    PRINT 'CASO 10 FALLO: no deberia haber eliminado';
END TRY
BEGIN CATCH
    PRINT 'CASO 10 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 11: Eliminar parque inexistente
-- Esperado: RECHAZO 'El parque no existe'
BEGIN TRY
    EXEC parques.EliminarParque @id_parque = 9999;
    PRINT 'CASO 11 FALLO: no deberia haber eliminado';
END TRY
BEGIN CATCH
    PRINT 'CASO 11 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO