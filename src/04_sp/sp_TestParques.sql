--	16/06/2026
-- INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
-- Descripcion: Testing de ABM de los parques

USE ParquesNacionales;
GO

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