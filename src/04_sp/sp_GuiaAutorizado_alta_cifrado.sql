--  30/06/2026
--  INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
--  Descripcion: SP de alta de GuiaAutorizado adaptado para columna dni cifrada.
--               Reemplaza a sp_GuiaAutorizado_alta.sql luego de aplicar 01_cifrado.sql.
--               Cambios respecto al original:
--                 - Corrige bug: el chequeo de duplicado consultaba personal.Guardaparque
--                   en lugar de personal.GuiaAutorizado.
--                 - Valida formato de DNI (el CHECK fue eliminado de la tabla).
--                 - Chequea unicidad via dni_hash en lugar de comparar dni directamente.
--                 - Inserta dni cifrado con EncryptByPassPhrase y calcula dni_hash.

USE ParquesNacionales;
GO
CREATE OR ALTER PROCEDURE personal.guiaAutorizado_alta
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
    DECLARE @activo       bit            = 1;
    DECLARE @claveCifrado NVARCHAR(128)  = 'ClaveUltraSegura_123!';

    -- Campos obligatorios

    IF @nombre IS NULL
        SET @v_errores += 'El nombre del guia es obligatorio. ';

    IF @dni IS NULL
        SET @v_errores += 'El DNI del guia es obligatorio. ';
    ELSE IF @dni LIKE '%[^0-9]%' OR LEN(@dni) NOT BETWEEN 7 AND 8
        SET @v_errores += 'El DNI debe ser numerico y tener entre 7 y 8 digitos. ';
    ELSE IF EXISTS (SELECT 1 FROM personal.GuiaAutorizado WHERE dni_hash = HASHBYTES('SHA2_256', @dni))
        SET @v_errores += 'El DNI ya existe. ';

    IF @vigencia_desde IS NULL
        SET @v_errores += 'La fecha de comienzo es obligatoria. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    INSERT INTO personal.GuiaAutorizado(nombre, dni, dni_hash, especialidad, titulo, vigencia_desde, vigencia_hasta, activo)
    VALUES (
        @nombre,
        EncryptByPassPhrase(@claveCifrado, @dni),
        HASHBYTES('SHA2_256', @dni),
        @especialidad,
        @titulo,
        @vigencia_desde,
        @vigencia_hasta,
        @activo
    );
END
GO

-- Pruebas de validaciones

-- Nombre obligatorio
EXEC personal.guiaAutorizado_alta
    @nombre         = NULL,
    @dni            = '49111222',
    @especialidad   = 'Fotografia',
    @titulo         = 'Guia Local',
    @vigencia_desde = '2026-06-30',
    @vigencia_hasta = '2029-12-31';

-- DNI obligatorio
EXEC personal.guiaAutorizado_alta
    @nombre         = 'Esteban Quito',
    @dni            = NULL,
    @especialidad   = 'Fotografia',
    @titulo         = 'Guia Local',
    @vigencia_desde = '2026-06-30',
    @vigencia_hasta = '2029-12-31';

-- DNI con formato invalido (letras)
EXEC personal.guiaAutorizado_alta
    @nombre         = 'Esteban Quito',
    @dni            = 'XY123456',
    @especialidad   = 'Fotografia',
    @titulo         = 'Guia Local',
    @vigencia_desde = '2026-06-30',
    @vigencia_hasta = '2029-12-31';

-- DNI con formato invalido (menos de 7 digitos)
EXEC personal.guiaAutorizado_alta
    @nombre         = 'Esteban Quito',
    @dni            = '123456',
    @especialidad   = 'Fotografia',
    @titulo         = 'Guia Local',
    @vigencia_desde = '2026-06-30',
    @vigencia_hasta = '2029-12-31';

-- Fecha de comienzo obligatoria
EXEC personal.guiaAutorizado_alta
    @nombre         = 'Esteban Quito',
    @dni            = '49111222',
    @especialidad   = 'Fotografia',
    @titulo         = 'Guia Local',
    @vigencia_desde = NULL,
    @vigencia_hasta = '2029-12-31';

-- Ejecucion exitosa
EXEC personal.guiaAutorizado_alta
    @nombre         = 'Esteban Quito',
    @dni            = '49111222',
    @especialidad   = 'Fotografia',
    @titulo         = 'Guia Local',
    @vigencia_desde = '2026-06-30',
    @vigencia_hasta = '2029-12-31';

-- DNI duplicado
EXEC personal.guiaAutorizado_alta
    @nombre         = 'Otro Nombre',
    @dni            = '49111222',
    @especialidad   = 'Trekking',
    @titulo         = 'Guia Profesional',
    @vigencia_desde = '2026-06-30',
    @vigencia_hasta = '2029-12-31';
