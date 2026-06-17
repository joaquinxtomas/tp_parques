--	16/06/2026
--  INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
--  Descripcion: Creacion de los STORED PROCEDURES de las operaciones ABM en tipos de ventas

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

    IF EXISTS (SELECT 1 FROM ventas.Ticket WHERE id_tipo_visitante = @id_tipo_visitante)
        SET @v_errores += 'No se puede eliminar: el tipo de visitante tiene tickets registrados. ';

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

    IF NOT EXISTS (SELECT 1 FROM ParquesNacionales.Parque WHERE id_parque = @id_parque)
        SET @v_errores += 'El parque no existe. ';

    IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id_tipo_visitante = @id_tipo_visitante)
        SET @v_errores += 'El tipo de visitante no existe. ';

    IF @precio IS NULL OR @precio < 0
        SET @v_errores += 'El precio debe ser un valor positivo. ';

    IF EXISTS (SELECT 1 FROM ventas.PrecioEntrada
                WHERE id_parque = @id_parque AND id_tipo_visitante = @id_tipo_visitante)
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

    IF NOT EXISTS (SELECT 1 FROM ParquesNacionales.Parque WHERE id_parque = @id_parque)
        SET @v_errores += 'El parque no existe. ';

    IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id_tipo_visitante = @id_tipo_visitante)
        SET @v_errores += 'El tipo de visitante no existe. ';

    IF @precio IS NULL OR @precio < 0
        SET @v_errores += 'El precio debe ser un valor positivo. ';

    IF EXISTS (SELECT 1 FROM ventas.PrecioEntrada WHERE id_parque = @id_parque AND id_tipo_visitante = @id_tipo_visitante)
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
    @id_precio_entrada INT,
    @precio DECIMAL(10, 2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM ventas.PrecioEntrada WHERE id_precio_entrada = @id_precio_entrada)
        SET @v_errores += 'El precio de entrada no existe. ';

    IF @precio IS NULL OR @precio < 0
        SET @v_errores += 'El precio debe ser un valor positivo. ';

    IF EXISTS (SELECT 1 FROM ventas.PrecioEntrada WHERE id_precio_entrada = @id_precio_entrada AND estado = 1)
        SET @v_errores += 'El precio de entrada está dado de baja. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    UPDATE ventas.PrecioEntrada SET precio = @precio WHERE id_precio_entrada = @id_precio_entrada;
END
GO

CREATE OR ALTER PROCEDURE ventas.PrecioEntrada_Eliminar    --	BAJA
    @id_precio_entrada INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM ventas.PrecioEntrada WHERE id_precio_entrada = @id_precio_entrada)
        SET @v_errores += 'El precio de entrada no existe. ';

    IF EXISTS (SELECT 1 FROM ventas.PrecioEntrada WHERE id_precio_entrada = @id_precio_entrada AND estado = 1)
        SET @v_errores += 'El precio de entrada ya está dado de baja. ';

    IF EXISTS (SELECT 1 FROM ventas.Ticket WHERE id_precio_entrada = @id_precio_entrada)
        SET @v_errores += 'No se puede eliminar: el precio de entrada tiene tickets registrados. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    UPDATE ventas.PrecioEntrada SET estado = 1 WHERE id_precio_entrada = @id_precio_entrada;
    UPDATE ventas.precioEntrada SET fecha_fin = GETDATE() WHERE id_precio_entrada = @id_precio_entrada;
END
GO

-- Tickets