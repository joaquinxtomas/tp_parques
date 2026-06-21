USE ParquesNacionales;
GO

--ABM SCHEMA ACTIVIDADES
/* ATRACCION */

/* ALTA */
CREATE OR ALTER PROCEDURE actividades.InsertarAtraccion  
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
CREATE OR ALTER PROCEDURE actividades.ActualizarAtraccion
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
CREATE OR ALTER PROCEDURE actividades.EliminarAtraccion
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

    IF @v_errores <> ''
    BEGIN
        THROW 50000, @v_errores, 1;
    END

    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE actividades.Atraccion
        SET estado = 1 --estado de borrado logico
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
EXEC parques.InsertarTipoDeParque 'Parque Nacional';

-- Insertar parques de prueba si no existen
IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = 'Parque Nacional Iguazu')
    INSERT INTO parques.Parque (nombre, id_tipo_parque, region)
    VALUES ('Parque Nacional Iguazu', 
            (SELECT id_tipo_parque FROM parques.TipoParque WHERE descripcion = 'Parque Nacional'),
            'Litoral');

IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = 'Parque Nacional Nahuel Huapi')
    INSERT INTO parques.Parque (nombre, id_tipo_parque, region)
    VALUES ('Parque Nacional Nahuel Huapi',
            (SELECT id_tipo_parque FROM parques.TipoParque WHERE descripcion = 'Parque Nacional'),
            'Cuyo');
GO

-- Variables auxiliares con los id de parques
DECLARE @id_iguazu INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Iguazu');
DECLARE @id_nahuel INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Nahuel Huapi');

-- INSERTS EXITOSOS
-- caso de inserción normal
BEGIN TRY
    EXEC actividades.InsertarAtraccion
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
    EXEC actividades.InsertarAtraccion
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
    EXEC actividades.InsertarAtraccion
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
    EXEC actividades.InsertarAtraccion
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
    EXEC actividades.InsertarAtraccion
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
    EXEC actividades.InsertarAtraccion
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

-- SCRIPTS TESTING - MODIFICACION
USE ParquesNacionales;
GO

--limpieza 
DELETE FROM actividades.Atraccion WHERE nombre LIKE 'TEST_%';
GO

DECLARE @id_iguazu INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Iguazu');
DECLARE @id_nahuel INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Nahuel Huapi');

--carga de atracciones
EXEC actividades.InsertarAtraccion @id_iguazu, 'TEST_Sendero', 1000, 60, 20, 'Senderismo';
EXEC actividades.InsertarAtraccion @id_iguazu, 'TEST_Mirador', 0, 30, NULL, 'Avistaje';
EXEC actividades.InsertarAtraccion @id_nahuel, 'TEST_Kayak', 2500, 90, 10, 'Acuatica';

DECLARE @id_sendero INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Sendero');
DECLARE @id_mirador INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Mirador');
DECLARE @id_kayak INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Kayak');

-- modificacion válida: cambia costo y duración
EXEC actividades.ActualizarAtraccion @id_sendero, 'TEST_Sendero', 1500, 75, 20, 'Senderismo';

-- modificación válida: cambio de nombre
EXEC actividades.ActualizarAtraccion @id_mirador, 'TEST_Mirador Renovado', 0, 30, NULL, 'Avistaje';

-- casos negativos
EXEC actividades.ActualizarAtraccion 99999, 'Fantasma', 100, 30, 10, 'Senderismo';        -- no existe
EXEC actividades.ActualizarAtraccion @id_sendero, 'TEST_Kayak', 1500, 75, 20, 'Senderismo';  -- nombre ok si kayak está en otro parque
EXEC actividades.ActualizarAtraccion @id_kayak, 'TEST_Mirador Renovado', 2500, 90, 10, 'Acuatica';  -- nombre libre, está en otro parque
EXEC actividades.ActualizarAtraccion @id_sendero, '', -100, -5, 0, '';                    -- multiples errores

-- modificarse a si mismo
EXEC actividades.ActualizarAtraccion @id_sendero, 'TEST_Sendero', 1800, 80, 25, 'Senderismo';

-- SCRIPTS TESTING - BAJA

-- baja ok
EXEC actividades.EliminarAtraccion 12;

-- casos negativos
EXEC actividades.EliminarAtraccion 99999;     -- no existe
EXEC actividades.EliminarAtraccion 12;  -- ya está dada de baja

-- ver como quedó la tabla

SELECT id_atraccion, nombre, costo, duracion, cupo_maximo, tipo, estado
FROM actividades.Atraccion
WHERE nombre LIKE 'TEST_%'
ORDER BY id_atraccion;
GO
---------------------------------------------------------------------------------------------------------
/* TOURGUIA */

-- ALTA
CREATE OR ALTER PROCEDURE actividades.InsertarTourGuia
    @id_atraccion INT,
    @id_guia INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF @id_atraccion IS NULL
        SET @v_errores += 'El id de la atraccion es obligatorio. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM actividades.atraccion WHERE id_atraccion = @id_atraccion)
        SET @v_errores += 'La atracción indicada no existe ';
    ELSE IF EXISTS (SELECT 1 FROM actividades.atraccion WHERE id_atraccion = @id_atraccion AND estado = 1)
        SET @v_errores += 'La atracción está dada de baja. ';

    IF @id_guia IS NULL
        SET @v_errores += 'El id del guía asignado es obligatorio. ';
    ELSE IF NOT EXISTS (SELECT 1 FROM personal.GuiaAutorizado WHERE id_guia = @id_guia)
        SET @v_errores += 'El guía indicado no existe. ';
    ELSE IF EXISTS (
        SELECT 1 FROM personal.GuiaAutorizado
        WHERE id_guia = @id_guia
        AND vigencia_hasta IS NOT NULL
        AND vigencia_desde <= vigencia_hasta
    )
        SET @v_errores += 'El guía no se encuentra en vigencia';

    IF EXISTS (SELECT 1 FROM actividades.tourguia WHERE id_atraccion = @id_atraccion AND id_guia = @id_guia AND estado = 0)
        SET @v_errores += 'El guía ya está asignado a esta atracción';

    IF @v_errores <> ''
    BEGIN
        THROW 50000, @v_errores, 1;
    END

    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO actividades.TourGuia (id_atraccion, id_guia)
        VALUES (@id_atraccion, @id_guia)
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- MODIFICACION (logica de negocio)
--CREATE OR ALTER PROCEDURE actividades.usp_ActualizarTourGuia

--BAJA
CREATE OR ALTER PROCEDURE actividades.usp_EliminarTourGuia
    @id_tour_guia INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM actividades.tourGuia WHERE id_tour_guia = @id_tour_guia)
        SET @v_errores += 'El tour no existe. ';
    ELSE IF EXISTS (SELECT 1 FROM actividades.tourGuia WHERE id_tour_guia = @id_tour_guia AND estado = 1)
        SET @v_errores += 'El tour ya está dado de baja. ';

    IF @v_errores <> ''
    BEGIN
        THROW 50000, @v_errores,1;
    END

    BEGIN TRY 
        BEGIN TRANSACTION;
            UPDATE actividades.tourGuia
            SET estado = 1
            WHERE id_tour_guia = @id_tour_guia
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- SCRIPTS TESTING 

USE ParquesNacionales;
GO

DECLARE @id_iguazu INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Iguazu');

-- insertar guias de prueba
IF NOT EXISTS (SELECT 1 FROM personal.GuiaAutorizado WHERE dni = '11111111')
    INSERT INTO personal.GuiaAutorizado (nombre, dni, especialidad, titulo, vigencia_desde)
    VALUES ('Guia Test 1', '11111111', 'Flora', 'Licenciado', '2024-01-01');

IF NOT EXISTS (SELECT 1 FROM personal.GuiaAutorizado WHERE dni = '22222222')
    INSERT INTO personal.GuiaAutorizado (nombre, dni, especialidad, titulo, vigencia_desde)
    VALUES ('Guia Test 2', '22222222', 'Fauna', NULL, '2024-01-01');

-- insertar atraccion de prueba
IF NOT EXISTS (SELECT 1 FROM actividades.Atraccion WHERE nombre = 'TEST_Tour_Selva')
    EXEC actividades.InsertarAtraccion @id_iguazu, 'TEST_Tour_Selva', 3000, 120, 15, 'Senderismo';
GO

DECLARE @id_guia1 INT = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni = '11111111');
DECLARE @id_guia2 INT = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni = '22222222');
DECLARE @id_tour INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Tour_Selva');

-- ALTA

-- casos válidos
EXEC actividades.InsertarTourGuia @id_tour, @id_guia1;
EXEC actividades.InsertarTourGuia @id_tour, @id_guia2;

-- casos negativos
EXEC actividades.InsertarTourGuia @id_tour, @id_guia1;    -- duplicado
EXEC actividades.InsertarTourGuia @id_tour, 99999;        -- guía inexistente
EXEC actividades.InsertarTourGuia 99999, @id_guia1;       -- atracción inexistente
EXEC actividades.InsertarTourGuia NULL, NULL;              -- ambos null

-- verificar como queda la tabla luego de los tests
SELECT tg.id_tour_guia, a.nombre AS atraccion, g.nombre AS guia, tg.estado
FROM actividades.TourGuia tg
INNER JOIN actividades.Atraccion a ON a.id_atraccion = tg.id_atraccion
INNER JOIN personal.GuiaAutorizado g ON g.id_guia = tg.id_guia
WHERE a.nombre = 'TEST_Tour_Selva';
GO

-- BAJA

DECLARE @id_asignacion INT = (
    SELECT TOP 1 id_tour_guia FROM actividades.TourGuia 
    WHERE id_guia = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni = '11111111')
      AND estado = 0
);

-- caso válido
EXEC actividades.usp_EliminarTourGuia @id_asignacion;

-- casos negativos
EXEC actividades.usp_EliminarTourGuia @id_asignacion;    -- ya dada de baja
EXEC actividades.usp_EliminarTourGuia 99999;              -- no existe

-- verificar como queda la tabla luego de los tests
SELECT tg.id_tour_guia, a.nombre AS atraccion, g.nombre AS guia, tg.estado
FROM actividades.TourGuia tg
INNER JOIN actividades.Atraccion a ON a.id_atraccion = tg.id_atraccion
INNER JOIN personal.GuiaAutorizado g ON g.id_guia = tg.id_guia
WHERE a.nombre = 'TEST_Tour_Selva';