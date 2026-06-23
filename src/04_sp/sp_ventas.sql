--	16/06/2026
--  INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
--  Descripcion: Creacion de los STORED PROCEDURES de las operaciones ABM en tipos de ventas

--  NOTAS:
--      TIPO DE VISITANTE "NO RESIDENTE" es "EXTRANJERO"

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


-- ============================================================
-- PRUEBAS
-- ============================================================

USE ParquesNacionales;
GO

-- PRECONDICIONES

BEGIN TRY
    EXEC parques.InsertarTipoDeParque @descripcion = 'Nacional';
END TRY
BEGIN CATCH
    PRINT 'Precondicion tipo parque: ' + ERROR_MESSAGE();
END CATCH
GO

DECLARE @id_tipo INT = (SELECT id_tipo_parque FROM parques.TipoParque WHERE descripcion = 'Nacional');
IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = 'Nahuel Huapi')
    EXEC parques.InsertarParque
        @nombre         = 'Nahuel Huapi',
        @id_tipo_parque = @id_tipo,
        @provincia      = 'Neuquén',
        @region         = 'Patagonia',
        @superficie     = 717261.00;
GO


-- ============================================================
-- TipoVisitante_Nuevo
-- ============================================================

-- CASO 1: descripcion NULL → error
BEGIN TRY
    EXEC ventas.TipoVisitante_Nuevo @descripcion = NULL;
    PRINT 'CASO 1 FALLO: no debería insertar';
END TRY
BEGIN CATCH
    PRINT 'CASO 1 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 2: descripcion vacía → error
BEGIN TRY
    EXEC ventas.TipoVisitante_Nuevo @descripcion = '   ';
    PRINT 'CASO 2 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 2 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 3: altas correctas (3 tipos)
BEGIN TRY
    EXEC ventas.TipoVisitante_Nuevo @descripcion = 'Residente';
    PRINT 'CASO 3a OK';
END TRY
BEGIN CATCH
    PRINT 'CASO 3a: ' + ERROR_MESSAGE();
END CATCH
GO
BEGIN TRY
    EXEC ventas.TipoVisitante_Nuevo @descripcion = 'Extranjero';
    PRINT 'CASO 3b OK';
END TRY
BEGIN CATCH
    PRINT 'CASO 3b: ' + ERROR_MESSAGE();
END CATCH
GO
BEGIN TRY
    EXEC ventas.TipoVisitante_Nuevo @descripcion = 'Jubilado';
    PRINT 'CASO 3c OK';
END TRY
BEGIN CATCH
    PRINT 'CASO 3c: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 4: descripcion duplicada → error
BEGIN TRY
    EXEC ventas.TipoVisitante_Nuevo @descripcion = 'Residente';
    PRINT 'CASO 4 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 4 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

SELECT id_tipo_visitante, descripcion, estado FROM ventas.TipoVisitante;
GO


-- ============================================================
-- TipoVisitante_Modificar
-- ============================================================

-- CASO 5: ID inexistente → error
BEGIN TRY
    EXEC ventas.TipoVisitante_Modificar @id_tipo_visitante = 9999, @descripcion = 'X';
    PRINT 'CASO 5 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 5 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 6: descripcion vacía → error
BEGIN TRY
    DECLARE @id INT = (SELECT id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    EXEC ventas.TipoVisitante_Modificar @id_tipo_visitante = @id, @descripcion = '';
    PRINT 'CASO 6 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 6 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 7: descripcion ya usada por otro tipo → error
BEGIN TRY
    DECLARE @id INT = (SELECT id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    EXEC ventas.TipoVisitante_Modificar @id_tipo_visitante = @id, @descripcion = 'Extranjero';
    PRINT 'CASO 7 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 7 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 8: modificación correcta
BEGIN TRY
    DECLARE @id INT = (SELECT id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Jubilado');
    EXEC ventas.TipoVisitante_Modificar @id_tipo_visitante = @id, @descripcion = 'Jubilado / Pensionado';
    PRINT 'CASO 8 OK: descripcion actualizada';
END TRY
BEGIN CATCH
    PRINT 'CASO 8 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO


-- ============================================================
-- TipoVisitante_Eliminar
-- ============================================================

-- CASO 9: ID inexistente → error
BEGIN TRY
    EXEC ventas.TipoVisitante_Eliminar @id_tipo_visitante = 9999;
    PRINT 'CASO 9 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 9 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 10: baja correcta ('Jubilado / Pensionado', sin precios asociados)
BEGIN TRY
    DECLARE @id INT = (SELECT id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Jubilado / Pensionado');
    EXEC ventas.TipoVisitante_Eliminar @id_tipo_visitante = @id;
    PRINT 'CASO 10 OK: tipo dado de baja';
END TRY
BEGIN CATCH
    PRINT 'CASO 10 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 11: ya dado de baja → error
BEGIN TRY
    DECLARE @id INT = (SELECT id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Jubilado / Pensionado');
    EXEC ventas.TipoVisitante_Eliminar @id_tipo_visitante = @id;
    PRINT 'CASO 11 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 11 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 12: modificar tipo dado de baja → error
BEGIN TRY
    DECLARE @id INT = (SELECT id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Jubilado / Pensionado');
    EXEC ventas.TipoVisitante_Modificar @id_tipo_visitante = @id, @descripcion = 'Jubilado';
    PRINT 'CASO 12 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 12 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO


-- ============================================================
-- PrecioEntrada_Nuevo_Normal
-- ============================================================

-- CASO 13: parque inexistente → error
BEGIN TRY
    DECLARE @id_res INT = (SELECT id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    EXEC ventas.PrecioEntrada_Nuevo_Normal @id_parque = 9999, @id_tipo_visitante = @id_res, @precio = 1500.00, @fecha_inicio = '2026-01-01';
    PRINT 'CASO 13 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 13 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 14: tipo visitante inexistente → error
BEGIN TRY
    DECLARE @id_p INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Nahuel Huapi');
    EXEC ventas.PrecioEntrada_Nuevo_Normal @id_parque = @id_p, @id_tipo_visitante = 9999, @precio = 1500.00, @fecha_inicio = '2026-01-01';
    PRINT 'CASO 14 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 14 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 15: precio negativo → error
BEGIN TRY
    DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
    DECLARE @id_res INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    EXEC ventas.PrecioEntrada_Nuevo_Normal @id_parque = @id_p, @id_tipo_visitante = @id_res, @precio = -100.00, @fecha_inicio = '2026-01-01';
    PRINT 'CASO 15 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 15 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 16: altas correctas Residente y Extranjero (precios vigentes desde 2026-01-01)
BEGIN TRY
    DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
    DECLARE @id_res INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    EXEC ventas.PrecioEntrada_Nuevo_Normal @id_parque = @id_p, @id_tipo_visitante = @id_res, @precio = 1500.00, @fecha_inicio = '2026-01-01';
    PRINT 'CASO 16a OK: precio Residente $1500 desde 2026-01-01';
END TRY
BEGIN CATCH
    PRINT 'CASO 16a ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO
BEGIN TRY
    DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
    DECLARE @id_ext INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Extranjero');
    EXEC ventas.PrecioEntrada_Nuevo_Normal @id_parque = @id_p, @id_tipo_visitante = @id_ext, @precio = 5000.00, @fecha_inicio = '2026-01-01';
    PRINT 'CASO 16b OK: precio Extranjero $5000 desde 2026-01-01';
END TRY
BEGIN CATCH
    PRINT 'CASO 16b ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 17: precio activo ya existe para ese parque + tipo → error
BEGIN TRY
    DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
    DECLARE @id_res INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    EXEC ventas.PrecioEntrada_Nuevo_Normal @id_parque = @id_p, @id_tipo_visitante = @id_res, @precio = 2000.00, @fecha_inicio = '2026-06-01';
    PRINT 'CASO 17 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 17 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO


-- ============================================================
-- PrecioEntrada_Nuevo_Temporada
-- ============================================================

-- CASO 18: fecha_fin < fecha_inicio → error
BEGIN TRY
    DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
    DECLARE @id_res INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    EXEC ventas.PrecioEntrada_Nuevo_Temporada @id_parque = @id_p, @id_tipo_visitante = @id_res,
        @precio = 2000.00, @fecha_inicio = '2026-08-01', @fecha_fin = '2026-07-31';
    PRINT 'CASO 18 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 18 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 19: fecha_inicio = fecha_fin → error (requiere estrictamente menor)
BEGIN TRY
    DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
    DECLARE @id_res INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    EXEC ventas.PrecioEntrada_Nuevo_Temporada @id_parque = @id_p, @id_tipo_visitante = @id_res,
        @precio = 2000.00, @fecha_inicio = '2026-07-01', @fecha_fin = '2026-07-01';
    PRINT 'CASO 19 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 19 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- Precondición: tipo 'Menor' sin precio activo (para tests de Entrada_Nuevo y temporada)
BEGIN TRY
    EXEC ventas.TipoVisitante_Nuevo @descripcion = 'Menor';
    PRINT 'Precondicion tipo Menor OK';
END TRY
BEGIN CATCH
    PRINT 'Precondicion tipo Menor: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 20: alta de temporada correcta (Menor, invierno 2026)
BEGIN TRY
    DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
    DECLARE @id_men INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Menor');
    EXEC ventas.PrecioEntrada_Nuevo_Temporada @id_parque = @id_p, @id_tipo_visitante = @id_men,
        @precio = 750.00, @fecha_inicio = '2026-07-01', @fecha_fin = '2026-08-31';
    PRINT 'CASO 20 OK: precio de temporada Menor $750 (jul-ago 2026)';
END TRY
BEGIN CATCH
    PRINT 'CASO 20 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO


-- ============================================================
-- PrecioEntrada_Modificar_Precio
-- ============================================================

-- CASO 21: id_precio inexistente → error
BEGIN TRY
    EXEC ventas.PrecioEntrada_Modificar_Precio @id_precio = 9999, @precio = 2000.00;
    PRINT 'CASO 21 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 21 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 22: precio negativo → error
BEGIN TRY
    DECLARE @id_prec INT = (
        SELECT pe.id_precio FROM ventas.PrecioEntrada pe
        JOIN ventas.TipoVisitante tv ON tv.id_tipo_visitante = pe.id_tipo_visitante
        WHERE tv.descripcion = 'Residente' AND pe.estado = 0
    );
    EXEC ventas.PrecioEntrada_Modificar_Precio @id_precio = @id_prec, @precio = -1.00;
    PRINT 'CASO 22 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 22 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 23: modificación correcta
BEGIN TRY
    DECLARE @id_prec INT = (
        SELECT pe.id_precio FROM ventas.PrecioEntrada pe
        JOIN ventas.TipoVisitante tv ON tv.id_tipo_visitante = pe.id_tipo_visitante
        WHERE tv.descripcion = 'Residente' AND pe.estado = 0
    );
    EXEC ventas.PrecioEntrada_Modificar_Precio @id_precio = @id_prec, @precio = 1800.00;
    PRINT 'CASO 23 OK: precio Residente actualizado a $1800';
END TRY
BEGIN CATCH
    PRINT 'CASO 23 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO


-- ============================================================
-- PrecioEntrada_Eliminar
-- ============================================================

-- CASO 24: id_precio inexistente → error
BEGIN TRY
    EXEC ventas.PrecioEntrada_Eliminar @id_precio = 9999;
    PRINT 'CASO 24 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 24 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 25: baja correcta (precio de temporada Menor)
BEGIN TRY
    DECLARE @id_prec INT = (
        SELECT pe.id_precio FROM ventas.PrecioEntrada pe
        JOIN ventas.TipoVisitante tv ON tv.id_tipo_visitante = pe.id_tipo_visitante
        WHERE tv.descripcion = 'Menor' AND pe.estado = 0
    );
    EXEC ventas.PrecioEntrada_Eliminar @id_precio = @id_prec;
    PRINT 'CASO 25 OK: precio Menor dado de baja';
END TRY
BEGIN CATCH
    PRINT 'CASO 25 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 26: ya dado de baja → error
BEGIN TRY
    DECLARE @id_prec INT = (
        SELECT pe.id_precio FROM ventas.PrecioEntrada pe
        JOIN ventas.TipoVisitante tv ON tv.id_tipo_visitante = pe.id_tipo_visitante
        WHERE tv.descripcion = 'Menor' AND pe.estado = 1
    );
    EXEC ventas.PrecioEntrada_Eliminar @id_precio = @id_prec;
    PRINT 'CASO 26 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 26 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 27: eliminar tipo visitante con precios activos → error
BEGIN TRY
    DECLARE @id INT = (SELECT id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    EXEC ventas.TipoVisitante_Eliminar @id_tipo_visitante = @id;
    PRINT 'CASO 27 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 27 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

SELECT id_precio, id_parque, id_tipo_visitante, precio, fecha_inicio, fecha_fin, estado
FROM ventas.PrecioEntrada ORDER BY id_precio;
GO


-- ============================================================
-- Entrada_Nuevo
-- ============================================================

-- CASO 28: parque inexistente → error
BEGIN TRY
    DECLARE @id_res INT = (SELECT id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    EXEC ventas.Entrada_Nuevo @id_parque = 9999, @pto_venta = 1, @fecha = '2026-06-23 10:00:00',
        @forma_pago = 'Efectivo', @id_tipo_1 = @id_res, @cantidad_1 = 1;
    PRINT 'CASO 28 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 28 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 29: forma de pago inválida → error
BEGIN TRY
    DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
    DECLARE @id_res INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    EXEC ventas.Entrada_Nuevo @id_parque = @id_p, @pto_venta = 1, @fecha = '2026-06-23 10:00:00',
        @forma_pago = 'Bitcoin', @id_tipo_1 = @id_res, @cantidad_1 = 1;
    PRINT 'CASO 29 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 29 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 30: cantidad_1 = 0 → error
BEGIN TRY
    DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
    DECLARE @id_res INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    EXEC ventas.Entrada_Nuevo @id_parque = @id_p, @pto_venta = 1, @fecha = '2026-06-23 10:00:00',
        @forma_pago = 'Efectivo', @id_tipo_1 = @id_res, @cantidad_1 = 0;
    PRINT 'CASO 30 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 30 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 31: tipo_1 inexistente → error
BEGIN TRY
    DECLARE @id_p INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Nahuel Huapi');
    EXEC ventas.Entrada_Nuevo @id_parque = @id_p, @pto_venta = 1, @fecha = '2026-06-23 10:00:00',
        @forma_pago = 'Efectivo', @id_tipo_1 = 9999, @cantidad_1 = 1;
    PRINT 'CASO 31 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 31 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 32: tipo_1 activo pero sin precio vigente para la fecha (Menor, precio dado de baja) → error
BEGIN TRY
    DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
    DECLARE @id_men INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Menor');
    EXEC ventas.Entrada_Nuevo @id_parque = @id_p, @pto_venta = 1, @fecha = '2026-06-23 10:00:00',
        @forma_pago = 'Efectivo', @id_tipo_1 = @id_men, @cantidad_1 = 1;
    PRINT 'CASO 32 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 32 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 33: alta correcta con 1 tipo de visitante
BEGIN TRY
    DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
    DECLARE @id_res INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    EXEC ventas.Entrada_Nuevo @id_parque = @id_p, @pto_venta = 1, @fecha = '2026-06-23 10:00:00',
        @forma_pago = 'Efectivo', @id_tipo_1 = @id_res, @cantidad_1 = 2;
    PRINT 'CASO 33 OK: entrada con 1 tipo insertada (2 residentes)';
END TRY
BEGIN CATCH
    PRINT 'CASO 33 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 34: tipo_2 sin precio vigente → error acumulado junto a tipo_1 válido
BEGIN TRY
    DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
    DECLARE @id_res INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    DECLARE @id_men INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Menor');
    EXEC ventas.Entrada_Nuevo @id_parque = @id_p, @pto_venta = 1, @fecha = '2026-06-23 11:00:00',
        @forma_pago = 'Débito', @id_tipo_1 = @id_res, @cantidad_1 = 1, @id_tipo_2 = @id_men, @cantidad_2 = 1;
    PRINT 'CASO 34 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 34 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 35: alta correcta con 2 tipos de visitante
BEGIN TRY
    DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
    DECLARE @id_res INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
    DECLARE @id_ext INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Extranjero');
    EXEC ventas.Entrada_Nuevo @id_parque = @id_p, @pto_venta = 1, @fecha = '2026-06-23 11:00:00',
        @forma_pago = 'Crédito', @id_tipo_1 = @id_res, @cantidad_1 = 1, @id_tipo_2 = @id_ext, @cantidad_2 = 2;
    PRINT 'CASO 35 OK: entrada con 2 tipos insertada';
END TRY
BEGIN CATCH
    PRINT 'CASO 35 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

SELECT e.id_entrada, e.nro_ticket, e.fecha, e.total, e.forma_pago,
       tv.descripcion AS tipo_visitante, tv2.cantidad, tv2.precio_unit, tv2.subtotal
FROM   ventas.Entrada e
JOIN   ventas.TicketVisitante tv2 ON tv2.id_ticket = e.id_entrada
JOIN   ventas.TipoVisitante   tv  ON tv.id_tipo_visitante = tv2.id_tipo_visitante
ORDER BY e.id_entrada, tv.descripcion;
GO


-- ============================================================
-- Ticket_Eliminar
-- ============================================================

-- CASO 36: ticket inexistente → error
BEGIN TRY
    EXEC ventas.Ticket_Eliminar @id_ticket = 9999;
    PRINT 'CASO 36 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 36 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 37: baja correcta (primer ticket activo)
BEGIN TRY
    DECLARE @id_tk INT = (SELECT MIN(id_entrada) FROM ventas.Entrada WHERE estado = 0);
    EXEC ventas.Ticket_Eliminar @id_ticket = @id_tk;
    PRINT 'CASO 37 OK: ticket dado de baja';
END TRY
BEGIN CATCH
    PRINT 'CASO 37 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 38: ya dado de baja → error
BEGIN TRY
    DECLARE @id_tk INT = (SELECT MIN(id_entrada) FROM ventas.Entrada WHERE estado = 1);
    EXEC ventas.Ticket_Eliminar @id_ticket = @id_tk;
    PRINT 'CASO 38 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 38 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO


-- ============================================================
-- LOTE: 10 Entradas válidas
-- ============================================================

DECLARE @id_p   INT = (SELECT id_parque          FROM parques.Parque       WHERE nombre      = 'Nahuel Huapi');
DECLARE @id_res INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Residente');
DECLARE @id_ext INT = (SELECT id_tipo_visitante   FROM ventas.TipoVisitante WHERE descripcion = 'Extranjero');

BEGIN TRY EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=1, @fecha='2026-06-01 08:30:00', @forma_pago='Efectivo',      @id_tipo_1=@id_res, @cantidad_1=3;                                            PRINT 'Lote  1 OK'; END TRY BEGIN CATCH PRINT 'Lote  1 ERROR: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=1, @fecha='2026-06-02 09:00:00', @forma_pago='Débito',        @id_tipo_1=@id_res, @cantidad_1=1, @id_tipo_2=@id_ext, @cantidad_2=1;       PRINT 'Lote  2 OK'; END TRY BEGIN CATCH PRINT 'Lote  2 ERROR: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=2, @fecha='2026-06-03 10:15:00', @forma_pago='Crédito',       @id_tipo_1=@id_ext, @cantidad_1=4;                                            PRINT 'Lote  3 OK'; END TRY BEGIN CATCH PRINT 'Lote  3 ERROR: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=2, @fecha='2026-06-04 11:00:00', @forma_pago='QR',            @id_tipo_1=@id_res, @cantidad_1=2, @id_tipo_2=@id_ext, @cantidad_2=3;       PRINT 'Lote  4 OK'; END TRY BEGIN CATCH PRINT 'Lote  4 ERROR: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=1, @fecha='2026-06-05 13:00:00', @forma_pago='Transferencia', @id_tipo_1=@id_res, @cantidad_1=5;                                            PRINT 'Lote  5 OK'; END TRY BEGIN CATCH PRINT 'Lote  5 ERROR: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=3, @fecha='2026-06-06 09:30:00', @forma_pago='Efectivo',      @id_tipo_1=@id_ext, @cantidad_1=2;                                            PRINT 'Lote  6 OK'; END TRY BEGIN CATCH PRINT 'Lote  6 ERROR: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=1, @fecha='2026-06-07 08:00:00', @forma_pago='Débito',        @id_tipo_1=@id_res, @cantidad_1=2, @id_tipo_2=@id_ext, @cantidad_2=1;       PRINT 'Lote  7 OK'; END TRY BEGIN CATCH PRINT 'Lote  7 ERROR: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=2, @fecha='2026-06-08 14:00:00', @forma_pago='QR',            @id_tipo_1=@id_res, @cantidad_1=1;                                            PRINT 'Lote  8 OK'; END TRY BEGIN CATCH PRINT 'Lote  8 ERROR: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=3, @fecha='2026-06-09 16:30:00', @forma_pago='Crédito',       @id_tipo_1=@id_ext, @cantidad_1=6;                                            PRINT 'Lote  9 OK'; END TRY BEGIN CATCH PRINT 'Lote  9 ERROR: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC ventas.Entrada_Nuevo @id_parque=@id_p, @pto_venta=1, @fecha='2026-06-10 10:00:00', @forma_pago='Efectivo',      @id_tipo_1=@id_res, @cantidad_1=3, @id_tipo_2=@id_ext, @cantidad_2=2;       PRINT 'Lote 10 OK'; END TRY BEGIN CATCH PRINT 'Lote 10 ERROR: '+ERROR_MESSAGE(); END CATCH
GO

SELECT e.id_entrada, e.nro_ticket, e.fecha, e.forma_pago, e.total,
       tv.descripcion AS tipo_visitante, tv2.cantidad, tv2.precio_unit, tv2.subtotal
FROM   ventas.Entrada e
JOIN   ventas.TicketVisitante tv2 ON tv2.id_ticket = e.id_entrada
JOIN   ventas.TipoVisitante   tv  ON tv.id_tipo_visitante = tv2.id_tipo_visitante
WHERE  e.estado = 0
ORDER BY e.id_entrada, tv.descripcion;
GO