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
	IF EXISTS (SELECT 1 from Parques.TipoParque WHERE descripcion = @descripcion and estado =1)
		UPDATE parques.TipoParque SET estado = 0 WHERE descripcion = @descripcion;
    ELSE 
		INSERT INTO parques.TipoParque (descripcion) VALUES (@descripcion);
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

