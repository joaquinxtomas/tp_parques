--	16/06/2026
-- INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
-- Descripcion: Creacion de los STORED PROCEDURES de las operaciones ABM en tipos de parques y parques

USE ParquesNacionales;
GO

--				ABM TIPOS DE PARQUE

CREATE OR ALTER PROCEDURE parques.InsertarTipoDeParque	--	ALTA
    @descripcion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = ''
        SET @v_errores += 'La descripcion es obligatoria. ';

    IF EXISTS (SELECT 1 FROM parques.TipoParque WHERE descripcion = @descripcion AND estado = 0)
        SET @v_errores += 'Ya existe un tipo de parque activo con esa descripcion. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    INSERT INTO parques.TipoParque (descripcion)
    VALUES (@descripcion);
END
GO

CREATE OR ALTER PROCEDURE parques.ModificarTipoDeParque	--	MODIFICACION
    @id_tipo_parque INT,
    @descripcion    VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM parques.TipoParque WHERE id_tipo_parque = @id_tipo_parque AND estado = 0)
        SET @v_errores += 'El tipo de parque no existe o esta dado de baja. ';

    IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = ''
        SET @v_errores += 'La descripcion es obligatoria. ';

    IF EXISTS (SELECT 1 FROM parques.TipoParque
               WHERE descripcion = @descripcion AND id_tipo_parque <> @id_tipo_parque AND estado = 0)
        SET @v_errores += 'Otro tipo de parque ya usa esa descripcion. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    UPDATE parques.TipoParque
    SET descripcion = @descripcion
    WHERE id_tipo_parque = @id_tipo_parque;
END
GO

CREATE OR ALTER PROCEDURE parques.EliminarTipoDeParque	--	BAJA (logica)
    @id_tipo_parque INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM parques.TipoParque WHERE id_tipo_parque = @id_tipo_parque)
        SET @v_errores += 'El tipo de parque no existe. ';

    IF EXISTS (SELECT 1 FROM parques.TipoParque WHERE id_tipo_parque = @id_tipo_parque AND estado = 1)
        SET @v_errores += 'El tipo de parque ya esta dado de baja. ';

    IF EXISTS (SELECT 1 FROM parques.Parque WHERE id_tipo_parque = @id_tipo_parque AND estado = 0)
        SET @v_errores += 'No se puede eliminar: hay parques activos que usan este tipo. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    UPDATE parques.TipoParque SET estado = 1 WHERE id_tipo_parque = @id_tipo_parque;
END
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
SELECT * FROM parques.TipoParque WHERE descripcion = 'Parque Nacional';
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
    EXEC parques.ModificarTipoDeParque @id_tipo_parque = 1, @descripcion = 'Parque Nacional Federal';
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