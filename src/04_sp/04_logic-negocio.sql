-- PARQUESNACIONALES

USE ParquesNacionales;
GO

--               ABM DE VENTAS

-- ENTRADA

CREATE OR ALTER PROCEDURE ventas.Entrada_Nuevo  --	ALTA ENTRADA
    @id_parque  INT,
    @pto_venta  INT,
    @fecha      DATETIME2(0),
    @forma_pago VARCHAR(20),
    @id_tipo_1  INT,
    @cantidad_1 INT,            -- uno obligatorio, el resto opcional
    @id_tipo_2  INT = NULL,
    @cantidad_2 INT = NULL,
    @id_tipo_3  INT = NULL,
    @cantidad_3 INT = NULL,
    @id_tipo_4  INT = NULL,
    @cantidad_4 INT = NULL,
    @id_tipo_5       INT = NULL,
    @cantidad_5      INT = NULL,
    @recargo_feriado BIT = 0        -- 1 = feriado, aplica CEILING(precio * 1.2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(2000) = '';
    DECLARE @total     DECIMAL(12,2) = 0;
    DECLARE @id_entrada INT;

    DECLARE @precio_1  DECIMAL(10,2),
        @precio_2  DECIMAL(10,2),
        @precio_3  DECIMAL(10,2),
        @precio_4  DECIMAL(10,2),
        @precio_5  DECIMAL(10,2);

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @id_parque AND estado = 0)
        SET @v_errores += 'El parque no existe o está inactivo. ';

    IF @forma_pago NOT IN ('Efectivo', 'Débito', 'Crédito', 'Transferencia', 'QR')
        SET @v_errores += 'Forma de pago inválida. ';

    IF @cantidad_1 IS NULL OR @cantidad_1 <= 0
        SET @v_errores += 'La cantidad del tipo de visitante 1 debe ser mayor a 0. ';

    IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id_tipo_visitante = @id_tipo_1 AND estado = 0)
        SET @v_errores += 'El tipo de visitante 1 no existe o está inactivo. ';
    ELSE
    BEGIN
        SELECT @precio_1 = precio FROM ventas.PrecioEntrada
        WHERE id_parque = @id_parque AND id_tipo_visitante = @id_tipo_1
          AND fecha_inicio <= CAST(@fecha AS DATE)
          AND (fecha_fin IS NULL OR fecha_fin >= CAST(@fecha AS DATE))
          AND estado = 0;

        IF @precio_1 IS NULL
            SET @v_errores += 'El tipo de visitante 1 no tiene precio vigente para la fecha indicada. ';
    END

    IF @id_tipo_2 IS NOT NULL
    BEGIN
        IF @cantidad_2 IS NULL OR @cantidad_2 <= 0
            SET @v_errores += 'La cantidad del tipo de visitante 2 debe ser mayor a 0. ';

        IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id_tipo_visitante = @id_tipo_2 AND estado = 0)
            SET @v_errores += 'El tipo de visitante 2 no existe o está inactivo. ';
        ELSE
        BEGIN
            SELECT @precio_2 = precio FROM ventas.PrecioEntrada
            WHERE id_parque = @id_parque AND id_tipo_visitante = @id_tipo_2
              AND fecha_inicio <= CAST(@fecha AS DATE)
              AND (fecha_fin IS NULL OR fecha_fin >= CAST(@fecha AS DATE))
              AND estado = 0;

            IF @precio_2 IS NULL
                SET @v_errores += 'El tipo de visitante 2 no tiene precio vigente para la fecha indicada. ';
        END
    END

    IF @id_tipo_3 IS NOT NULL
    BEGIN
        IF @cantidad_3 IS NULL OR @cantidad_3 <= 0
            SET @v_errores += 'La cantidad del tipo de visitante 3 debe ser mayor a 0. ';

        IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id_tipo_visitante = @id_tipo_3 AND estado = 0)
            SET @v_errores += 'El tipo de visitante 3 no existe o está inactivo. ';
        ELSE
        BEGIN
            SELECT @precio_3 = precio FROM ventas.PrecioEntrada
            WHERE id_parque = @id_parque AND id_tipo_visitante = @id_tipo_3
              AND fecha_inicio <= CAST(@fecha AS DATE)
              AND (fecha_fin IS NULL OR fecha_fin >= CAST(@fecha AS DATE))
              AND estado = 0;

            IF @precio_3 IS NULL
                SET @v_errores += 'El tipo de visitante 3 no tiene precio vigente para la fecha indicada. ';
        END
    END

    IF @id_tipo_4 IS NOT NULL
    BEGIN
        IF @cantidad_4 IS NULL OR @cantidad_4 <= 0
            SET @v_errores += 'La cantidad del tipo de visitante 4 debe ser mayor a 0. ';

        IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id_tipo_visitante = @id_tipo_4 AND estado = 0)
            SET @v_errores += 'El tipo de visitante 4 no existe o está inactivo. ';
        ELSE
        BEGIN
            SELECT @precio_4 = precio FROM ventas.PrecioEntrada
            WHERE id_parque = @id_parque AND id_tipo_visitante = @id_tipo_4
              AND fecha_inicio <= CAST(@fecha AS DATE)
              AND (fecha_fin IS NULL OR fecha_fin >= CAST(@fecha AS DATE))
              AND estado = 0;

            IF @precio_4 IS NULL
                SET @v_errores += 'El tipo de visitante 4 no tiene precio vigente para la fecha indicada. ';
        END
    END

    IF @id_tipo_5 IS NOT NULL
    BEGIN
        IF @cantidad_5 IS NULL OR @cantidad_5 <= 0
            SET @v_errores += 'La cantidad del tipo de visitante 5 debe ser mayor a 0. ';

        IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id_tipo_visitante = @id_tipo_5 AND estado = 0)
            SET @v_errores += 'El tipo de visitante 5 no existe o está inactivo. ';
        ELSE
        BEGIN
            SELECT @precio_5 = precio FROM ventas.PrecioEntrada
            WHERE id_parque = @id_parque AND id_tipo_visitante = @id_tipo_5
              AND fecha_inicio <= CAST(@fecha AS DATE)
              AND (fecha_fin IS NULL OR fecha_fin >= CAST(@fecha AS DATE))
              AND estado = 0;

            IF @precio_5 IS NULL
                SET @v_errores += 'El tipo de visitante 5 no tiene precio vigente para la fecha indicada. ';
        END
    END

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    IF @recargo_feriado = 1
    BEGIN
        SET @precio_1 = CEILING(@precio_1 * 1.2);
        IF @precio_2 IS NOT NULL SET @precio_2 = CEILING(@precio_2 * 1.2);
        IF @precio_3 IS NOT NULL SET @precio_3 = CEILING(@precio_3 * 1.2);
        IF @precio_4 IS NOT NULL SET @precio_4 = CEILING(@precio_4 * 1.2);
        IF @precio_5 IS NOT NULL SET @precio_5 = CEILING(@precio_5 * 1.2);
    END

    BEGIN TRANSACTION;
    BEGIN TRY
        -- calcular total
        SET @total = (@precio_1 * @cantidad_1) + ISNULL(@precio_2 * @cantidad_2, 0)
                   + ISNULL(@precio_3 * @cantidad_3, 0) + ISNULL(@precio_4 * @cantidad_4, 0)
                   + ISNULL(@precio_5 * @cantidad_5, 0);
        
        INSERT INTO ventas.Entrada (id_parque, pto_venta, nro_ticket, fecha, forma_pago, total)
        VALUES (@id_parque, @pto_venta, 0, @fecha, @forma_pago, @total);

        SET @id_entrada = SCOPE_IDENTITY();

        UPDATE ventas.Entrada
        SET nro_ticket = @id_parque * 1000000 + @id_entrada
        WHERE id_entrada = @id_entrada;

        INSERT INTO ventas.TicketVisitante (id_entrada, id_tipo_visitante, cantidad, precio_unit, subtotal)
        VALUES (@id_entrada, @id_tipo_1, @cantidad_1, @precio_1, @cantidad_1 * @precio_1);

        IF @id_tipo_2 IS NOT NULL
            INSERT INTO ventas.TicketVisitante (id_entrada, id_tipo_visitante, cantidad, precio_unit, subtotal)
            VALUES (@id_entrada, @id_tipo_2, @cantidad_2, @precio_2, @cantidad_2 * @precio_2);

        IF @id_tipo_3 IS NOT NULL
            INSERT INTO ventas.TicketVisitante (id_entrada, id_tipo_visitante, cantidad, precio_unit, subtotal)
            VALUES (@id_entrada, @id_tipo_3, @cantidad_3, @precio_3, @cantidad_3 * @precio_3);

        IF @id_tipo_4 IS NOT NULL
            INSERT INTO ventas.TicketVisitante (id_entrada, id_tipo_visitante, cantidad, precio_unit, subtotal)
            VALUES (@id_entrada, @id_tipo_4, @cantidad_4, @precio_4, @cantidad_4 * @precio_4);

        IF @id_tipo_5 IS NOT NULL
            INSERT INTO ventas.TicketVisitante (id_entrada, id_tipo_visitante, cantidad, precio_unit, subtotal)
            VALUES (@id_entrada, @id_tipo_5, @cantidad_5, @precio_5, @cantidad_5 * @precio_5);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE ventas.Ticket_Eliminar    --	BAJA TICKET
    @id_ticket INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(2000) = '';

    IF NOT EXISTS (SELECT 1 FROM ventas.Entrada WHERE id_entrada = @id_ticket)
        SET @v_errores += 'El ticket no existe. ';

    IF EXISTS (SELECT 1 FROM ventas.Entrada WHERE id_entrada = @id_ticket AND estado = 1)
        SET @v_errores += 'El ticket ya está dado de baja. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END
    UPDATE ventas.Entrada SET estado = 1 WHERE id_entrada = @id_ticket;
END
GO

--====================================================================================
--						LOGICAS DE NEGOCIO REGISTRO DE ACTIVIDADES
--====================================================================================

Use ParquesNacionales
GO

CREATE OR ALTER PROCEDURE actividades.RegistrarTicketActividad
	@id_atraccion INT,
	@cantidad INT,
	@fecha_actividad DATE
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

	DECLARE @v_errores VARCHAR (2000) = '';
	DECLARE @v_costo DECIMAL (10,2);
	DECLARE @v_cupo INT;
	DECLARE @v_estado BIT;
	DECLARE @v_existe BIT = 0;
	DECLARE @v_turno TIME;
	DECLARE @v_ocupado INT;
	DECLARE @v_subtotal DECIMAL (12,2);
	DECLARE @v_fechaActual DATETIME2(0)= SYSDATETIME();
	DECLARE @v_inicioActividad DATETIME2(0);
BEGIN TRANSACTION
BEGIN TRY
	-- (a) cantidad positiva
    IF @cantidad IS NULL OR @cantidad <= 0
		SET @v_errores += '- La cantidad debe ser mayor a cero.';

	IF @fecha_actividad IS NULL
		SET @v_errores += '- La fecha de la actividad es obligatoria. ';

	SELECT @v_costo  = costo,
           @v_cupo   = cupo_maximo,
           @v_estado = estado,
		   @v_turno  = turno,
           @v_existe = 1 -- me indica si encontro la atraccion 
	FROM actividades.Atraccion WHERE id_atraccion = @id_atraccion;

	IF @v_existe = 0
		SET @v_errores += 'La atraccion no existe. ';
    ELSE IF @v_estado = 1
		SET @v_errores += 'La atraccion esta dada de baja. ';

	IF @v_existe = 1 AND @v_estado = 0 AND @fecha_actividad IS NOT NULL  -- verifico si la actividad no comenzo ya
	BEGIN
		--armo una fecha y hora de inicio con la fecha de actividad y hora del turno
		SET @v_inicioActividad = DATETIME2FROMPARTS(YEAR(@fecha_actividad), MONTH(@fecha_actividad), DAY(@fecha_actividad), DATEPART(HOUR, @v_turno), DATEPART(MINUTE, @v_turno), DATEPART(SECOND, @v_turno),0, 0);
		IF @v_inicioActividad < @v_fechaActual
			SET @v_errores += 'No se puede registrar: la actividad ya comenzo (' 
				+ CONVERT(VARCHAR(16), @v_inicioActividad, 120) + '). ';
	END

	IF @v_existe = 1 AND @v_estado = 0 AND @cantidad > 0 AND @v_cupo IS NOT NULL AND @fecha_actividad IS NOT NULL
	-- si existe el ticket, atraccion activa, cantidad valida y tiene cupo definido, chequeo cuantos cupos ya voy ocupados hoy
	BEGIN -- CALCULO LA CANTIDAD DE CUPOS ACTUALMENTE PARA EL DIA DE HOY
		SELECT @v_ocupado = ISNULL(SUM(cantidad), 0)
		FROM   actividades.TicketsAtraccion
		WHERE  id_atraccion = @id_atraccion
		AND  fecha_actividad = @fecha_actividad
		AND  estado = 0;  
		IF @v_ocupado + @cantidad > @v_cupo
                SET @v_errores += 'Cupo insuficiente para el turno. Disponible: '
                    + CAST(@v_cupo - @v_ocupado AS VARCHAR(10))
                    + ', solicitado: ' + CAST(@cantidad AS VARCHAR(10)) + '. ';
   END
   IF @v_errores <> '' -- si hubo errores, cierro la transaccion antes de salir
   BEGIN
       ROLLBACK TRANSACTION;
	   RAISERROR(@v_errores, 16, 1);
       RETURN;
   END
       SET @v_subtotal = @cantidad * @v_costo;
	   INSERT INTO actividades.TicketsAtraccion (id_atraccion, fecha, fecha_actividad, cantidad, subtotal)
       VALUES (@id_atraccion, @v_fechaActual, @fecha_actividad, @cantidad, @v_subtotal);  
COMMIT TRANSACTION;
END TRY
BEGIN CATCH 
	IF @@TRANCOUNT > 0
       ROLLBACK TRANSACTION;

    DECLARE @v_msg VARCHAR(2000) = ERROR_MESSAGE();
    DECLARE @v_sev INT          = ERROR_SEVERITY();
    DECLARE @v_est INT          = ERROR_STATE();
    RAISERROR(@v_msg, @v_sev, @v_est);
    RETURN;
END CATCH;
END
GO

CREATE OR ALTER PROCEDURE actividades.CancelarTicketActividad
	@id_ticketAtraccion INT
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @v_errores VARCHAR(2000) = '';

	IF NOT EXISTS(SELECT 1 FROM actividades.TicketsAtraccion WHERE  id_ticket_atraccion = @id_ticketAtraccion )
	SET @v_errores += 'No existe un ticket con ese ID'

	IF EXISTS (SELECT 1 FROM actividades.TicketsAtraccion where  id_ticket_atraccion = @id_ticketAtraccion AND estado = 1)
	SET @v_errores += 'El registro ya esta dado de baja'

	IF @v_errores <> ''
	BEGIN 
		RAISERROR (@v_errores,16,1);
		RETURN;
	END

	UPDATE actividades.TicketsAtraccion SET estado = 1 WHERE id_ticket_atraccion = @id_ticketAtraccion;
END
GO