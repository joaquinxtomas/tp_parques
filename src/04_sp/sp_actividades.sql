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
		;THROW 50000, @v_errores, 1;
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
        ;THROW 50000, @v_errores, 1;
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

    IF @v_errores <> ''
    BEGIN
        ;THROW 50000, @v_errores, 1;
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

-------------------------------------------------------
-- SCRIPTS TESTING - ALTA DE ATRACCION

USE ParquesNacionales;
GO

-- PRECONDICIONES: asegurar que existan datos base
EXEC parques.InsertarTipoDeParque 'Parque Nacional';

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

SELECT id_parque, nombre FROM parques.Parque
WHERE nombre IN ('Parque Nacional Iguazu', 'Parque Nacional Nahuel Huapi');

--test 1: caso normal
EXEC actividades.usp_InsertarAtraccion
    @id_parque   = 39,                                  
    @nombre      = 'Paseo por la Garganta del Diablo',
    @costo       = 5000.00,
    @duracion    = 90,
    @cupo_maximo = 25,
    @tipo        = 'Senderismo';
GO

-- test 2: insertar con costo 0 (atracción gratuita)
EXEC actividades.usp_InsertarAtraccion
    @id_parque   = 39,                                  
    @nombre      = 'Mirador Salto Bossetti',
    @costo       = 0.00,
    @duracion    = 30,
    @cupo_maximo = NULL,
    @tipo        = 'Avistaje';
GO

-- test 3: insertar con duración y cupo NULL
EXEC actividades.usp_InsertarAtraccion
    @id_parque   = 40,                                  
    @nombre      = 'Acceso libre al Cerro Campanario',
    @costo       = 0.00,
    @duracion    = NULL,
    @cupo_maximo = NULL,
    @tipo        = 'Senderismo';
GO

-- test 4: mismo nombre en otro parque (debe funcionar)
EXEC actividades.usp_InsertarAtraccion
    @id_parque   = 40,                                 
    @nombre      = 'Paseo por la Garganta del Diablo',
    @costo       = 3500.00,
    @duracion    = 60,
    @cupo_maximo = 20,
    @tipo        = 'Senderismo';
GO

-- test 5 negativo: nombre duplicado en el mismo parque
EXEC actividades.usp_InsertarAtraccion
    @id_parque   = 39,                                 
    @nombre      = 'Paseo por la Garganta del Diablo', -- ya existe en Iguazu
    @costo       = 5500.00,
    @duracion    = 90,
    @cupo_maximo = 25,
    @tipo        = 'Senderismo';
GO

-- test 6 negativo: id de parque inexistente
EXEC actividades.usp_InsertarAtraccion
    @id_parque   = 99999,
    @nombre      = 'Atraccion en parque fantasma',
    @costo       = 1000.00,
    @duracion    = 45,
    @cupo_maximo = 15,
    @tipo        = 'Cultural';
GO

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

-- Prerequisitos: insertar datos de prueba
DECLARE @id_iguazu INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Iguazu');
DECLARE @id_nahuel INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Nahuel Huapi');

EXEC actividades.usp_InsertarAtraccion @id_iguazu, 'TEST_Sendero', 1000, 60, 20, 'Senderismo';
EXEC actividades.usp_InsertarAtraccion @id_iguazu, 'TEST_Mirador', 0, 30, NULL, 'Avistaje';
EXEC actividades.usp_InsertarAtraccion @id_nahuel, 'TEST_Kayak', 2500, 90, 10, 'Acuatica';
GO

-- test 1 positivo: modificación válida, cambia costo y duración
DECLARE @id INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Sendero');
EXEC actividades.usp_ActualizarAtraccion
    @id_atraccion = @id,
    @nombre       = 'TEST_Sendero',
    @costo        = 1500,
    @duracion     = 75,
    @cupo_maximo  = 20,
    @tipo         = 'Senderismo';
GO

-- test 2 positivo: cambio de nombre
DECLARE @id INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Mirador');
EXEC actividades.usp_ActualizarAtraccion
    @id_atraccion = @id,
    @nombre       = 'TEST_Mirador Renovado',
    @costo        = 0,
    @duracion     = 30,
    @cupo_maximo  = NULL,
    @tipo         = 'Avistaje';
GO

-- test 3 negativo: id de atracción inexistente
EXEC actividades.usp_ActualizarAtraccion
    @id_atraccion = 99999,
    @nombre       = 'Fantasma',
    @costo        = 100,
    @duracion     = 30,
    @cupo_maximo  = 10,
    @tipo         = 'Senderismo';
GO

-- test 4 positivo: nombre duplicado pero en otro parque (debería permitirse)
DECLARE @id INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Sendero');
EXEC actividades.usp_ActualizarAtraccion
    @id_atraccion = @id,
    @nombre       = 'TEST_Kayak',
    @costo        = 1500,
    @duracion     = 75,
    @cupo_maximo  = 20,
    @tipo         = 'Senderismo';
GO

-- test 5 positivo: nombre existente en otro parque (debería permitirse)
DECLARE @id INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Kayak' AND id_parque = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Nahuel Huapi'));
EXEC actividades.usp_ActualizarAtraccion
    @id_atraccion = @id,
    @nombre       = 'TEST_Mirador Renovado',
    @costo        = 2500,
    @duracion     = 90,
    @cupo_maximo  = 10,
    @tipo         = 'Acuatica';
GO

-- test 6 negativo: múltiples errores (nombre vacío, costo negativo, duración negativa, cupo cero, tipo vacío)
DECLARE @id INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Sendero');
EXEC actividades.usp_ActualizarAtraccion
    @id_atraccion = @id,
    @nombre       = '',
    @costo        = -100,
    @duracion     = -5,
    @cupo_maximo  = 0,
    @tipo         = '';
GO

-- SCRIPTS TESTING - BAJA

-- baja ok
EXEC actividades.usp_EliminarAtraccion 1;

-- casos negativos
EXEC actividades.usp_EliminarAtraccion 99999;     -- no existe
EXEC actividades.usp_EliminarAtraccion 1;  -- ya está dada de baja

-- ver como quedó la tabla

SELECT id_atraccion, nombre, costo, duracion, cupo_maximo, tipo, estado
FROM actividades.Atraccion
WHERE nombre LIKE 'TEST_%'
ORDER BY id_atraccion;

---------------------------------------------------------------------------------------------------------
/* TOURGUIA */

-- ALTA
CREATE OR ALTER PROCEDURE actividades.usp_InsertarTourGuia
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
        ;THROW 50000, @v_errores, 1;
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
        ;THROW 50000, @v_errores,1;
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


-- SCRIPTS TESTING TOURGUIA

USE ParquesNacionales;
GO

-- ejecutar una sola vez
DECLARE @id_iguazu INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Iguazu');

IF NOT EXISTS (SELECT 1 FROM personal.GuiaAutorizado WHERE dni = '11111111')
    INSERT INTO personal.GuiaAutorizado (nombre, dni, especialidad, titulo, vigencia_desde)
    VALUES ('Guia Test 1', '11111111', 'Flora', 'Licenciado', '2024-01-01');

IF NOT EXISTS (SELECT 1 FROM personal.GuiaAutorizado WHERE dni = '22222222')
    INSERT INTO personal.GuiaAutorizado (nombre, dni, especialidad, titulo, vigencia_desde)
    VALUES ('Guia Test 2', '22222222', 'Fauna', NULL, '2024-01-01');

IF NOT EXISTS (SELECT 1 FROM actividades.Atraccion WHERE nombre = 'TEST_Tour_Selva')
    EXEC actividades.usp_InsertarAtraccion @id_iguazu, 'TEST_Tour_Selva', 3000, 120, 15, 'Senderismo';
GO

-- ALTA
-- test 1 positivo: asignar guía a atracción
DECLARE @id_tour INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Tour_Selva');
DECLARE @id_guia INT = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni = '11111111');
EXEC actividades.usp_InsertarTourGuia
    @id_atraccion = @id_tour,
    @id_guia      = @id_guia;
GO

-- test 2 positivo: asignar segundo guía a la misma atracción
DECLARE @id_tour INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Tour_Selva');
DECLARE @id_guia INT = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni = '22222222');
EXEC actividades.usp_InsertarTourGuia
    @id_atraccion = @id_tour,
    @id_guia      = @id_guia;
GO

-- test 3 negativo: guía ya asignado (duplicado)
DECLARE @id_tour INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Tour_Selva');
DECLARE @id_guia INT = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni = '11111111');
EXEC actividades.usp_InsertarTourGuia
    @id_atraccion = @id_tour,
    @id_guia      = @id_guia;
GO

-- test 4 negativo: guía inexistente
DECLARE @id_tour INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Tour_Selva');
EXEC actividades.usp_InsertarTourGuia
    @id_atraccion = @id_tour,
    @id_guia      = 99999;
GO

-- test 5 negativo: atracción inexistente
DECLARE @id_guia INT = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni = '11111111');
EXEC actividades.usp_InsertarTourGuia
    @id_atraccion = 99999,
    @id_guia      = @id_guia;
GO

-- test 6 negativo: ambos NULL
EXEC actividades.usp_InsertarTourGuia
    @id_atraccion = NULL,
    @id_guia      = NULL;
GO

-- verificar
SELECT tg.id_tour_guia, a.nombre AS atraccion, g.nombre AS guia, tg.estado
FROM actividades.TourGuia tg
INNER JOIN actividades.Atraccion a ON a.id_atraccion = tg.id_atraccion
INNER JOIN personal.GuiaAutorizado g ON g.id_guia = tg.id_guia
WHERE a.nombre = 'TEST_Tour_Selva';
GO

-- BAJA
-- test 7 positivo: baja válida
DECLARE @id_asignacion INT = (
    SELECT TOP 1 id_tour_guia FROM actividades.TourGuia
    WHERE id_guia = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni = '11111111')
      AND estado = 0
);
EXEC actividades.usp_EliminarTourGuia
    @id_tour_guia = @id_asignacion;
GO

-- test 8 negativo: ya dada de baja
DECLARE @id_asignacion INT = (
    SELECT TOP 1 id_tour_guia FROM actividades.TourGuia
    WHERE id_guia = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni = '11111111')
      AND estado = 1
);
EXEC actividades.usp_EliminarTourGuia
    @id_tour_guia = @id_asignacion;
GO

-- test 9 negativo: tour inexistente
EXEC actividades.usp_EliminarTourGuia
    @id_tour_guia = 99999;
GO

-- verificar
SELECT tg.id_tour_guia, a.nombre AS atraccion, g.nombre AS guia, tg.estado
FROM actividades.TourGuia tg
INNER JOIN actividades.Atraccion a ON a.id_atraccion = tg.id_atraccion
INNER JOIN personal.GuiaAutorizado g ON g.id_guia = tg.id_guia
WHERE a.nombre = 'TEST_Tour_Selva';
GO