USE ParquesNacionales;
GO

CREATE OR ALTER PROCEDURE parques.usp_InsertarTipoDeParque
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


CREATE OR ALTER PROCEDURE parques.usp_InsertarParque
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


--PRUEBAS
--creo un tipo de parque para crear la prueba de parque
IF NOT EXISTS (SELECT 1 FROM parques.TipoParque WHERE descripcion = 'Parque Nacional')
    INSERT INTO parques.TipoParque (descripcion) VALUES ('Parque Nacional');



EXEC parques.usp_InsertarParque --prueba todo bien -- CORRIENDO 2 VECES DA ERROR POR DUPLICADO
    @nombre = 'Los Glaciares',
    @id_tipo_parque = 1,
    @ubicacion = 'Santa Cruz',
    @latitud = -50.476100,
    @longitud = -73.037700,
    @superficie = 726927.00;
GO 

EXEC parques.usp_InsertarParque
    @nombre = '',              -- vacío → falla validación 1
    @id_tipo_parque = 999;     -- no existe → falla validación 3
GO

