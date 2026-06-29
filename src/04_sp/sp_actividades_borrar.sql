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
CREATE OR ALTER PROCEDURE actividades.EliminarTourGuia
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