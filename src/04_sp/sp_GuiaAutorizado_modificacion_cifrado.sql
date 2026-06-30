--  30/06/2026
--  INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
--  Descripcion: SP de modificacion de GuiaAutorizado adaptado para columna dni cifrada.
--               Reemplaza a sp_GuiaAutorizado_modificacion.sql luego de aplicar 01_cifrado.sql.
--               Cambios respecto al original:
--                 - Valida formato de DNI (el CHECK fue eliminado de la tabla).
--                 - Chequea unicidad via dni_hash excluyendo el registro actual.
--                 - Actualiza dni cifrado con EncryptByPassPhrase y recalcula dni_hash.

USE ParquesNacionales;
GO
CREATE OR ALTER PROCEDURE personal.guia_modificacion
    @id_guia        int,
    @nombre         varchar(100),
    @dni            varchar(10),
    @especialidad   varchar(100),
    @titulo         varchar(100),
    @vigencia_desde date,
    @vigencia_hasta date
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores    VARCHAR(MAX)   = '';
    DECLARE @claveCifrado NVARCHAR(128)  = 'ClaveUltraSegura_123!';

    IF NOT EXISTS (SELECT 1 FROM personal.GuiaAutorizado WHERE id_guia = @id_guia)
        SET @v_errores += 'No se encontro el guia. ';

    IF @nombre IS NULL
        SET @v_errores += 'El nombre del guia es obligatorio. ';

    IF @dni IS NULL
        SET @v_errores += 'El DNI del guia es obligatorio. ';
    ELSE IF @dni LIKE '%[^0-9]%' OR LEN(@dni) NOT BETWEEN 7 AND 8
        SET @v_errores += 'El DNI debe ser numerico y tener entre 7 y 8 digitos. ';
    ELSE IF EXISTS (
        SELECT 1 FROM personal.GuiaAutorizado
        WHERE dni_hash = HASHBYTES('SHA2_256', @dni)
          AND id_guia <> @id_guia
    )
        SET @v_errores += 'El DNI ya existe en otro guia. ';

    IF @vigencia_desde IS NULL
        SET @v_errores += 'La fecha de vigencia inicial es obligatoria. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    UPDATE personal.GuiaAutorizado
    SET nombre          = @nombre,
        dni             = EncryptByPassPhrase(@claveCifrado, @dni),
        dni_hash        = HASHBYTES('SHA2_256', @dni),
        especialidad    = @especialidad,
        titulo          = @titulo,
        vigencia_desde  = @vigencia_desde,
        vigencia_hasta  = @vigencia_hasta
    WHERE id_guia = @id_guia;
END
GO

-- Pruebas de validaciones

-- Guia inexistente
EXEC personal.guia_modificacion
    @id_guia        = 99999,
    @nombre         = 'Laura Benitez',
    @dni            = '38444555',
    @especialidad   = 'Trekking y Alta Montana',
    @titulo         = 'Guia Profesional de Turismo',
    @vigencia_desde = '2024-01-01',
    @vigencia_hasta = '2027-01-01';

-- Nombre obligatorio
EXEC personal.guia_modificacion
    @id_guia        = 1,
    @nombre         = NULL,
    @dni            = '38444555',
    @especialidad   = 'Trekking y Alta Montana',
    @titulo         = 'Guia Profesional de Turismo',
    @vigencia_desde = '2024-01-01',
    @vigencia_hasta = '2027-01-01';

-- DNI obligatorio
EXEC personal.guia_modificacion
    @id_guia        = 1,
    @nombre         = 'Laura Benitez',
    @dni            = NULL,
    @especialidad   = 'Trekking y Alta Montana',
    @titulo         = 'Guia Profesional de Turismo',
    @vigencia_desde = '2024-01-01',
    @vigencia_hasta = '2027-01-01';

-- DNI con formato invalido
EXEC personal.guia_modificacion
    @id_guia        = 1,
    @nombre         = 'Laura Benitez',
    @dni            = 'AB123456',
    @especialidad   = 'Trekking y Alta Montana',
    @titulo         = 'Guia Profesional de Turismo',
    @vigencia_desde = '2024-01-01',
    @vigencia_hasta = '2027-01-01';

-- Fecha de comienzo obligatoria
EXEC personal.guia_modificacion
    @id_guia        = 1,
    @nombre         = 'Laura Benitez',
    @dni            = '38444555',
    @especialidad   = 'Trekking y Alta Montana',
    @titulo         = 'Guia Profesional de Turismo',
    @vigencia_desde = NULL,
    @vigencia_hasta = '2027-01-01';

-- Ejecucion exitosa
EXEC personal.guia_modificacion
    @id_guia        = 1,
    @nombre         = 'Laura Benitez',
    @dni            = '38444555',
    @especialidad   = 'Trekking y Alta Montana',
    @titulo         = 'Guia Profesional de Turismo',
    @vigencia_desde = '2024-01-01',
    @vigencia_hasta = '2027-01-01';
