USE ParquesNacionales;
GO

--ABM SCHEMA ACTIVIDADES
/* ATRACCION */

/* ALTA */
CREATE OR ALTER PROCEDURE actividades.usp_InsertarAtraccion  
	@id_parque INT,
	@nombre VARCHAR(100),
	@costo DECIMAL(10,2),
	@duracion INT,
	@cupo_maximo INT,
	@tipo VARCHAR(20)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @v_errores VARCHAR(MAX) = '';
	
	--normalizo de entrada
	SET @nombre = TRIM(@nombre); 
	SET @tipo = TRIM(@tipo);

	IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @id_parque)
		SET @v_errores += 'El parque indicado no existe. ';

	IF @nombre IS NULL OR @nombre = ''
		SET @v_errores += 'El nombre es obligatorio. ';
	ELSE IF EXISTS(
		SELECT 1 FROM actividades.Atraccion
		WHERE nombre = @nombre AND id_parque = @id_parque
	)
		SET @v_errores += 'Ya existe una atracción con ese nombre. ';

	IF @costo IS NULL
		SET @v_errores += 'El costo es obligatorio (colocar 0 si es gratuita). ';
	ELSE IF @costo < 0
		SET @v_errores += 'El costo debe ser positivo (mayor a 0). ';

	IF @duracion IS NOT NULL AND @duracion <= 0
		SET @v_errores += 'La duración debe ser positiva (mayor a 0). ';

	IF @cupo_maximo IS NOT NULL AND @cupo_maximo <= 0
		SET @v_errores += 'El cupo maximo debe ser positivo (mayor a 0). ';

	IF @tipo IS NULL OR @tipo = ''
		SET @v_errores += 'El tipo es obligatorio. ';

	IF @v_errores <> ''
	BEGIN 
		THROW 50000, @v_errores, 1;
	END

	BEGIN TRY
		BEGIN TRANSACTION;
		INSERT INTO actividades.Atraccion (id_parque, nombre, costo, duracion, cupo_maximo, tipo)
		VALUES (@id_parque, @nombre, @costo, @duracion, @cupo_maximo, @tipo);
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO

/*MODIFICACION*/
CREATE OR ALTER PROCEDURE actividades.usp_ActualizarAtraccion
    @id_atraccion INT,
    @nombre VARCHAR(100),
    @costo DECIMAL(10,2),
    @duracion INT,
    @cupo_maximo INT,
    @tipo VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    DECLARE @id_parque_atraccion INT;

    SELECT @id_parque_atraccion = id_parque --recupero id_parque de la tabla
    FROM actividades.Atraccion
    WHERE id_atraccion = @id_atraccion;

    SET @nombre = TRIM(@nombre)
    SET @tipo = TRIM(@tipo)

    IF @id_parque_atraccion IS NULL --si no la encontro en el select anterior, queda en NULL
        SET @v_errores += 'La atraccion no existe. ';

    IF @nombre IS NULL OR @nombre = ''
        SET @v_errores += 'El nombre es obligatorio ';

    ELSE IF EXISTS (SELECT 1 FROM actividades.Atraccion WHERE nombre = @nombre 
                    AND id_parque = @id_parque_atraccion AND id_atraccion <> @id_atraccion)
        SET @v_errores += 'La atraccion ya existe en el mismo parque. ';

    IF @costo IS NULL 
        SET @v_errores += 'El costo es obligatorio. ';
    ELSE IF @costo < 0
        SET @v_errores += 'El costo debe ser positivo (mayor a 0). ';

    IF @duracion IS NOT NULL AND @duracion <= 0 
        SET @v_errores += 'La duracion debe ser positiva (mayor a 0). ';

    IF @cupo_maximo IS NOT NULL AND @cupo_maximo <= 0
        SET @v_errores += 'El cupo maximo debe ser positivo (mayor a 0). ';

    IF @tipo IS NULL OR @tipo = ''
        SET @v_errores += 'El tipo es obligatorio. ';

    IF @v_errores <> ''
    BEGIN 
        THROW 50000, @v_errores, 1;
    END

    BEGIN TRY 
        BEGIN TRANSACTION;
        UPDATE actividades.Atraccion
        SET
            nombre = @nombre,
            costo = @costo,
            duracion = @duracion,
            cupo_maximo = @cupo_maximo,
            tipo = @tipo
        WHERE id_atraccion = @id_atraccion;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

/* BAJA */
CREATE OR ALTER PROCEDURE actividades.usp_EliminarAtraccion
    @id_atraccion INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';
    DECLARE @v_estado BIT;

    SELECT @v_estado = estado
    FROM actividades.Atraccion
    WHERE id_atraccion = @id_atraccion;

    IF @v_estado IS NULL
        SET @v_errores += 'La atraccion indicada no existe. ';
    ELSE IF @v_estado = 1
        SET @v_errores += 'La atraccion ya está dada de baja. ';

    --duda, dar de baja tanto atraccion como tour o bloquear la baja de la atraccion porque hay tours asociados
    IF EXISTS (SELECT 1 FROM personal.TourGuia WHERE id_atraccion = @id_atraccion)
        SET @v_errores += 'No es posible eliminar. Existen tours asociados a esta atraccion. ';

    IF @v_errores <> ''
    BEGIN
        THROW 50000, @v_errores, 1;
    END

    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE actividades.Atraccion
        SET estado = 1; --estado de borrado logico
        WHERE id_atraccion = @id_atraccion
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW
    END CATCH
END
GO


-- SCRIPTS TESTING - ALTA DE ATRACCION

USE ParquesNacionales;
GO

-- PRECONDICIONES: asegurar que existan datos base

-- Insertar tipo de parque si no existe
EXEC parques.usp_InsertarTipoDeParque 'Parque Nacional';

-- Insertar parques de prueba si no existen
IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = 'Parque Nacional Iguazu')
    INSERT INTO parques.Parque (nombre, id_tipo_parque, ubicacion)
    VALUES ('Parque Nacional Iguazu', 
            (SELECT id_tipo_parque FROM parques.TipoParque WHERE descripcion = 'Parque Nacional'),
            'Misiones, Argentina');

IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = 'Parque Nacional Nahuel Huapi')
    INSERT INTO parques.Parque (nombre, id_tipo_parque, ubicacion)
    VALUES ('Parque Nacional Nahuel Huapi',
            (SELECT id_tipo_parque FROM parques.TipoParque WHERE descripcion = 'Parque Nacional'),
            'Rio Negro / Neuquen, Argentina');
GO

-- Variables auxiliares con los id de parques
DECLARE @id_iguazu INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Iguazu');
DECLARE @id_nahuel INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Nahuel Huapi');

-- INSERTS EXITOSOS
-- caso de inserción normal
BEGIN TRY
    EXEC actividades.usp_InsertarAtraccion
        @id_parque = @id_iguazu,
        @nombre = 'Paseo por la Garganta del Diablo',
        @costo = 5000.00,
        @duracion = 90,
        @cupo_maximo = 25,
        @tipo = 'Senderismo';
    PRINT 'Insertada correctamente';
END TRY
BEGIN CATCH
    PRINT 'ERROR: ' + ERROR_MESSAGE();
END CATCH
PRINT '';

-- caso de inserción con costo 0
BEGIN TRY
    EXEC actividades.usp_InsertarAtraccion
        @id_parque = @id_iguazu,
        @nombre = 'Mirador Salto Bossetti',
        @costo = 0.00,
        @duracion = 30,
        @cupo_maximo = NULL,
        @tipo = 'Avistaje';
    PRINT 'Insertada correctamente';
END TRY
BEGIN CATCH
    PRINT 'ERROR: ' + ERROR_MESSAGE();
END CATCH
PRINT '';

-- caso de inserción con duración y cupo maximo NULL
BEGIN TRY
    EXEC actividades.usp_InsertarAtraccion
        @id_parque = @id_nahuel,
        @nombre = 'Acceso libre al Cerro Campanario',
        @costo = 0.00,
        @duracion = NULL,
        @cupo_maximo = NULL,
        @tipo = 'Senderismo';
    PRINT 'Insertada correctamente';
END TRY
BEGIN CATCH
    PRINT 'ERROR: ' + ERROR_MESSAGE();
END CATCH
PRINT '';

-- caso de inserción de atracción con mismo nombre pero en otro parque
BEGIN TRY
    EXEC actividades.usp_InsertarAtraccion
        @id_parque = @id_nahuel,
        @nombre = 'Paseo por la Garganta del Diablo',  -- mismo nombre que primer caso
        @costo = 3500.00,
        @duracion = 60,
        @cupo_maximo = 20,
        @tipo = 'Senderismo';
    PRINT 'Insertada correctamente';
END TRY
BEGIN CATCH
    PRINT 'ERROR: ' + ERROR_MESSAGE();
END CATCH
PRINT '';



-- CASOS NEGATIVOS (debe haber error personalizado)
-- caso de inserción con el mismo nombre en el mismo parque
BEGIN TRY
    EXEC actividades.usp_InsertarAtraccion
        @id_parque = @id_iguazu,
        @nombre = 'Paseo por la Garganta del Diablo',  -- ya existe en parque iguazu
        @costo = 5500.00,
        @duracion = 90,
        @cupo_maximo = 25,
        @tipo = 'Senderismo';
END TRY
BEGIN CATCH
    PRINT 'Rechazado: ' + ERROR_MESSAGE();
END CATCH
PRINT '';

-- caso de inserción de parque con id inexistente
BEGIN TRY
    EXEC actividades.usp_InsertarAtraccion
        @id_parque = 99999,
        @nombre = 'Atraccion en parque fantasma',
        @costo = 1000.00,
        @duracion = 45,
        @cupo_maximo = 15,
        @tipo = 'Cultural';
END TRY
BEGIN CATCH
    PRINT 'Rechazado: ' + ERROR_MESSAGE();
END CATCH
PRINT '';


-- ver lo que quedo cargado luego de test
SELECT 
    a.id_atraccion,
    p.nombre AS parque,
    a.nombre AS atraccion,
    a.costo,
    a.duracion AS duracion_min,
    a.cupo_maximo,
    a.tipo
FROM actividades.Atraccion a
INNER JOIN parques.Parque p ON p.id_parque = a.id_parque
ORDER BY a.id_atraccion;
GO
