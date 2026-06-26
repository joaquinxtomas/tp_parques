USE ParquesNacionales;
GO

--               ABM DE CONCESIONES

-- Empresa

CREATE OR ALTER PROCEDURE concesiones.Empresa_Nueva
    @razon_social VARCHAR(255),
    @cuit VARCHAR(20),
    @contacto VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF @razon_social IS NULL OR LTRIM(RTRIM(@razon_social)) = ''
        SET @v_errores = @v_errores + 'La razón social es obligatoria. ';

    IF @cuit IS NULL OR LTRIM(RTRIM(@cuit)) = ''
        SET @v_errores = @v_errores + 'El CUIT es obligatorio. ';

    IF EXISTS (SELECT 1 FROM concesiones.Empresa WHERE cuit = @cuit)
        SET @v_errores = @v_errores + 'El CUIT ya existe. ';

    IF @contacto IS NULL OR LTRIM(RTRIM(@contacto)) = ''
        SET @v_errores = @v_errores + 'El contacto es obligatorio. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    INSERT INTO concesiones.Empresa (razon_social, cuit, contacto)
    VALUES (@razon_social, @cuit, @contacto);
END
GO

CREATE OR ALTER PROCEDURE concesiones.Empresa_Modificar
    @id_empresa INT,
    @razon_social VARCHAR(255) = NULL,
    @cuit VARCHAR(20) = NULL,
    @contacto VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM concesiones.Empresa WHERE id_empresa = @id_empresa)
        SET @v_errores = @v_errores + 'La empresa no existe. ';

    IF EXISTS (SELECT 1 FROM concesiones.Empresa WHERE razon_social = @razon_social AND id_empresa <> @id_empresa)
        SET @v_errores = @v_errores + 'La razón social ya existe. ';

    IF EXISTS (SELECT 1 FROM concesiones.Empresa WHERE cuit = @cuit AND id_empresa <> @id_empresa)
        SET @v_errores = @v_errores + 'El CUIT ya existe. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    IF @razon_social IS NOT NULL        
        UPDATE concesiones.Empresa
        SET razon_social = @razon_social
        WHERE id_empresa = @id_empresa;

    IF @cuit IS NOT NULL
        UPDATE concesiones.Empresa
        SET cuit = @cuit
        WHERE id_empresa = @id_empresa;

    IF @contacto IS NOT NULL
        UPDATE concesiones.Empresa
        SET contacto = @contacto
        WHERE id_empresa = @id_empresa;
END
GO

CREATE OR ALTER PROCEDURE concesiones.Empresa_Eliminar
    @id_empresa INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM concesiones.Empresa WHERE id_empresa = @id_empresa)
        SET @v_errores = @v_errores + 'La empresa no existe. ';

    IF EXISTS (SELECT 1 FROM concesiones.Empresa where id_empresa = @id_empresa AND estado = 1)
        SET @v_errores = @v_errores + 'La empresa ya está deshabilitada. ';
    
    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    UPDATE concesiones.Empresa SET estado = 1 WHERE id_empresa = @id_empresa;

END
GO

-- Concesion

CREATE OR ALTER PROCEDURE concesiones.Concesion_Nueva
    @id_empresa INT,
    @id_parque INT,
    @tipo_actividad VARCHAR(100),
    @fecha_inicio DATE,
    @valor_alquiler DECIMAL(18, 2),
    @fecha_fin DATE = NULL
    
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM concesiones.Empresa WHERE id_empresa = @id_empresa AND estado = 0)
        SET @v_errores = @v_errores + 'La empresa no existe o está inactiva. ';
    
    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @id_parque)
        SET @v_errores = @v_errores + 'El parque no existe. ';

    IF @tipo_actividad IS NULL OR LTRIM(RTRIM(@tipo_actividad)) = ''
        SET @v_errores = @v_errores + 'El tipo de actividad es obligatorio. ';

    IF @fecha_inicio IS NULL
        SET @v_errores = @v_errores + 'La fecha de inicio es obligatoria. ';

    IF @fecha_fin IS NOT NULL AND @fecha_fin < @fecha_inicio
        SET @v_errores = @v_errores + 'La fecha de fin no puede ser anterior a la fecha de inicio. ';

    IF @valor_alquiler IS NULL OR @valor_alquiler <= 0
        SET @v_errores = @v_errores + 'El valor del alquiler es obligatorio y debe ser positivo. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    INSERT INTO concesiones.Concesion (id_empresa, id_parque, tipo_actividad, fecha_inicio, fecha_fin, valor_alquiler)
    VALUES (@id_empresa, @id_parque, @tipo_actividad, @fecha_inicio, @fecha_fin, @valor_alquiler);

END
GO

CREATE OR ALTER PROCEDURE concesiones.Concesion_Modificar
    @id_concesion INT,
    @tipo_actividad VARCHAR(100) = NULL,
    @fecha_inicio DATE = NULL,
    @fecha_fin DATE = NULL,
    @valor_alquiler DECIMAL(18, 2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM concesiones.Concesion WHERE id_concesion = @id_concesion)
        SET @v_errores = @v_errores + 'La concesión no existe. ';

    IF @fecha_inicio IS NOT NULL AND @fecha_fin IS NOT NULL AND @fecha_fin < @fecha_inicio
        SET @v_errores = @v_errores + 'La fecha de fin no puede ser anterior a la fecha de inicio. ';

    IF @valor_alquiler IS NOT NULL AND @valor_alquiler <= 0
        SET @v_errores = @v_errores + 'El valor del alquiler debe ser positivo. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    IF @tipo_actividad IS NOT NULL
        UPDATE concesiones.Concesion
        SET tipo_actividad = @tipo_actividad
        WHERE id_concesion = @id_concesion;

    IF @fecha_inicio IS NOT NULL
        UPDATE concesiones.Concesion
        SET fecha_inicio = @fecha_inicio
        WHERE id_concesion = @id_concesion;

    IF @fecha_fin IS NOT NULL
        UPDATE concesiones.Concesion
        SET fecha_fin = @fecha_fin
        WHERE id_concesion = @id_concesion;
    
    IF @valor_alquiler IS NOT NULL
        UPDATE concesiones.Concesion
        SET valor_alquiler = @valor_alquiler
        WHERE id_concesion = @id_concesion;

END
GO

CREATE OR ALTER PROCEDURE concesiones.Concesion_Eliminar
    @id_concesion INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM concesiones.Concesion WHERE id_concesion = @id_concesion)
        SET @v_errores = @v_errores + 'La concesión no existe. ';

    IF EXISTS (SELECT 1 FROM concesiones.Concesion where id_concesion = @id_concesion AND estado = 1)
        SET @v_errores = @v_errores + 'La concesión ya está deshabilitada. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    UPDATE concesiones.Concesion SET estado = 1 WHERE id_concesion = @id_concesion;
END
GO

-- PagoConcesion

CREATE OR ALTER PROCEDURE concesiones.PagoConcesion_Nuevo
    @id_concesion INT,
    @fecha_pago DATE,
    @periodo DATE,
    @monto DECIMAL(18, 2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';
    
    SET @periodo = DATEFROMPARTS(YEAR(@periodo), MONTH(@periodo), 1);

    IF NOT EXISTS (SELECT 1 FROM concesiones.Concesion WHERE id_concesion = @id_concesion AND estado = 0)
        SET @v_errores = @v_errores + 'La concesión no existe o está inactiva. ';

    IF @fecha_pago IS NULL
        SET @v_errores = @v_errores + 'La fecha de pago es obligatoria. ';

    IF @periodo IS NULL
        SET @v_errores = @v_errores + 'El período es obligatorio. ';

    IF EXISTS (SELECT 1 FROM concesiones.PagoConcesion WHERE id_concesion = @id_concesion AND periodo = @periodo)
        SET @v_errores = @v_errores + 'Ya existe un pago para este período. ';

    -- Cambiar por mayor o igual a 0 si se permiten pagos de $0
    IF @monto IS NULL OR @monto <= 0
        SET @v_errores = @v_errores + 'El monto es obligatorio y debe ser positivo. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    INSERT INTO concesiones.PagoConcesion (id_concesion, fecha_pago, periodo, monto)
    VALUES (@id_concesion, @fecha_pago, @periodo, @monto);
END
GO

CREATE OR ALTER PROCEDURE concesiones.PagoConcesion_Modificar
    @id_pago INT,
    @fecha_pago DATE = NULL,
    @periodo DATE = NULL,
    @monto DECIMAL(18, 2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM concesiones.PagoConcesion WHERE id_pago = @id_pago)
        SET @v_errores = @v_errores + 'El pago de concesión no existe. ';

    IF @monto IS NOT NULL AND @monto <= 0
        SET @v_errores = @v_errores + 'El monto debe ser positivo. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    IF @fecha_pago IS NOT NULL
        UPDATE concesiones.PagoConcesion
        SET fecha_pago = @fecha_pago
        WHERE id_pago = @id_pago;

    IF @periodo IS NOT NULL
    BEGIN
        SET @periodo = DATEFROMPARTS(YEAR(@periodo), MONTH(@periodo), 1);
        UPDATE concesiones.PagoConcesion
        SET periodo = @periodo
        WHERE id_pago = @id_pago;
    END

    IF @monto IS NOT NULL
        UPDATE concesiones.PagoConcesion
        SET monto = @monto  
        WHERE id_pago = @id_pago;
END
GO

CREATE OR ALTER PROCEDURE concesiones.PagoConcesion_Eliminar
    @id_pago INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM concesiones.PagoConcesion WHERE id_pago = @id_pago)
        SET @v_errores = @v_errores + 'El pago de concesión no existe. ';

    IF EXISTS (SELECT 1 FROM concesiones.PagoConcesion where id_pago = @id_pago AND estado = 1)
        SET @v_errores = @v_errores + 'El pago de concesión ya está deshabilitado. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    UPDATE concesiones.PagoConcesion SET estado = 1 WHERE id_pago = @id_pago;
END
GO


-- Ventas

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