--	16/06/2026
--  INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
--  Descripcion: Creacion de los STORED PROCEDURES de las operaciones ABM en tipos de ventas

-- CAMBIAR NOMBRE DE TICKET A ENTRADA EN TABLAS Y SP
-- TIPO DE VISITANTE "NO RESIDENTE"

USE ParquesNacionales;
GO

--               ABM DE VENTAS

-- TiposVisitante

CREATE OR ALTER PROCEDURE ventas.TipoVisitante_Nuevo    --	ALTA
    @descripcion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = ''
        SET @v_errores += 'La descripcion es obligatoria. ';
    
    IF EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE descripcion = @descripcion)
        SET @v_errores += 'Ya existe un tipo de visitante con esa descripcion. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    INSERT INTO ventas.TipoVisitante (descripcion)
    VALUES (@descripcion);
END
GO

CREATE OR ALTER PROCEDURE ventas.TipoVisitante_Modificar    --	MODIFICACION
    @id_tipo_visitante INT,
    @descripcion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id_tipo_visitante = @id_tipo_visitante AND estado = 1)
        SET @v_errores += 'El tipo de visitante está dado de baja. ';

    IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id_tipo_visitante = @id_tipo_visitante)
        SET @v_errores += 'El tipo de visitante no existe. ';

    IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = ''
        SET @v_errores += 'La descripcion es obligatoria. ';
    
    IF EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE descripcion = @descripcion AND id_tipo_visitante <> @id_tipo_visitante)
        SET @v_errores += 'Otro tipo de visitante ya usa esa descripcion. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    UPDATE ventas.TipoVisitante SET descripcion = @descripcion WHERE id_tipo_visitante = @id_tipo_visitante;
END
GO

CREATE OR ALTER PROCEDURE ventas.TipoVisitante_Eliminar    --	BAJA
    @id_tipo_visitante INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id_tipo_visitante = @id_tipo_visitante AND estado = 1)
        SET @v_errores += 'El tipo de visitante ya está dado de baja. ';

    IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id_tipo_visitante = @id_tipo_visitante)
        SET @v_errores += 'El tipo de visitante no existe. ';

    IF EXISTS (SELECT 1 FROM ventas.PrecioEntrada WHERE id_tipo_visitante = @id_tipo_visitante)
        SET @v_errores += 'No se puede eliminar: el tipo de visitante tiene precios asociados. ';

    --IF EXISTS (SELECT 1 FROM ventas.Ticket WHERE id_tipo_visitante = @id_tipo_visitante)
    --    SET @v_errores += 'No se puede eliminar: el tipo de visitante tiene tickets registrados. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    UPDATE ventas.TipoVisitante SET estado = 1 WHERE id_tipo_visitante = @id_tipo_visitante;
END
GO

-- PreciosEntrada

CREATE OR ALTER PROCEDURE ventas.PrecioEntrada_Nuevo_Normal    --	ALTA
    @id_parque INT,
    @id_tipo_visitante INT,
    @precio DECIMAL(10, 2),
    @fecha_inicio DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @id_parque)
        SET @v_errores += 'El parque no existe. ';

    IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id_tipo_visitante = @id_tipo_visitante)
        SET @v_errores += 'El tipo de visitante no existe. ';

    IF @precio IS NULL OR @precio < 0
        SET @v_errores += 'El precio debe ser un valor positivo. ';

    IF EXISTS (SELECT 1 FROM ventas.PrecioEntrada WHERE id_parque = @id_parque AND id_tipo_visitante = @id_tipo_visitante AND estado = 0)
        SET @v_errores += 'Ya existe un precio para ese parque y tipo de visitante. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    INSERT INTO ventas.PrecioEntrada (id_parque, id_tipo_visitante, precio, fecha_inicio) VALUES (@id_parque, @id_tipo_visitante, @precio, @fecha_inicio);
END
GO

CREATE OR ALTER PROCEDURE ventas.PrecioEntrada_Nuevo_Temporada    --	ALTA
    @id_parque INT,
    @id_tipo_visitante INT,
    @precio DECIMAL(10, 2),
    @fecha_inicio DATE,
    @fecha_fin DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @id_parque)
        SET @v_errores += 'El parque no existe. ';

    IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id_tipo_visitante = @id_tipo_visitante)
        SET @v_errores += 'El tipo de visitante no existe. ';

    IF @precio IS NULL OR @precio < 0
        SET @v_errores += 'El precio debe ser un valor positivo. ';

    IF EXISTS (SELECT 1 FROM ventas.PrecioEntrada WHERE id_parque = @id_parque AND id_tipo_visitante = @id_tipo_visitante AND estado = 0)
        SET @v_errores += 'Ya existe un precio para ese parque y tipo de visitante. ';
    
    IF @fecha_inicio IS NULL OR @fecha_fin IS NULL
        SET @v_errores += 'Las fechas de inicio y fin son obligatorias. ';
    ELSE IF @fecha_inicio >= @fecha_fin
        SET @v_errores += 'La fecha de inicio debe ser anterior a la fecha de fin. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    INSERT INTO ventas.PrecioEntrada (id_parque, id_tipo_visitante, precio, fecha_inicio, fecha_fin) VALUES (@id_parque, @id_tipo_visitante, @precio, @fecha_inicio, @fecha_fin);
END
GO

CREATE OR ALTER PROCEDURE ventas.PrecioEntrada_Modificar_Precio    --	MODIFICACION DE PRECIO
    @id_precio INT,
    @precio DECIMAL(10, 2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM ventas.PrecioEntrada WHERE id_precio = @id_precio AND estado = 0)
        SET @v_errores += 'El precio de entrada no existe o está dado de baja. ';

    IF @precio IS NULL OR @precio < 0
        SET @v_errores += 'El precio debe ser un valor positivo. ';

    IF EXISTS (SELECT 1 FROM ventas.PrecioEntrada WHERE id_precio = @id_precio AND estado = 1)
        SET @v_errores += 'El precio de entrada está dado de baja. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    UPDATE ventas.PrecioEntrada SET precio = @precio WHERE id_precio = @id_precio;
END
GO

CREATE OR ALTER PROCEDURE ventas.PrecioEntrada_Eliminar    --	BAJA
    @id_precio INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM ventas.PrecioEntrada WHERE id_precio = @id_precio)
        SET @v_errores += 'El precio de entrada no existe. ';

    IF EXISTS (SELECT 1 FROM ventas.PrecioEntrada WHERE id_precio = @id_precio AND estado = 1)
        SET @v_errores += 'El precio de entrada ya está dado de baja. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    UPDATE ventas.PrecioEntrada SET estado = 1, fecha_fin = GETDATE() WHERE id_precio = @id_precio;
END
GO

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
    @id_tipo_5  INT = NULL,
    @cantidad_5 INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';
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

        INSERT INTO ventas.TicketVisitante (id_ticket, id_tipo_visitante, cantidad, precio_unit, subtotal)
        VALUES (@id_entrada, @id_tipo_1, @cantidad_1, @precio_1, @cantidad_1 * @precio_1);

        IF @id_tipo_2 IS NOT NULL
            INSERT INTO ventas.TicketVisitante (id_ticket, id_tipo_visitante, cantidad, precio_unit, subtotal)
            VALUES (@id_entrada, @id_tipo_2, @cantidad_2, @precio_2, @cantidad_2 * @precio_2);

        IF @id_tipo_3 IS NOT NULL
            INSERT INTO ventas.TicketVisitante (id_ticket, id_tipo_visitante, cantidad, precio_unit, subtotal)
            VALUES (@id_entrada, @id_tipo_3, @cantidad_3, @precio_3, @cantidad_3 * @precio_3);

        IF @id_tipo_4 IS NOT NULL
            INSERT INTO ventas.TicketVisitante (id_ticket, id_tipo_visitante, cantidad, precio_unit, subtotal)
            VALUES (@id_entrada, @id_tipo_4, @cantidad_4, @precio_4, @cantidad_4 * @precio_4);

        IF @id_tipo_5 IS NOT NULL
            INSERT INTO ventas.TicketVisitante (id_ticket, id_tipo_visitante, cantidad, precio_unit, subtotal)
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
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM ventas.Ticket WHERE id_ticket = @id_ticket)
        SET @v_errores += 'El ticket no existe. ';

    IF EXISTS (SELECT 1 FROM ventas.Ticket WHERE id_ticket = @id_ticket AND estado = 1)
        SET @v_errores += 'El ticket ya está dado de baja. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    UPDATE ventas.Ticket SET estado = 1 WHERE id_ticket = @id_ticket;
END
GO