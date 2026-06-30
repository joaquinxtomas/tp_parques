--	16/06/2026
-- INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
-- Descripcion: Creacion de los STORED PROCEDURES de las operaciones ABM en tipos de parques y parques

USE ParquesNacionales;
GO

--	ABM PARQUES

CREATE OR ALTER PROCEDURE parques.InsertarParque --	ALTA
    @nombre         VARCHAR(100),
    @id_tipo_parque INT,
    @region         VARCHAR(100) = NULL, --son opcionales, por defecto valen NULL
    @provincia      VARCHAR(100) = NULL,
	@latitud        DECIMAL(9,6) = NULL,
    @longitud       DECIMAL(9,6) = NULL,
    @superficie     DECIMAL(12,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = ''; --declaro cadena donde junto todos los errores

    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        SET @v_errores += 'El nombre es obligatorio. ';

    IF EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = @nombre AND estado = 0)
        SET @v_errores += 'Ya existe un parque activo con ese nombre. ';

    IF NOT EXISTS (SELECT 1 FROM parques.TipoParque WHERE id_tipo_parque = @id_tipo_parque AND estado = 0)
        SET @v_errores += 'El tipo de parque no existe o esta dado de baja. ';

    IF @superficie IS NOT NULL AND @superficie <= 0
        SET @v_errores += 'La superficie debe ser mayor a cero. ';

    IF (@latitud IS NULL AND @longitud IS NOT NULL)
       OR (@latitud IS NOT NULL AND @longitud IS NULL)
        SET @v_errores += 'Debe indicar latitud y longitud juntas, o ninguna. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1); -- muestro la cadena de errores y corto
        RETURN;
    END

    INSERT INTO parques.Parque (nombre, id_tipo_parque, provincia, region, latitud, longitud, superficie)
    VALUES (@nombre, @id_tipo_parque, @provincia, @region, @latitud, @longitud, @superficie);
END
GO

CREATE OR ALTER PROCEDURE parques.ModificarParque --	MODIFICACION
    @id_parque      INT,
    @nombre         VARCHAR(100),
    @id_tipo_parque INT,
	@provincia         VARCHAR(100) = NULL,
    @region         VARCHAR(100) = NULL,
    @latitud        DECIMAL(9,6) = NULL,
    @longitud       DECIMAL(9,6) = NULL,
    @superficie     DECIMAL(12,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @id_parque AND estado = 0)
        SET @v_errores += 'El parque no existe o esta dado de baja. ';

    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        SET @v_errores += 'El nombre es obligatorio. ';

    IF EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = @nombre AND id_parque <> @id_parque)
        SET @v_errores += 'Otro parque ya usa ese nombre. ';

    IF NOT EXISTS (SELECT 1 FROM parques.TipoParque WHERE id_tipo_parque = @id_tipo_parque AND estado = 0)
        SET @v_errores += 'El tipo de parque no existe o esta dado de baja. ';

    IF @superficie IS NOT NULL AND @superficie <= 0
        SET @v_errores += 'La superficie debe ser mayor a cero. ';

    IF (@latitud IS NULL AND @longitud IS NOT NULL)
       OR (@latitud IS NOT NULL AND @longitud IS NULL)
        SET @v_errores += 'Debe indicar latitud y longitud juntas, o ninguna. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    UPDATE parques.Parque
    SET nombre = @nombre,
        id_tipo_parque = @id_tipo_parque,
        provincia = @provincia,
        region = @region,
        latitud = @latitud,
        longitud = @longitud,
        superficie = @superficie
    WHERE id_parque = @id_parque;
END
GO

CREATE OR ALTER PROCEDURE parques.EliminarParque	-- BAJA (logica)
    @id_parque INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @id_parque)
        SET @v_errores += 'El parque no existe. ';

    IF EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @id_parque AND estado = 1)
        SET @v_errores += 'El parque ya esta dado de baja. ';

    IF EXISTS (SELECT 1 FROM actividades.Atraccion WHERE id_parque = @id_parque AND estado = 0)
        SET @v_errores += 'No se puede eliminar: el parque tiene atracciones activas. ';

    IF EXISTS (SELECT 1 FROM ventas.Entrada WHERE id_parque = @id_parque AND estado = 0)
        SET @v_errores += 'No se puede eliminar: el parque tiene ventas activas. ';

    IF EXISTS (SELECT 1 FROM concesiones.Concesion WHERE id_parque = @id_parque AND estado = 0)
        SET @v_errores += 'No se puede eliminar: el parque tiene concesiones activas. ';

    IF EXISTS (SELECT 1 FROM personal.AsignacionGP WHERE id_parque = @id_parque AND estado = 0)
        SET @v_errores += 'No se puede eliminar: el parque tiene asignaciones de personal activas. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    UPDATE parques.Parque SET estado = 1 WHERE id_parque = @id_parque;
END
GO
