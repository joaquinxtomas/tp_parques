--  30/06/2026
--  INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
--  Descripcion: SP de modificacion de Guardaparque adaptado para columna dni cifrada.
--               Reemplaza a sp_Guardaparque_modificacion.sql luego de aplicar 01_cifrado.sql.
--               Cambios respecto al original:
--                 - Valida formato de DNI (el CHECK fue eliminado de la tabla).
--                 - Chequea unicidad via dni_hash excluyendo el registro actual.
--                 - Actualiza dni cifrado con EncryptByPassPhrase y recalcula dni_hash.

USE ParquesNacionales;
GO
CREATE OR ALTER PROCEDURE personal.guardaparque_modificacion
    @id_guardaparque int,
    @nombre          varchar(100),
    @dni             varchar(10),
    @vigencia_desde  date,
    @vigencia_hasta  date
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores    VARCHAR(MAX)   = '';
    DECLARE @claveCifrado NVARCHAR(128)  = 'ClaveUltraSegura_123!';

    IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE id_guardaparque = @id_guardaparque)
        SET @v_errores += 'No se encontro el guardaparque. ';

    IF @nombre IS NULL
        SET @v_errores += 'El nombre del guardaparque es obligatorio. ';

    IF @dni IS NULL
        SET @v_errores += 'El DNI del guardaparque es obligatorio. ';
    ELSE IF @dni LIKE '%[^0-9]%' OR LEN(@dni) NOT BETWEEN 7 AND 8
        SET @v_errores += 'El DNI debe ser numerico y tener entre 7 y 8 digitos. ';
    ELSE IF EXISTS (
        SELECT 1 FROM personal.Guardaparque
        WHERE dni_hash = HASHBYTES('SHA2_256', @dni)
          AND id_guardaparque <> @id_guardaparque
    )
        SET @v_errores += 'El DNI ya existe en otro guardaparque. ';

    IF @vigencia_desde IS NULL
        SET @v_errores += 'La fecha de vigencia inicial es obligatoria. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    UPDATE personal.Guardaparque
    SET nombre          = @nombre,
        dni             = EncryptByPassPhrase(@claveCifrado, @dni),
        dni_hash        = HASHBYTES('SHA2_256', @dni),
        vigencia_desde  = @vigencia_desde,
        vigencia_hasta  = @vigencia_hasta
    WHERE id_guardaparque = @id_guardaparque;
END
GO

-- Pruebas de validaciones

-- Guardaparque inexistente
EXEC personal.guardaparque_modificacion
    @id_guardaparque = 99999,
    @nombre          = 'Carlos Gomez',
    @dni             = '32456789',
    @vigencia_desde  = '2020-01-15',
    @vigencia_hasta  = '2028-12-31';

-- Nombre obligatorio
EXEC personal.guardaparque_modificacion
    @id_guardaparque = 1,
    @nombre          = NULL,
    @dni             = '32456789',
    @vigencia_desde  = '2020-01-15',
    @vigencia_hasta  = '2028-12-31';

-- DNI obligatorio
EXEC personal.guardaparque_modificacion
    @id_guardaparque = 1,
    @nombre          = 'Carlos Gomez',
    @dni             = NULL,
    @vigencia_desde  = '2020-01-15',
    @vigencia_hasta  = '2028-12-31';

-- DNI con formato invalido
EXEC personal.guardaparque_modificacion
    @id_guardaparque = 1,
    @nombre          = 'Carlos Gomez',
    @dni             = 'AB123456',
    @vigencia_desde  = '2020-01-15',
    @vigencia_hasta  = '2028-12-31';

-- Fecha de comienzo obligatoria
EXEC personal.guardaparque_modificacion
    @id_guardaparque = 1,
    @nombre          = 'Carlos Gomez',
    @dni             = '32456789',
    @vigencia_desde  = NULL,
    @vigencia_hasta  = '2028-12-31';

-- Ejecucion exitosa
EXEC personal.guardaparque_modificacion
    @id_guardaparque = 1,
    @nombre          = 'Carlos Gomez',
    @dni             = '32456789',
    @vigencia_desde  = '2020-01-15',
    @vigencia_hasta  = '2028-12-31';
