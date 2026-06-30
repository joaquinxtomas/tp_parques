--              PARQUESNACIONALES

USE ParquesNacionales;
GO

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  TESTS - CONCESIONES                                          ║
-- ╚═══════════════════════════════════════════════════════════════╝

PRINT '═══════════════════════════════════════════════════';
PRINT '                 TESTS - CONCESIONES               ';
PRINT '═══════════════════════════════════════════════════';


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


-- ─── Empresa_Nueva ────────────────────────────────────────────

PRINT '';
PRINT '─── Empresa_Nueva ───────────────────────────────';

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


-- ─── Empresa_Modificar ────────────────────────────────────────────

PRINT '';
PRINT '─── Empresa_Modificar ───────────────────────────────';

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


-- ─── Empresa_Eliminar ────────────────────────────────────────────

PRINT '';
PRINT '─── Empresa_Eliminar ───────────────────────────────';

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


-- ─── Concesion_Nueva ────────────────────────────────────────────

PRINT '';
PRINT '─── Concesion_Nueva ───────────────────────────────';

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


-- ─── Concesion_Modificar ────────────────────────────────────────────

PRINT '';
PRINT '─── Concesion_Modificar ───────────────────────────────';

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


-- ─── Concesion_Eliminar ────────────────────────────────────────────

PRINT '';
PRINT '─── Concesion_Eliminar ───────────────────────────────';

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


-- ─── PagoConcesion_Nuevo ────────────────────────────────────────────

PRINT '';
PRINT '─── PagoConcesion_Nuevo ───────────────────────────────';

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


-- ─── PagoConcesion_Modificar ────────────────────────────────────────────

PRINT '';
PRINT '─── PagoConcesion_Modificar ───────────────────────────────';

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


-- ─── PagoConcesion_Eliminar ────────────────────────────────────────────

PRINT '';
PRINT '─── PagoConcesion_Eliminar ───────────────────────────────';

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


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  TESTS - VENTAS                                               ║
-- ╚═══════════════════════════════════════════════════════════════╝

PRINT '═══════════════════════════════════════════════════';
PRINT '                 TESTS - VENTAS                    ';
PRINT '═══════════════════════════════════════════════════';

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


-- ─── TipoVisitante_Nuevo ────────────────────────────────────────────

PRINT '';
PRINT '─── TipoVisitante_Nuevo ───────────────────────────────';

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


-- ─── TipoVisitante_Modificar ────────────────────────────────────────────

PRINT '';
PRINT '─── TipoVisitante_Modificar ───────────────────────────────';

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


-- ─── TipoVisitante_Eliminar ────────────────────────────────────────────

PRINT '';
PRINT '─── TipoVisitante_Eliminar ───────────────────────────────';

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


-- ─── PrecioEntrada_Nuevo_Normal ────────────────────────────────────────────

PRINT '';
PRINT '─── PrecioEntrada_Nuevo_Normal ───────────────────────────────';

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


-- ─── PrecioEntrada_Nuevo_Temporada ────────────────────────────────────────────

PRINT '';
PRINT '─── PrecioEntrada_Nuevo_Temporada ───────────────────────────────';

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


-- ─── PrecioEntrada_Modificar_Precio ────────────────────────────────────────────

PRINT '';
PRINT '─── PrecioEntrada_Modificar_Precio ───────────────────────────────';

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

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  TESTS - TIPO DE PARQUES                                      ║
-- ╚═══════════════════════════════════════════════════════════════╝

PRINT '═══════════════════════════════════════════════════';
PRINT '               TESTS - TIPO DE PARQUES             ';
PRINT '═══════════════════════════════════════════════════';

-- ─── InsertarTipoDeParque ────────────────────────────────────────────

PRINT '';
PRINT '─── InsertarTipoDeParque ───────────────────────────────';

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

-- ─── ModificarTipoDeParque ────────────────────────────────────────────

PRINT '';
PRINT '─── ModificarTipoDeParque ───────────────────────────────';

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

-- ─── EliminarTipoDeParque ────────────────────────────────────────────

PRINT '';
PRINT '─── EliminarTipoDeParque ───────────────────────────────';

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

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  TESTS - PARQUES                                              ║
-- ╚═══════════════════════════════════════════════════════════════╝

PRINT '═══════════════════════════════════════════════════';
PRINT '                 TESTS - PARQUES                   ';
PRINT '═══════════════════════════════════════════════════';


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


-- ─── InsertarParque ────────────────────────────────────────────

PRINT '';
PRINT '─── InsertarParque ───────────────────────────────';

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

-- ─── ModificarParque ────────────────────────────────────────────

PRINT '';
PRINT '─── ModificarParque ───────────────────────────────';

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

-- ─── EliminarParque ────────────────────────────────────────────

PRINT '';
PRINT '─── EliminarParque ───────────────────────────────';

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


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  TESTS - ACTIVIDADES                                          ║
-- ╚═══════════════════════════════════════════════════════════════╝

PRINT '═══════════════════════════════════════════════════';
PRINT '                 TESTS - ACTIVIDADES               ';
PRINT '═══════════════════════════════════════════════════';

-- PRECONDICIONES
BEGIN TRY
    EXEC parques.InsertarTipoDeParque 'Parque Nacional';
END TRY
BEGIN CATCH
    PRINT 'Precondicion tipo parque: ' + ERROR_MESSAGE();
END CATCH
GO

IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = 'Parque Nacional Iguazu')
    INSERT INTO parques.Parque (nombre, id_tipo_parque, region)
    VALUES ('Parque Nacional Iguazu',
            (SELECT id_tipo_parque FROM parques.TipoParque WHERE descripcion = 'Parque Nacional'),
            'Litoral');

IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = 'Parque Nacional Nahuel Huapi')
    INSERT INTO parques.Parque (nombre, id_tipo_parque, region)
    VALUES ('Parque Nacional Nahuel Huapi',
            (SELECT id_tipo_parque FROM parques.TipoParque WHERE descripcion = 'Parque Nacional'),
            'Cuyo');
GO

-- ─── InsertarAtraccion ────────────────────────────────────────────
PRINT '';
PRINT '─── InsertarAtraccion ───────────────────────────────';

-- CASO 1: inserción normal
BEGIN TRY
    DECLARE @id_p INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Iguazu');
    EXEC actividades.InsertarAtraccion
        @id_parque = @id_p, @nombre = 'Paseo por la Garganta del Diablo',
        @costo = 5000.00, @duracion = 90, @cupo_maximo = 25, @tipo = 'Senderismo', @turno = '09:00';
    PRINT 'CASO 1 OK: atracción insertada';
END TRY
BEGIN CATCH
    PRINT 'CASO 1 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 2: insertar con costo 0 (gratuita)
BEGIN TRY
    DECLARE @id_p INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Iguazu');
    EXEC actividades.InsertarAtraccion
        @id_parque = @id_p, @nombre = 'Mirador Salto Bossetti',
        @costo = 0.00, @duracion = 30, @cupo_maximo = NULL, @tipo = 'Avistaje', @turno = '10:00';
    PRINT 'CASO 2 OK: atracción gratuita insertada';
END TRY
BEGIN CATCH
    PRINT 'CASO 2 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 3: insertar con duración y cupo NULL
BEGIN TRY
    DECLARE @id_p INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Nahuel Huapi');
    EXEC actividades.InsertarAtraccion
        @id_parque = @id_p, @nombre = 'Acceso libre al Cerro Campanario',
        @costo = 0.00, @duracion = NULL, @cupo_maximo = NULL, @tipo = 'Senderismo', @turno = '08:00';
    PRINT 'CASO 3 OK: atracción con NULLs insertada';
END TRY
BEGIN CATCH
    PRINT 'CASO 3 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 4: mismo nombre en otro parque (debe funcionar)
BEGIN TRY
    DECLARE @id_p INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Nahuel Huapi');
    EXEC actividades.InsertarAtraccion
        @id_parque = @id_p, @nombre = 'Paseo por la Garganta del Diablo',
        @costo = 3500.00, @duracion = 60, @cupo_maximo = 20, @tipo = 'Senderismo', @turno = '09:00';
    PRINT 'CASO 4 OK: mismo nombre en otro parque insertado';
END TRY
BEGIN CATCH
    PRINT 'CASO 4 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 5: nombre + parque + turno duplicado → error
BEGIN TRY
    DECLARE @id_p INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Iguazu');
    EXEC actividades.InsertarAtraccion
        @id_parque = @id_p, @nombre = 'Paseo por la Garganta del Diablo',
        @costo = 5500.00, @duracion = 90, @cupo_maximo = 25, @tipo = 'Senderismo', @turno = '09:00';
    PRINT 'CASO 5 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 5 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 6: parque inexistente
BEGIN TRY
    EXEC actividades.InsertarAtraccion
        @id_parque = 99999, @nombre = 'Atraccion en parque fantasma',
        @costo = 1000.00, @duracion = 45, @cupo_maximo = 15, @tipo = 'Cultural', @turno = '09:00';
    PRINT 'CASO 6 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 6 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- ver lo que quedó cargado
SELECT a.id_atraccion, p.nombre AS parque, a.nombre AS atraccion,
       a.costo, a.turno ,a.duracion AS duracion_min, a.cupo_maximo, a.tipo
FROM actividades.Atraccion a
INNER JOIN parques.Parque p ON p.id_parque = a.id_parque
ORDER BY a.id_atraccion;
GO

-- ─── ActualizarAtraccion ────────────────────────────────────────────
PRINT '';
PRINT '─── ActualizarAtraccion ───────────────────────────────';

-- prerequisitos
BEGIN TRY
    DECLARE @id_ig INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Iguazu');
    DECLARE @id_na INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Nahuel Huapi');
    EXEC actividades.InsertarAtraccion @id_ig, 'TEST_Sendero', 1000, 60, 20, 'Senderismo', '09:00';
    EXEC actividades.InsertarAtraccion @id_ig, 'TEST_Mirador', 0, 30, NULL, 'Avistaje', '10:00';
    EXEC actividades.InsertarAtraccion @id_na, 'TEST_Kayak', 2500, 90, 10, 'Acuatica', '11:00';
    PRINT 'PREREQUISITOS MODIFICACION OK';
END TRY
BEGIN CATCH
    PRINT 'PREREQUISITOS MODIFICACION ERROR: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 7: modificación válida, cambia costo y duración (mismo turno)
BEGIN TRY
    DECLARE @id INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Sendero');
    EXEC actividades.ActualizarAtraccion
        @id_atraccion = @id, @nombre = 'TEST_Sendero',
        @costo = 1500, @duracion = 75, @cupo_maximo = 20, @tipo = 'Senderismo', @turno = '09:00';
    PRINT 'CASO 7 OK: costo y duración actualizados';
END TRY
BEGIN CATCH
    PRINT 'CASO 7 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 8: cambio de nombre
BEGIN TRY
    DECLARE @id INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Mirador');
    EXEC actividades.ActualizarAtraccion
        @id_atraccion = @id, @nombre = 'TEST_Mirador Renovado',
        @costo = 0, @duracion = 30, @cupo_maximo = NULL, @tipo = 'Avistaje', @turno = '11:00';
    PRINT 'CASO 8 OK: nombre actualizado';
END TRY
BEGIN CATCH
    PRINT 'CASO 8 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 9: id de atracción inexistente
BEGIN TRY
    EXEC actividades.ActualizarAtraccion
        @id_atraccion = 99999, @nombre = 'Fantasma',
        @costo = 100, @duracion = 30, @cupo_maximo = 10, @tipo = 'Senderismo', @turno = '09:00';
    PRINT 'CASO 9 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 9 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 10: cambiar nombre a uno que existe en OTRO parque (debe funcionar)
BEGIN TRY
    DECLARE @id INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Sendero');
    EXEC actividades.ActualizarAtraccion
        @id_atraccion = @id, @nombre = 'TEST_Kayak',
        @costo = 1500, @duracion = 75, @cupo_maximo = 20, @tipo = 'Senderismo', @turno = '09:00';
    PRINT 'CASO 10 OK: nombre duplicado en otro parque permitido';
END TRY
BEGIN CATCH
    PRINT 'CASO 10 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 11: nombre existente en otro parque (debe funcionar)
BEGIN TRY
    DECLARE @id INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Kayak'
        AND id_parque = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Nahuel Huapi'));
    EXEC actividades.ActualizarAtraccion
        @id_atraccion = @id, @nombre = 'TEST_Mirador Renovado',
        @costo = 2500, @duracion = 90, @cupo_maximo = 10, @tipo = 'Acuatica', @turno = '11:00';
    PRINT 'CASO 11 OK: nombre de otro parque permitido';
END TRY
BEGIN CATCH
    PRINT 'CASO 11 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 12: múltiples errores (nombre vacío, costo negativo, duración negativa, cupo 0, tipo vacío) → error
BEGIN TRY
    DECLARE @id INT = (SELECT TOP 1 id_atraccion FROM actividades.Atraccion WHERE nombre LIKE 'TEST_%'
        AND id_parque = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Iguazu'));
    EXEC actividades.ActualizarAtraccion
        @id_atraccion = @id, @nombre = '',
        @costo = -100, @duracion = -5, @cupo_maximo = 0, @tipo = '', @turno = '09:00';
    PRINT 'CASO 12 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 12 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO
-- ─── EliminarAtraccion ────────────────────────────────────────────

PRINT '';
PRINT '─── EliminarAtraccion ───────────────────────────────';

-- CASO 13: baja correcta
BEGIN TRY
    DECLARE @id INT = (SELECT MIN(id_atraccion) FROM actividades.Atraccion WHERE estado = 0);
    EXEC actividades.EliminarAtraccion @id_atraccion = @id;
    PRINT 'CASO 13 OK: atracción dada de baja';
END TRY
BEGIN CATCH
    PRINT 'CASO 13 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 14: atracción inexistente
BEGIN TRY
    EXEC actividades.EliminarAtraccion @id_atraccion = 99999;
    PRINT 'CASO 14 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 14 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 15: ya dada de baja
BEGIN TRY
    DECLARE @id INT = (SELECT MIN(id_atraccion) FROM actividades.Atraccion WHERE estado = 1);
    EXEC actividades.EliminarAtraccion @id_atraccion = @id;
    PRINT 'CASO 15 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 15 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- ─── ACTIVIDADES SIMULTANEAS ─────────────────────────────────
PRINT '';
PRINT '─── Actividades simultaneas (mismo parque, mismo turno) ───';

-- CASO 16: dos atracciones DISTINTAS, mismo parque, mismo turno -> AMBAS OK
BEGIN TRY
    DECLARE @id_p INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Iguazu');
    EXEC actividades.InsertarAtraccion
        @id_parque = @id_p, @nombre = 'Safari Fotografico',
        @costo = 4000, @duracion = 90, @cupo_maximo = 15, @tipo = 'Avistaje', @turno = '14:00';
    EXEC actividades.InsertarAtraccion
        @id_parque = @id_p, @nombre = 'Caminata Botanica',
        @costo = 2000, @duracion = 90, @cupo_maximo = 10, @tipo = 'Senderismo', @turno = '14:00';
    PRINT 'CASO 16 OK: dos actividades distintas coexisten en el mismo parque y turno (simultaneas)';
END TRY
BEGIN CATCH
    PRINT 'CASO 16 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 17: misma actividad (mismo nombre) en el mismo parque pero OTRO turno -> OK
BEGIN TRY
    DECLARE @id_p INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Iguazu');
    EXEC actividades.InsertarAtraccion
        @id_parque = @id_p, @nombre = 'Safari Fotografico',
        @costo = 4000, @duracion = 90, @cupo_maximo = 15, @tipo = 'Avistaje', @turno = '17:00';
    PRINT 'CASO 17 OK: misma actividad en otro turno permitida';
END TRY
BEGIN CATCH
    PRINT 'CASO 17 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- Verificacion: actividades de Iguazu en el turno 14:00 (deben ser 2 distintas = simultaneas)
SELECT a.nombre, a.turno, p.nombre AS parque
FROM actividades.Atraccion a
INNER JOIN parques.Parque p ON p.id_parque = a.id_parque
WHERE p.nombre = 'Parque Nacional Iguazu' AND a.turno = '14:00' AND a.estado = 0;
GO


-- ver cómo quedó la tabla
SELECT id_atraccion, nombre, costo, duracion, cupo_maximo, tipo, estado
FROM actividades.Atraccion
WHERE nombre LIKE 'TEST_%'
ORDER BY id_atraccion;
GO

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  TESTS - TOURGUIA                                             ║
-- ╚═══════════════════════════════════════════════════════════════╝

PRINT '═══════════════════════════════════════════════════';
PRINT '                 TESTS - TOURGUIA                  ';
PRINT '═══════════════════════════════════════════════════';

-- PRECONDICIONES
-- PRECONDICIONES TOURGUIA
DECLARE @id_iguazu INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Iguazu');

IF NOT EXISTS (SELECT 1 FROM personal.GuiaAutorizado WHERE dni = '11111111')
    INSERT INTO personal.GuiaAutorizado (nombre, dni, especialidad, titulo, vigencia_desde)
    VALUES ('Guia Test 1', '11111111', 'Flora', 'Licenciado', '2024-01-01');

IF NOT EXISTS (SELECT 1 FROM personal.GuiaAutorizado WHERE dni = '22222222')
    INSERT INTO personal.GuiaAutorizado (nombre, dni, especialidad, titulo, vigencia_desde)
    VALUES ('Guia Test 2', '22222222', 'Fauna', NULL, '2024-01-01');

-- limpiar asignaciones previas de la atracción de test
DELETE FROM actividades.TourGuia 
WHERE id_atraccion = (SELECT id_atraccion FROM actividades.Atraccion 
                      WHERE nombre = 'TEST_Tour_Selva' AND turno = '12:00');  -- agrego turno para identificar única

-- si existe pero está dada de baja, reactivarla
IF EXISTS (SELECT 1 FROM actividades.Atraccion WHERE nombre = 'TEST_Tour_Selva' AND turno = '12:00' AND estado = 1)
    UPDATE actividades.Atraccion SET estado = 0 WHERE nombre = 'TEST_Tour_Selva' AND turno = '12:00';

-- si no existe, crearla
IF NOT EXISTS (SELECT 1 FROM actividades.Atraccion WHERE nombre = 'TEST_Tour_Selva' AND turno = '12:00')
    EXEC actividades.InsertarAtraccion @id_iguazu, 'TEST_Tour_Selva', 3000, 120, 15, 'Senderismo', '12:00';
GO

-- ─── InsertarTourGuia ────────────────────────────────────────────

PRINT '';
PRINT '─── InsertarTourGuia ───────────────────────────────';

-- CASO 1: asignar guía a atracción
BEGIN TRY
    DECLARE @id_tour INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Tour_Selva' AND turno = '12:00');
    DECLARE @id_guia INT = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni = '11111111');
    EXEC actividades.InsertarTourGuia @id_atraccion = @id_tour, @id_guia = @id_guia;
    PRINT 'CASO 1 OK: guía asignado a atracción';
END TRY
BEGIN CATCH
    PRINT 'CASO 1 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 2: asignar segundo guía a la misma atracción
BEGIN TRY
	DECLARE @id_tour INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Tour_Selva' AND turno = '12:00');
	DECLARE @id_guia INT = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni = '22222222');
    EXEC actividades.InsertarTourGuia @id_atraccion = @id_tour, @id_guia = @id_guia;
    PRINT 'CASO 2 OK: segundo guía asignado';
END TRY
BEGIN CATCH
    PRINT 'CASO 2 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 3: guía ya asignado (duplicado) → error
BEGIN TRY
    DECLARE @id_tour INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Tour_Selva' AND turno = '12:00');
    DECLARE @id_guia INT = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni = '11111111');
    EXEC actividades.InsertarTourGuia @id_atraccion = @id_tour, @id_guia = @id_guia;
    PRINT 'CASO 3 FALLO';
=======
--====================================================================================
--								TEST ABM PERSONAL
--====================================================================================
-- Pruebas asignacionGP_alta

-- 1: Id de parque obligatorio
BEGIN TRY
    PRINT 'CASO 1 FALLO: No ingresó parque.';
    EXEC personal.asignacionGP_alta @id_guardaparque = 1, @id_parque = NULL, @id_guia = 1, @fecha_desde = '2026-07-01', @fecha_hasta = '2026-12-31', @motivo = 'Error Parque NULL';
END TRY
BEGIN CATCH
    PRINT 'CASO 1 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO
-- 2: Parque inexistente
BEGIN TRY
    PRINT 'CASO 2 FALLO: no existe el parque';
    EXEC personal.asignacionGP_alta @id_guardaparque = 1, @id_parque = 999, @id_guia = 1, @fecha_desde = '2026-07-01', @fecha_hasta = '2026-12-31', @motivo = 'Error Parque Inexistente';
END TRY
BEGIN CATCH
    PRINT 'CASO 2 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO
-- 3: Id de guardaparque obligatorio
BEGIN TRY
    EXEC personal.asignacionGP_alta @id_guardaparque = NULL, @id_parque = 1, @id_guia = 1, @fecha_desde = '2026-07-01', @fecha_hasta = '2026-12-31', @motivo = 'Error Guardaparque NULL';
    PRINT 'CASO 3 FALLO: No ingresó guardaparque';
END TRY
BEGIN CATCH
    PRINT 'CASO 3 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO


-- CASO 4: guía inexistente → error
BEGIN TRY
    DECLARE @id_tour INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Tour_Selva' AND turno = '12:00');
    EXEC actividades.InsertarTourGuia @id_atraccion = @id_tour, @id_guia = 99999;
    PRINT 'CASO 4 FALLO';
=======
-- 4: Guardaparque inexistente
BEGIN TRY
    EXEC personal.asignacionGP_alta @id_guardaparque = 999, @id_parque = 1, @id_guia = 1, @fecha_desde = '2026-07-01', @fecha_hasta = '2026-12-31', @motivo = 'Error Guardaparque Inexistente';
    PRINT 'CASO 4 FALLO: no existe el guardaparque';
END TRY
BEGIN CATCH
    PRINT 'CASO 4 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO


-- CASO 5: atracción inexistente → error
BEGIN TRY
    DECLARE @id_guia INT = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni = '11111111');
    EXEC actividades.InsertarTourGuia @id_atraccion = 99999, @id_guia = @id_guia;
    PRINT 'CASO 5 FALLO';
=======
-- 5: Guía inexistente
BEGIN TRY
    EXEC personal.asignacionGP_alta @id_guardaparque = 1, @id_parque = 1, @id_guia = 999, @fecha_desde = '2026-07-01', @fecha_hasta = '2026-12-31', @motivo = 'Error Guía Inexistente';
    PRINT 'CASO 5 FALLO: No existe el guía';
END TRY
BEGIN CATCH
    PRINT 'CASO 5 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 6: ambos NULL → error
BEGIN TRY
    EXEC actividades.InsertarTourGuia @id_atraccion = NULL, @id_guia = NULL;
    PRINT 'CASO 6 FALLO';
=======
-- 6: Fecha de comienzo obligatoria
BEGIN TRY
    EXEC personal.asignacionGP_alta @id_guardaparque = 1, @id_parque = 1, @id_guia = 1, @fecha_desde = NULL, @fecha_hasta = '2026-12-31', @motivo = 'Error Fecha NULL';
    PRINT 'CASO 6 FALLO: no ingreso fecha inicial';
END TRY
BEGIN CATCH
    PRINT 'CASO 6 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- verificar altas
SELECT tg.id_tour_guia, a.nombre AS atraccion,a.turno, g.nombre AS guia, tg.estado
FROM actividades.TourGuia tg
INNER JOIN actividades.Atraccion a ON a.id_atraccion = tg.id_atraccion
INNER JOIN personal.GuiaAutorizado g ON g.id_guia = tg.id_guia
WHERE a.nombre = 'TEST_Tour_Selva';
GO


-- ─── EliminarTourGuia ────────────────────────────────────────────

PRINT '';
PRINT '─── EliminarTourGuia ───────────────────────────────';

-- CASO 7: baja válida
BEGIN TRY
    DECLARE @id INT = (
        SELECT TOP 1 id_tour_guia FROM actividades.TourGuia
        WHERE id_guia = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni = '11111111')
          AND estado = 0
    );
    EXEC actividades.EliminarTourGuia @id_tour_guia = @id;
    PRINT 'CASO 7 OK: tour dado de baja';
END TRY
BEGIN CATCH
    PRINT 'CASO 7 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 8: ya dada de baja → error
BEGIN TRY
    DECLARE @id INT = (
        SELECT TOP 1 id_tour_guia FROM actividades.TourGuia
        WHERE id_guia = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni = '11111111')
          AND estado = 1
    );
    EXEC actividades.EliminarTourGuia @id_tour_guia = @id;
    PRINT 'CASO 8 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 8 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 9: tour inexistente → error
BEGIN TRY
    EXEC actividades.EliminarTourGuia @id_tour_guia = 99999;
    PRINT 'CASO 9 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 9 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- verificar bajas
SELECT tg.id_tour_guia, a.nombre AS atraccion, g.nombre AS guia, tg.estado
FROM actividades.TourGuia tg
INNER JOIN actividades.Atraccion a ON a.id_atraccion = tg.id_atraccion
INNER JOIN personal.GuiaAutorizado g ON g.id_guia = tg.id_guia
WHERE a.nombre = 'TEST_Tour_Selva';
=======
-- 7: Asignación duplicada
BEGIN TRY
    EXEC personal.asignacionGP_alta @id_guardaparque = 1, @id_parque = 1, @id_guia = NULL, @fecha_desde = '2026-01-01', @fecha_hasta = '2026-06-30', @motivo = 'Error Duplicado';
    PRINT 'CASO 7 FALLO: no puede hacer asignación';
END TRY
BEGIN CATCH
    PRINT 'CASO 7 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

--    EXEC parques.EliminarParque @id_parque = 9999;

-- Pruebas guardaparque
-- Alta
-- Nombre obligatorio
BEGIN TRY
    PRINT 'CASO 1 FALLO: no ingresó nombre';
    EXEC personal.guardaparque_alta @nombre = NULL, @dni = '45111222', @vigencia_desde = '2026-06-18', @vigencia_hasta = '2030-12-31';
END TRY
BEGIN CATCH
    PRINT 'CASO 1 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO
-- DNI obligatorio

    EXEC personal.guardaparque_alta @nombre = 'Pedro Picapiedra', @dni = NULL, @vigencia_desde = '2026-06-18', @vigencia_hasta = '2030-12-31';
END TRY
BEGIN CATCH
    PRINT 'CASO 2 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO
-- Fecha de comienzo obligatoria

EXEC personal.guardaparque_alta @nombre = 'Pedro Picapiedra', @dni = '45111222', @vigencia_desde = NULL, @vigencia_hasta = '2030-12-31';

-- Baja
-- Guardaparque inexistente
BEGIN TRY
    PRINT 'CASO 1 FALLO: no existe guardaparque';
    EXEC personal.guardaparque_baja @id_guardaparque = 99999;
END TRY
BEGIN CATCH
    PRINT 'CASO 1 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO
-- Ejecución Exitosa
BEGIN TRY
    PRINT 'CASO 2 EXITO: baja lógica realizada';
    EXEC personal.guardaparque_baja @id_guardaparque = 2;
END TRY
BEGIN CATCH
    PRINT 'CASO 2 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO
-- Modificación
-- Guardaparque inexistente
BEGIN TRY
    PRINT 'CASO 1 FALLO: no existe el guardaparque';
    EXEC personal.guardaparque_modificacion @id_guardaparque = 99999,@nombre = 'Carlos Gómez', @dni = '32456789', @vigencia_desde = '2020-01-15', @vigencia_hasta = '2028-12-31';
END TRY
BEGIN CATCH
    PRINT 'CASO 1 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO
-- Nombre obligatorio
BEGIN TRY
    PRINT 'CASO 2 FALLO: no ingresó nombre';
    EXEC personal.guardaparque_modificacion @id_guardaparque = 1, @nombre = NULL, @dni = '32456789', @vigencia_desde = '2020-01-15', @vigencia_hasta = '2028-12-31';
END TRY
BEGIN CATCH
    PRINT 'CASO 2 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO
-- DNI obligatorio
BEGIN TRY
    PRINT 'CASO 3 FALLO: no ingresó DNI.';
    EXEC personal.guardaparque_modificacion @id_guardaparque = 1, @nombre = 'Carlos Gómez', @dni = NULL, @vigencia_desde = '2020-01-15', @vigencia_hasta = '2028-12-31';
END TRY
BEGIN CATCH
    PRINT 'CASO 3 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO
-- Fecha de comienzo obligatoria
BEGIN TRY
    PRINT 'CASO 4 FALLO: no ingresó fecha inicial';
    EXEC personal.guardaparque_modificacion @id_guardaparque = 1, @nombre = 'Carlos Gómez', @dni = '32456789', @vigencia_desde = NULL, @vigencia_hasta = '2028-12-31';
END TRY
BEGIN CATCH
    PRINT 'CASO 4 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO
-- Guía
-- Alta
-- Guía existente
BEGIN TRY
    PRINT 'CASO 1 FALLO: ya existe el guía';
    EXEC personal.guiaAutorizado_alta @nombre = 'Carlos Gómez', @dni = '32456789', @especialidad = 'Trekking', @titulo = 'Guía Profesional', @vigencia_desde = '2026-06-18', @vigencia_hasta = '2029-12-31';
END TRY
BEGIN CATCH
    PRINT 'CASO 1 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO
-- Nombre obligatorio
BEGIN TRY
    PRINT 'CASO 2 FALLO: no ingresó nombre';
    EXEC personal.guiaAutorizado_alta @nombre = NULL, @dni = '49111222', @especialidad = 'Fotografía', @titulo = 'Guía Local', @vigencia_desde = '2026-06-18', @vigencia_hasta = '2029-12-31';
END TRY
BEGIN CATCH
    PRINT 'CASO 2 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO
-- DNI obligatorio
BEGIN TRY
    PRINT 'CASO 3 FALLO: no ingresó DNI';
    EXEC personal.guiaAutorizado_alta @nombre = 'Esteban Quito', @dni = NULL, @especialidad = 'Fotografía', @titulo = 'Guía Local', @vigencia_desde = '2026-06-18', @vigencia_hasta = '2029-12-31';
END TRY
BEGIN CATCH
    PRINT 'CASO 3 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO
-- Fecha de comienzo obligatoria
BEGIN TRY
    PRINT 'CASO 4 FALLO: no ingresó fecha inicial';
    EXEC personal.guiaAutorizado_alta @nombre = 'Esteban Quito', @dni = '49111222', @especialidad = 'Fotografía', @titulo = 'Guía Local', @vigencia_desde = NULL, @vigencia_hasta = '2029-12-31';
END TRY
BEGIN CATCH
    PRINT 'CASO 4 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO
-- Baja
-- Guía inexistente
BEGIN TRY
    PRINT 'CASO 1 FALLO: no existe guía';
    EXEC personal.guia_baja @id_guia = 99999;
END TRY
BEGIN CATCH
    PRINT 'CASO 1 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO
-- Ejecución Exitosa 
BEGIN TRY
    PRINT 'CASO 2 ÉXITO: baja lógica realizada.';
    EXEC personal.guia_baja @id_guia = 2;
END TRY
BEGIN CATCH
    PRINT 'CASO 2 FALLO : ' + ERROR_MESSAGE();
END CATCH
GO
-- Modificación
-- Guía inexistente
BEGIN TRY
    PRINT 'CASO 1 FALLO: no existe guía';
    EXEC personal.guia_modificacion @id_guia = 99999, @nombre = 'Laura Benítez', @dni = '38444555', @especialidad = 'Trekking y Alta Montaña', @titulo = 'Guía Profesional de Turismo', @vigencia_desde = '2024-01-01', @vigencia_hasta = '2027-01-01';
END TRY
BEGIN CATCH
    PRINT 'CASO 1 FALLO : ' + ERROR_MESSAGE();
END CATCH
GO
-- Nombre obligatorio
BEGIN TRY
    PRINT 'CASO 2 FALLO: no ingresó nombre';
    EXEC personal.guia_modificacion @id_guia = 1, @nombre = NULL, @dni = '38444555', @especialidad = 'Trekking y Alta Montaña', @titulo = 'Guía Profesional de Turismo', @vigencia_desde = '2024-01-01', @vigencia_hasta = '2027-01-01';
END TRY
BEGIN CATCH
    PRINT 'CASO 2 FALLO : ' + ERROR_MESSAGE();
END CATCH
GO
-- DNI obligatorio
BEGIN TRY
    PRINT 'CASO 3 FALLO: no ingresó DNI';
    EXEC personal.guia_modificacion @id_guia = 1, @nombre = 'Laura Benítez', @dni = NULL, @especialidad = 'Trekking y Alta Montaña', @titulo = 'Guía Profesional de Turismo', @vigencia_desde = '2024-01-01', @vigencia_hasta = '2027-01-01';
END TRY
BEGIN CATCH
    PRINT 'CASO 3 FALLO : ' + ERROR_MESSAGE();
END CATCH
GO
-- Fecha de comienzo obligatoria
BEGIN TRY
    PRINT 'CASO 4 FALLO: no ingresó fecha inicial';
    EXEC personal.guia_modificacion @id_guia = 1, @nombre = 'Laura Benítez', @dni = '38444555', @especialidad = 'Trekking y Alta Montaña', @titulo = 'Guía Profesional de Turismo', @vigencia_desde = NULL, @vigencia_hasta = '2027-01-01';
END TRY
BEGIN CATCH
    PRINT 'CASO 4 FALLO : ' + ERROR_MESSAGE();
END CATCH
GO