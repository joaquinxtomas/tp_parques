--	16/06/2026
-- INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
-- Descripcion: Creacion de los STORED PROCEDURES de las operaciones ABM en tipos de parques y parques


USE ParquesNacionales;
GO

--				ABM TIPOS DE PARQUE
CREATE OR ALTER PROCEDURE parques.usp_InsertarTipoDeParque	--	ALTA
    @descripcion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = ''
        SET @v_errores += 'La descripcion es obligatoria. ';

    IF EXISTS (SELECT 1 FROM parques.TipoParque WHERE descripcion = @descripcion)
        SET @v_errores += 'Ya existe un tipo de parque con esa descripcion. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    INSERT INTO parques.TipoParque (descripcion)
    VALUES (@descripcion);
END
GO

CREATE OR ALTER PROCEDURE parques.usp_UpdateTipoDeParque	--	MODIFICACION
    @id_tipo_parque INT,
    @descripcion    VARCHAR(50)
AS
BEGIN
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM parques.TipoParque WHERE id_tipo_parque = @id_tipo_parque)
        SET @v_errores += 'El tipo de parque no existe. ';

    IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = ''
        SET @v_errores += 'La descripcion es obligatoria. ';

    IF EXISTS (SELECT 1 FROM parques.TipoParque
               WHERE descripcion = @descripcion AND id_tipo_parque <> @id_tipo_parque)
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

CREATE OR ALTER PROCEDURE parques.usp_EliminarParque	--	BAJA
    @id_parque INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @id_parque)
        SET @v_errores += 'El parque no existe. ';

    IF EXISTS (SELECT 1 FROM actividades.Atraccion WHERE id_parque = @id_parque)
        SET @v_errores += 'No se puede eliminar: el parque tiene atracciones. ';

    IF EXISTS (SELECT 1 FROM ventas.Ticket WHERE id_parque = @id_parque)
        SET @v_errores += 'No se puede eliminar: el parque tiene ventas registradas. ';

    IF EXISTS (SELECT 1 FROM concesiones.Concesion WHERE id_parque = @id_parque)
        SET @v_errores += 'No se puede eliminar: el parque tiene concesiones. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END
    DELETE FROM parques.Parque WHERE id_parque = @id_parque;
END
GO

--	ABM PARQUES

CREATE OR ALTER PROCEDURE parques.usp_InsertarParque --	ALTA
    @nombre         VARCHAR(100),
    @id_tipo_parque INT,
    @ubicacion      VARCHAR(100) = NULL, --son opcionales, por defecto valen NULL
    @latitud        DECIMAL(9,6) = NULL,
    @longitud       DECIMAL(9,6) = NULL,
    @superficie     DECIMAL(12,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = ''; --declaro cadena donde junto todos los errores

    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        SET @v_errores += 'El nombre es obligatorio. ';

    IF EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = @nombre)
        SET @v_errores += 'Ya existe un parque con ese nombre. ';

    IF NOT EXISTS (SELECT 1 FROM parques.TipoParque WHERE id_tipo_parque = @id_tipo_parque)
        SET @v_errores += 'El tipo de parque no existe. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1); -- muestro la cadena de errores y corto
        RETURN;
    END

    INSERT INTO parques.Parque (nombre, id_tipo_parque, ubicacion, latitud, longitud, superficie) --si no corto llegue a el insert
    VALUES (@nombre, @id_tipo_parque, @ubicacion, @latitud, @longitud, @superficie);
END
GO

CREATE OR ALTER PROCEDURE parques.usp_ModificarParque --	MODIFICACION
    @id_parque      INT,
    @nombre         VARCHAR(100),
    @id_tipo_parque INT,
    @ubicacion      VARCHAR(100) = NULL,
    @latitud        DECIMAL(9,6) = NULL,
    @longitud       DECIMAL(9,6) = NULL,
    @superficie     DECIMAL(12,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @id_parque)
        SET @v_errores += 'El parque no existe. ';

    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        SET @v_errores += 'El nombre es obligatorio. ';

    IF EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = @nombre AND id_parque <> @id_parque)
        SET @v_errores += 'Otro parque ya usa ese nombre. ';

    IF NOT EXISTS (SELECT 1 FROM parques.TipoParque WHERE id_tipo_parque = @id_tipo_parque)
        SET @v_errores += 'El tipo de parque no existe. ';

    IF @superficie IS NOT NULL AND @superficie <= 0
        SET @v_errores += 'La superficie debe ser mayor a cero. ';

    IF (@latitud IS NULL) <> (@longitud IS NULL)
        SET @v_errores += 'Debe indicar latitud y longitud juntas, o ninguna. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    UPDATE parques.Parque
    SET nombre = @nombre,
        id_tipo_parque = @id_tipo_parque,
        ubicacion = @ubicacion,
        latitud = @latitud,
        longitud = @longitud,
        superficie = @superficie
    WHERE id_parque = @id_parque;
END
GO

CREATE OR ALTER PROCEDURE parques.usp_EliminarParque	-- BAJA
    @id_parque INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @id_parque)
        SET @v_errores += 'El parque no existe. ';

    IF EXISTS (SELECT 1 FROM actividades.Atraccion WHERE id_parque = @id_parque)
        SET @v_errores += 'No se puede eliminar: el parque tiene atracciones. ';

    IF EXISTS (SELECT 1 FROM ventas.Ticket WHERE id_parque = @id_parque)
        SET @v_errores += 'No se puede eliminar: el parque tiene ventas registradas. ';

    IF EXISTS (SELECT 1 FROM concesiones.Concesion WHERE id_parque = @id_parque)
        SET @v_errores += 'No se puede eliminar: el parque tiene concesiones. ';

    IF EXISTS (SELECT 1 FROM personal.AsignacionGP WHERE id_parque = @id_parque)
        SET @v_errores += 'No se puede eliminar: el parque tiene asignaciones de personal. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    DELETE FROM parques.Parque WHERE id_parque = @id_parque;
END
GO