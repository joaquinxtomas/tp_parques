--	16/06/2026
-- INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
-- Descripcion: Testing de ABM de los tipos de parques

USE ParquesNacionales;
GO

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