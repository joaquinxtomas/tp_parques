--  21/06/2026
--  INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
--  Descripcion: Script de modificacion para aplicar cifrado a datos sensibles. Afecta a personal.GuiaAutorizado.dni, personal.Guardaparque.dni
--
--    NOTA: Este script funcionaba con la estructura vieja, pero se cambiaron los campos de las tablas y se cifran desde el inicio, por lo que no es necesario ejecutar este script. Dejo el ejemplo de referencia.
--
--    1. Recibir @claveCifrado NVARCHAR(128) como parametro.
--    2. En altas: cifrar @dni con EncryptByPassPhrase y calcular HASHBYTES para dni_hash.
--    3. En modificaciones de dni: idem punto 2.
--    4. En consultas que devuelvan el DNI: descifrarlo con DecryptByPassPhrase.
--    5. El CHECK de formato de dni se elimino de la tabla; validarlo en el SP antes de cifrar.
--    Deje un ejemplo al final de este script.

USE ParquesNacionales;
GO

-- PASO 1: GuiaAutorizado - eliminar constraints que dependen de dni

IF EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = 'CK_GuiaAutorizado_DNIFormato'
    AND parent_object_id = OBJECT_ID('personal.GuiaAutorizado')
)
    ALTER TABLE personal.GuiaAutorizado DROP CONSTRAINT CK_GuiaAutorizado_DNIFormato;
GO

IF EXISTS (
    SELECT 1 FROM sys.key_constraints
    WHERE name = 'UQ_GuiaAutorizado_DNI'
    AND parent_object_id = OBJECT_ID('personal.GuiaAutorizado')
)
    ALTER TABLE personal.GuiaAutorizado DROP CONSTRAINT UQ_GuiaAutorizado_DNI;
GO

-- PASO 2: GuiaAutorizado - agregar columnas nuevas (nullable para poder poblarlas)

IF COL_LENGTH('personal.GuiaAutorizado', 'dni_cifrado') IS NULL
    ALTER TABLE personal.GuiaAutorizado ADD dni_cifrado VARBINARY(256) NULL;
GO

IF COL_LENGTH('personal.GuiaAutorizado', 'dni_hash') IS NULL
    ALTER TABLE personal.GuiaAutorizado ADD dni_hash VARBINARY(32) NULL;
GO

-- PASO 3: GuiaAutorizado - cifrar datos existentes (Usar la misma frase en todos los SPs que accedan a esta columna).

DECLARE @claveCifrado NVARCHAR(128) = 'ClaveUltraSegura_123!';

UPDATE personal.GuiaAutorizado
SET
    dni_cifrado = EncryptByPassPhrase(@claveCifrado, dni),
    dni_hash    = HASHBYTES('SHA2_256', dni)
WHERE dni_cifrado IS NULL;
GO

-- PASO 4: GuiaAutorizado - aplicar NOT NULL luego de poblar

ALTER TABLE personal.GuiaAutorizado ALTER COLUMN dni_cifrado VARBINARY(256) NOT NULL;
GO

ALTER TABLE personal.GuiaAutorizado ALTER COLUMN dni_hash VARBINARY(32) NOT NULL;
GO

-- PASO 5: GuiaAutorizado - eliminar columna original y renombrar

IF COL_LENGTH('personal.GuiaAutorizado', 'dni') IS NOT NULL
    ALTER TABLE personal.GuiaAutorizado DROP COLUMN dni;
GO

IF COL_LENGTH('personal.GuiaAutorizado', 'dni_cifrado') IS NOT NULL
    EXEC sp_rename 'personal.GuiaAutorizado.dni_cifrado', 'dni', 'COLUMN';
GO

-- PASO 6: GuiaAutorizado - nuevo UNIQUE sobre el hash

IF NOT EXISTS (
    SELECT 1 FROM sys.key_constraints
    WHERE name = 'UQ_GuiaAutorizado_DNI'
    AND parent_object_id = OBJECT_ID('personal.GuiaAutorizado')
)
    ALTER TABLE personal.GuiaAutorizado ADD CONSTRAINT UQ_GuiaAutorizado_DNI UNIQUE (dni_hash);
GO


-- PASO 7: Guardaparque - eliminar constraints que dependen de dni

IF EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = 'CK_Guardaparque_DNIFormato'
    AND parent_object_id = OBJECT_ID('personal.Guardaparque')
)
    ALTER TABLE personal.Guardaparque DROP CONSTRAINT CK_Guardaparque_DNIFormato;
GO

IF EXISTS (
    SELECT 1 FROM sys.key_constraints
    WHERE name = 'UQ_Guardaparque_DNI'
    AND parent_object_id = OBJECT_ID('personal.Guardaparque')
)
    ALTER TABLE personal.Guardaparque DROP CONSTRAINT UQ_Guardaparque_DNI;
GO

-- PASO 8: Guardaparque - agregar columnas nuevas

IF COL_LENGTH('personal.Guardaparque', 'dni_cifrado') IS NULL
    ALTER TABLE personal.Guardaparque ADD dni_cifrado VARBINARY(256) NULL;
GO

IF COL_LENGTH('personal.Guardaparque', 'dni_hash') IS NULL
    ALTER TABLE personal.Guardaparque ADD dni_hash VARBINARY(32) NULL;
GO

-- PASO 9: Guardaparque - cifrar datos existentes

DECLARE @claveCifrado NVARCHAR(128) = 'ClaveUltraSegura_123!';

UPDATE personal.Guardaparque
SET
    dni_cifrado = EncryptByPassPhrase(@claveCifrado, dni),
    dni_hash    = HASHBYTES('SHA2_256', dni)
WHERE dni_cifrado IS NULL;
GO

-- PASO 10: Guardaparque - aplicar NOT NULL, eliminar original, renombrar

ALTER TABLE personal.Guardaparque ALTER COLUMN dni_cifrado VARBINARY(256) NOT NULL;
GO

ALTER TABLE personal.Guardaparque ALTER COLUMN dni_hash VARBINARY(32) NOT NULL;
GO

IF COL_LENGTH('personal.Guardaparque', 'dni') IS NOT NULL
    ALTER TABLE personal.Guardaparque DROP COLUMN dni;
GO

IF COL_LENGTH('personal.Guardaparque', 'dni_cifrado') IS NOT NULL
    EXEC sp_rename 'personal.Guardaparque.dni_cifrado', 'dni', 'COLUMN';
GO

-- PASO 11: Guardaparque - nuevo UNIQUE sobre el hash

IF NOT EXISTS (
    SELECT 1 FROM sys.key_constraints
    WHERE name = 'UQ_Guardaparque_DNI'
    AND parent_object_id = OBJECT_ID('personal.Guardaparque')
)
    ALTER TABLE personal.Guardaparque ADD CONSTRAINT UQ_Guardaparque_DNI UNIQUE (dni_hash);
GO


-- REFERENCIA: Patrones de uso del cifrado en SPs
--
-- ALTA (GuiaAutorizado_Nuevo / Guardaparque_Nuevo):
--
--   DECLARE @claveCifrado NVARCHAR(128) = @claveCifrado_param;
--
--   -- Validar formato antes de cifrar (el CHECK fue eliminado de la tabla)
--   IF @dni LIKE '%[^0-9]%' OR LEN(@dni) NOT BETWEEN 7 AND 8
--       SET @v_errores = @v_errores + 'El DNI debe ser numerico y tener entre 7 y 8 digitos. ';
--
--   -- Verificar unicidad via hash
--   IF EXISTS (SELECT 1 FROM personal.GuiaAutorizado WHERE dni_hash = HASHBYTES('SHA2_256', @dni))
--       SET @v_errores = @v_errores + 'El DNI ya existe. ';
--
--   -- Insertar con dni cifrado y hash
--   INSERT INTO personal.GuiaAutorizado (nombre, dni, dni_hash, ...)
--   VALUES (@nombre, EncryptByPassPhrase(@claveCifrado, @dni), HASHBYTES('SHA2_256', @dni), ...);
--
-- CONSULTA con dni descifrado:
--
--   DECLARE @claveCifrado NVARCHAR(128) = @claveCifrado_param;
--   SELECT
--       id_guia,
--       nombre,
--       CONVERT(VARCHAR(10), DecryptByPassPhrase(@claveCifrado, dni)) AS dni
--   FROM personal.GuiaAutorizado;
