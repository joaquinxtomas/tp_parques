--              USAR PARQUESNACIONALES

USE ParquesNacionales;
GO

--              AMB

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
    ELSE IF LEN(LTRIM(RTRIM(@cuit))) > 11
        SET @v_errores = @v_errores + 'El CUIT es inválido (ingresarlo sin guiones, 11 dígitos). ';
    ELSE IF EXISTS (SELECT 1 FROM concesiones.Empresa WHERE cuit = @cuit)
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

    IF @cuit IS NOT NULL AND LEN(LTRIM(RTRIM(@cuit))) > 11
        SET @v_errores = @v_errores + 'El CUIT es inválido (ingresarlo sin guiones, 11 dígitos). ';
    ELSE IF @cuit IS NOT NULL AND EXISTS (SELECT 1 FROM concesiones.Empresa WHERE cuit = @cuit AND id_empresa <> @id_empresa)
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


--====================================================================================
--									ABM TiposDeParques
--====================================================================================

CREATE OR ALTER PROCEDURE parques.InsertarTipoDeParque	--	ALTA
    @descripcion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = ''
        SET @v_errores += 'La descripcion es obligatoria. ';

    IF EXISTS (SELECT 1 FROM parques.TipoParque WHERE descripcion = @descripcion AND estado = 0)
        SET @v_errores += 'Ya existe un tipo de parque activo con esa descripcion. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END
	IF EXISTS (SELECT 1 from Parques.TipoParque WHERE descripcion = @descripcion and estado =1)
		UPDATE parques.TipoParque SET estado = 0 WHERE descripcion = @descripcion;
    ELSE
		INSERT INTO parques.TipoParque (descripcion) VALUES (@descripcion);
END
GO

CREATE OR ALTER PROCEDURE parques.ModificarTipoDeParque	--	MODIFICACION
    @id_tipo_parque INT,
    @descripcion    VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM parques.TipoParque WHERE id_tipo_parque = @id_tipo_parque AND estado = 0)
        SET @v_errores += 'El tipo de parque no existe o esta dado de baja. ';

    IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = ''
        SET @v_errores += 'La descripcion es obligatoria. ';

    IF EXISTS (SELECT 1 FROM parques.TipoParque
               WHERE descripcion = @descripcion AND id_tipo_parque <> @id_tipo_parque AND estado = 0)
        SET @v_errores += 'Otro tipo de parque ya usa esa descripcion. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    UPDATE parques.TipoParque
    SET descripcion = @descripcion
    WHERE id_tipo_parque = @id_tipo_parque;
END
GO

CREATE OR ALTER PROCEDURE parques.EliminarTipoDeParque	--	BAJA (logica)
    @id_tipo_parque INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM parques.TipoParque WHERE id_tipo_parque = @id_tipo_parque)
        SET @v_errores += 'El tipo de parque no existe. ';

    IF EXISTS (SELECT 1 FROM parques.TipoParque WHERE id_tipo_parque = @id_tipo_parque AND estado = 1)
        SET @v_errores += 'El tipo de parque ya esta dado de baja. ';

    IF EXISTS (SELECT 1 FROM parques.Parque WHERE id_tipo_parque = @id_tipo_parque AND estado = 0)
        SET @v_errores += 'No se puede eliminar: hay parques activos que usan este tipo. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END
    UPDATE parques.TipoParque SET estado = 1 WHERE id_tipo_parque = @id_tipo_parque;
END
GO


--====================================================================================
--									ABM PARQUES
--====================================================================================

CREATE OR ALTER PROCEDURE parques.InsertarParque --	ALTA
    @nombre         VARCHAR(100),
    @id_tipo_parque INT,
    @region         VARCHAR(100) = NULL, --son opcionales, por defecto valen NULL
    @provincia      VARCHAR(100) = NULL,
	@latitud        DECIMAL(9,6) = NULL,
    @longitud       DECIMAL(9,6) = NULL,
    @superficie     DECIMAL(12,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = ''; --declaro cadena donde junto todos los errores

    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        SET @v_errores += 'El nombre es obligatorio. ';

    IF EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = @nombre AND estado = 0)
        SET @v_errores += 'Ya existe un parque activo con ese nombre. ';

    IF NOT EXISTS (SELECT 1 FROM parques.TipoParque WHERE id_tipo_parque = @id_tipo_parque AND estado = 0)
        SET @v_errores += 'El tipo de parque no existe o esta dado de baja. ';

    IF @superficie IS NOT NULL AND @superficie <= 0
        SET @v_errores += 'La superficie debe ser mayor a cero. ';

    IF (@latitud IS NULL AND @longitud IS NOT NULL)
       OR (@latitud IS NOT NULL AND @longitud IS NULL)
        SET @v_errores += 'Debe indicar latitud y longitud juntas, o ninguna. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1); -- muestro la cadena de errores y corto
        RETURN;
    END

    INSERT INTO parques.Parque (nombre, id_tipo_parque, provincia, region, latitud, longitud, superficie)
    VALUES (@nombre, @id_tipo_parque, @provincia, @region, @latitud, @longitud, @superficie);
END
GO

CREATE OR ALTER PROCEDURE parques.ModificarParque --	MODIFICACION
    @id_parque      INT,
    @nombre         VARCHAR(100),
    @id_tipo_parque INT,
	@provincia         VARCHAR(100) = NULL,
    @region         VARCHAR(100) = NULL,
    @latitud        DECIMAL(9,6) = NULL,
    @longitud       DECIMAL(9,6) = NULL,
    @superficie     DECIMAL(12,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @id_parque AND estado = 0)
        SET @v_errores += 'El parque no existe o esta dado de baja. ';

    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        SET @v_errores += 'El nombre es obligatorio. ';

    IF EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = @nombre AND id_parque <> @id_parque)
        SET @v_errores += 'Otro parque ya usa ese nombre. ';

    IF NOT EXISTS (SELECT 1 FROM parques.TipoParque WHERE id_tipo_parque = @id_tipo_parque AND estado = 0)
        SET @v_errores += 'El tipo de parque no existe o esta dado de baja. ';

    IF @superficie IS NOT NULL AND @superficie <= 0
        SET @v_errores += 'La superficie debe ser mayor a cero. ';

    IF (@latitud IS NULL AND @longitud IS NOT NULL)
       OR (@latitud IS NOT NULL AND @longitud IS NULL)
        SET @v_errores += 'Debe indicar latitud y longitud juntas, o ninguna. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    UPDATE parques.Parque
    SET nombre = @nombre,
        id_tipo_parque = @id_tipo_parque,
        provincia = @provincia,
        region = @region,
        latitud = @latitud,
        longitud = @longitud,
        superficie = @superficie
    WHERE id_parque = @id_parque;
END
GO

CREATE OR ALTER PROCEDURE parques.EliminarParque	-- BAJA (logica)
    @id_parque INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @id_parque)
        SET @v_errores += 'El parque no existe. ';

    IF EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @id_parque AND estado = 1)
        SET @v_errores += 'El parque ya esta dado de baja. ';

    IF EXISTS (SELECT 1 FROM actividades.Atraccion WHERE id_parque = @id_parque AND estado = 0)
        SET @v_errores += 'No se puede eliminar: el parque tiene atracciones activas. ';

    IF EXISTS (SELECT 1 FROM ventas.Entrada WHERE id_parque = @id_parque AND estado = 0)
        SET @v_errores += 'No se puede eliminar: el parque tiene ventas activas. ';

    IF EXISTS (SELECT 1 FROM concesiones.Concesion WHERE id_parque = @id_parque AND estado = 0)
        SET @v_errores += 'No se puede eliminar: el parque tiene concesiones activas. ';

    IF EXISTS (SELECT 1 FROM personal.AsignacionGP WHERE id_parque = @id_parque AND estado = 0)
        SET @v_errores += 'No se puede eliminar: el parque tiene asignaciones de personal activas. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    UPDATE parques.Parque SET estado = 1 WHERE id_parque = @id_parque;
END
GO

---------------------------------------------------------------------------
-------------------------------- Personal----------------------------------
---------------------------------------------------------------------------
---------------------------- ABM Asignaciones -----------------------------
---------------------------------------------------------------------------
-- Alta
CREATE OR ALTER PROCEDURE personal.asignacionGP_alta
    @id_guardaparque int,
    @id_parque int,
    @id_guia int,
    @fecha_desde date,
    @fecha_hasta date,
    @motivo varchar(255)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';
    
    IF @id_parque IS NULL
        SET @v_errores += 'La id del parque es obligatoria. ';
    ELSE
        IF not exists (select 1 from parques.Parque where id_parque = @id_parque)
            set @v_errores += 'No existe el parque seleccionado. ';
    IF @id_guardaparque IS NULL
        SET @v_errores += 'La id del guardaparque es obligatoria. ';
    ELSE
        IF not exists (select 1 from personal.Guardaparque where id_guardaparque = @id_guardaparque)
            set @v_errores += 'No existe el guardaparque seleccionado. ';
    IF @id_guia IS not NULL
        IF not exists (select 1 from personal.GuiaAutorizado where id_guia = @id_guia)
            set @v_errores += 'No existe el guía seleccionado. ';
    IF @fecha_desde IS NULL
        SET @v_errores += 'La fecha de comienzo es obligatoria. ';

    IF EXISTS (SELECT 1 FROM personal.AsignacionGP WHERE id_guardaparque = @id_guardaparque and id_parque = @id_parque and fecha_desde = @fecha_desde)
        SET @v_errores += 'Ya existe la asignación del guardaparque en este parque para la fecha indicada. ';
            
    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    INSERT INTO personal.AsignacionGP(id_guardaparque, id_parque, id_guia, fecha_desde, fecha_hasta, motivo)
    VALUES (@id_guardaparque, @id_parque, @id_guia, @fecha_desde, @fecha_hasta, @motivo);
END
GO
-- Baja
CREATE OR ALTER PROCEDURE personal.asignacionGP_baja
    @id_asignacion int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';
    declare @fecha_hasta date;
    
    IF NOT EXISTS (select 1 from personal.AsignacionGP where id_asignacion = @id_asignacion)
        SET @v_errores += 'No se encontró la asignación solicitada. ';
/*
    IF @id_parque IS NULL
        SET @v_errores += 'La id del parque es obligatoria. ';
    ELSE
        IF not exists (select 1 from parques.Parque where id_parque = @id_parque)
            set @v_errores += 'No existe el parque seleccionado. ';

    IF @fecha_desde IS NULL
        SET @v_errores += 'La fecha de comienzo es obligatoria. ';
    
    IF @id_guardaparque IS NULL
        SET @v_errores += 'La id del guardaparque es obligatoria. ';
    ELSE
        IF not exists (select 1 from personal.Guardaparque where id_guardaparque = @id_guardaparque)
            set @v_errores += 'No existe el guardaparque seleccionado. ';
    IF @id_guia IS not NULL
        IF not exists (select 1 from personal.GuiaAutorizado where id_guia = @id_guia)
            set @v_errores += 'No existe el guía seleccionado. ';
   

    IF EXISTS (SELECT 1 FROM personal.AsignacionGP WHERE id_guardaparque = @id_guardaparque and id_parque = @id_parque and fecha_desde = @fecha_desde)
        SET @v_errores += 'Ya existe la asignación del guardaparque en este parque para la fecha indicada. ';
  */          
    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END
    set @fecha_hasta = GETDATE();
    UPDATE personal.AsignacionGP SET fecha_hasta = @fecha_hasta where id_asignacion = @id_asignacion
END
GO
-- Modificación
CREATE OR ALTER PROCEDURE personal.asignacionGP_modificacion
    @id_asignacion int,
    @id_guardaparque int,
    @id_parque int,
    @id_guia int,
    @fecha_desde date,
    @fecha_hasta date,
    @motivo varchar(255)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';
    
    IF NOT EXISTS (select 1 from personal.AsignacionGP where id_asignacion = @id_asignacion)
        SET @v_errores += 'No se encontró la asignación solicitada. ';

    IF @id_parque IS NULL
        SET @v_errores += 'La id del parque es obligatoria. ';
    ELSE
        IF not exists (select 1 from parques.Parque where id_parque = @id_parque)
            set @v_errores += 'No existe el parque seleccionado. ';

    IF @fecha_desde IS NULL
        SET @v_errores += 'La fecha de comienzo es obligatoria. ';

    IF @id_guardaparque IS NULL
        IF not exists (select 1 from personal.Guardaparque where id_guardaparque = @id_guardaparque)
            set @v_errores += 'No existe el guardaparque seleccionado. ';
    
    IF @id_guia IS not NULL
        IF not exists (select 1 from personal.GuiaAutorizado where id_guia = @id_guia)
            set @v_errores += 'No existe el guía seleccionado. ';  
         
    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END
    UPDATE personal.AsignacionGP SET id_guardaparque = @id_guardaparque, id_parque = @id_parque, id_guia = @id_guia, fecha_desde = @fecha_desde, fecha_hasta = @fecha_hasta, motivo = @motivo where id_asignacion = @id_asignacion
END
GO
---------------------------------------------------------------------------
--------------------------- ABM Guardaparques -----------------------------
---------------------------------------------------------------------------
-- Alta
CREATE OR ALTER PROCEDURE personal.guardaparque_alta
    @nombre varchar(100),
    @dni varchar(10),
    @vigencia_desde date,
    @vigencia_hasta date
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';
    DECLARE @activo bit = 1;

    -- Chequeo que el guardaparque no esté cargado

    IF EXISTS (SELECT 1 FROM personal.Guardaparque WHERE dni = @dni and nombre = @nombre)
        SET @v_errores += 'Ya existe el guardaparque. ';
            
    -- Chequeo que los campos obligatorios tengan información para cargar

    IF @nombre IS NULL
        SET @v_errores += 'El nombre del guardaparque es obligatorio. ';
    
    IF @dni IS NULL
        SET @v_errores += 'El DNI del guardaparque es obligatorio. ';
  
    IF @vigencia_desde IS NULL
        SET @v_errores += 'La fecha de vigencia inicial es obligatoria. ';

    -- En caso de error, salgo y muestro el log

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    -- Inserto el guardaparque con los datos recibidos y el campo activo por defecto en 1

    INSERT INTO personal.Guardaparque(nombre, dni, vigencia_desde, vigencia_hasta, activo)
    VALUES (@nombre, @dni, @vigencia_desde, @vigencia_hasta, @activo);
END
GO
-- Baja
CREATE OR ALTER PROCEDURE personal.guardaparque_baja
    @id_guardaparque int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';
    DECLARE @activo bit = 0;

    -- Chequeo que exista el guardaparque
    
     IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE id_guardaparque = @id_guardaparque)
        SET @v_errores += 'No se encontró el guardaparque. ';
            
    -- Salgo con error si no lo encuentro
    
    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    -- Actializo al campo activo para la baja lógica

    update personal.Guardaparque set activo = @activo where id_guardaparque = @id_guardaparque
END
GO
-- Modificacion
CREATE OR ALTER PROCEDURE personal.guardaparque_modificacion
    @id_guardaparque int,
    @nombre varchar(100),
    @dni varchar(10),
    @vigencia_desde date,
    @vigencia_hasta date
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    -- Chequeo que exista el guardaparque
    
    IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE id_guardaparque = @id_guardaparque)
        SET @v_errores += 'No se encontró el guardaparque. ';
    
    -- Chequeo que los campos no nulos se hayan ingresado

    IF @nombre IS NULL
        SET @v_errores += 'El nombre del guardaparque es obligatorio. ';
    
    IF @dni IS NULL
        SET @v_errores += 'El DNI del guardaparque es obligatorio. ';
  
    IF @vigencia_desde IS NULL
        SET @v_errores += 'La fecha de vigencia inicial es obligatoria. ';

    -- Si hubo errores salgo con el log correspondiente
    
    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    -- Actualizo el guardaparque con los datos recibidos

    update personal.Guardaparque 
    set nombre = @nombre, dni = @dni, vigencia_desde = @vigencia_desde, vigencia_hasta = @vigencia_hasta 
    where id_guardaparque = @id_guardaparque
END
GO
---------------------------------------------------------------------------
--------------------------------- ABM Guías -------------------------------
---------------------------------------------------------------------------
-- Alta
CREATE OR ALTER PROCEDURE personal.guiaAutorizado_alta
    @nombre varchar(100),
    @dni varchar(10),
    @especialidad varchar(100),
    @titulo varchar(100),
    @vigencia_desde date,
    @vigencia_hasta date
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';
    DECLARE @activo bit = 1;
    -- Chequeo que no exista el guía que se quiere cargar
    
    IF EXISTS (SELECT 1 FROM personal.Guardaparque WHERE dni = @dni and nombre = @nombre)
        SET @v_errores += 'Ya existe el guía. ';

    -- Chequeo que los campos obligatorios se hayan recibido
    IF @nombre IS NULL
        SET @v_errores += 'El nombre del guía es obligatorio. ';
    
    IF @dni IS NULL
        SET @v_errores += 'El DNI del guía es obligatorio. ';
  
    IF @vigencia_desde IS NULL
        SET @v_errores += 'La fecha de comienzo es obligatoria. ';

    -- Salgo con error en caso de existir
    
    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    -- 

    INSERT INTO personal.GuiaAutorizado(nombre, dni, especialidad, titulo, vigencia_desde, vigencia_hasta, activo)
    VALUES (@nombre, @dni, @especialidad, @titulo, @vigencia_desde, @vigencia_hasta, @activo);
END
GO
-- Baja
CREATE OR ALTER PROCEDURE personal.guia_baja
    @id_guia int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    -- Chequeo que exista el guía
    
     IF NOT EXISTS (SELECT 1 FROM personal.GuiaAutorizado WHERE id_guia = @id_guia)
        SET @v_errores += 'No se encontró el guía. ';
       
    -- Salgo con error en caso de no encontrar el guía  
      
    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    -- Actualizo ek campo activo para una baja lógica

    update personal.GuiaAutorizado set activo = 0 where id_guia = @id_guia
END
GO
-- Modificación
CREATE OR ALTER PROCEDURE personal.guia_modificacion
    @id_guia int,
    @nombre varchar(100),
    @dni varchar(10),
    @especialidad varchar(100),
    @titulo varchar(100),
    @vigencia_desde date,
    @vigencia_hasta date
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    -- Chequeo que existía el guía que se quiere modificar
    
     IF NOT EXISTS (SELECT 1 FROM personal.GuiaAutorizado WHERE id_guia = @id_guia)
        SET @v_errores += 'No se encontró el guía. ';
            
    -- Chequeo que se hayan enviado los campos que no se pueden dejar como nulos

    IF @nombre IS NULL
        SET @v_errores += 'El nombre del guía es obligatorio. ';
    
    IF @dni IS NULL
        SET @v_errores += 'El DNI del guía es obligatorio. ';
  
    IF @vigencia_desde IS NULL
        SET @v_errores += 'La fecha de vigencia inicial es obligatoria. ';

   -- Salgo con los errores en caso de existir
   
   IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    -- Actualizo el registro con los datos recibidos

    update personal.GuiaAutorizado 
    set nombre = @nombre, dni = @dni, especialidad = @especialidad, titulo = @titulo, vigencia_desde = @vigencia_desde, vigencia_hasta = @vigencia_hasta 
    where id_guia = @id_guia
END
GO