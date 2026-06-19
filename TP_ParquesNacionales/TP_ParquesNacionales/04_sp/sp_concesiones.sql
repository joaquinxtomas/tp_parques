--	18/06/2026
--  INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
--  Descripcion: Creacion de los STORED PROCEDURES de las operaciones ABM en tipos de concesiones

USE ParquesNacionales;
GO

--               ABM DE CONCESIONES

-- Empresa

CREATE OR ALTER PROCEDURE consesiones.Empresa_Nueva
    @razon_social VARCHAR(255),
    @cuit VARCHAR(20),
    @contrato VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF @razon_social IS NULL OR LTRIM(RTRIM(@razon_social)) = ''
        SET @v_errores = @v_errores + 'La razón social es obligatoria. ';

    IF @cuit IS NULL OR LTRIM(RTRIM(@cuit)) = ''
        SET @v_errores = @v_errores + 'El CUIT es obligatorio. ';

    IF EXISTS (SELECT 1 FROM consesiones.Empresa WHERE cuit = @cuit)
        SET @v_errores = @v_errores + 'El CUIT ya existe. ';

    IF @contrato IS NULL OR LTRIM(RTRIM(@contrato)) = ''
        SET @v_errores = @v_errores + 'El contrato es obligatorio. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    INSERT INTO consesiones.Empresa (razon_social, cuit, contrato)
    VALUES (@razon_social, @cuit, @contrato);
END
GO

CREATE OR ALTER PROCEDURE consesiones.Empresa_Modificar
    @id_empresa INT,
    @razon_social VARCHAR(255) = NULL,
    @cuit VARCHAR(20) = NULL,
    @contrato VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM consesiones.Empresa WHERE id_empresa = @id_empresa)
        SET @v_errores = @v_errores + 'La empresa no existe. ';

    IF EXISTS (SELECT 1 FROM consesiones.Empresa WHERE razon_social = @razon_social AND id_empresa <> @id_empresa)
        SET @v_errores = @v_errores + 'La razón social ya existe. ';

    IF EXISTS (SELECT 1 FROM consesiones.Empresa WHERE cuit = @cuit AND id_empresa <> @id_empresa)
        SET @v_errores = @v_errores + 'El CUIT ya existe. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    IF @razon_social IS NOT NULL        
        UPDATE consesiones.Empresa
        SET razon_social = @razon_social
        WHERE id_empresa = @id_empresa;

    IF @cuit IS NOT NULL
        UPDATE consesiones.Empresa
        SET cuit = @cuit
        WHERE id_empresa = @id_empresa;

    IF @contrato IS NOT NULL
        UPDATE consesiones.Empresa
        SET contrato = @contrato
        WHERE id_empresa = @id_empresa;
END
GO

CREATE OR ALTER PROCEDURE consesiones.Empresa_Eliminar
    @id_empresa INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM consesiones.Empresa WHERE id_empresa = @id_empresa)
        SET @v_errores = @v_errores + 'La empresa no existe. ';
    
    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    UPDATE consesiones.Empresa SET estado = 1 WHERE id_empresa = @id_empresa;

END
GO

-- Concesion

CREATE OR ALTER PROCEDURE consesiones.Concesion_Nueva
    @id_empresa INT,
    @id_parque INT,
    @tipo_actividad VARCHAR(100),
    @fecha_inicio DATE,
    @fecha_fin DATE = NULL,
    @valor_alquiler DECIMAL(18, 2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM consesiones.Empresa WHERE id_empresa = @id_empresa AND estado = 0)
        SET @v_errores = @v_errores + 'La empresa no existe o está inactiva. ';
    
    IF NOT EXISTS (SELECT 1 FROM ParquesNacionales.Parque WHERE id_parque = @id_parque)
        SET @v_errores = @v_errores + 'El parque no existe. ';

    IF @tipo_actividad IS NULL OR LTRIM(RTRIM(@tipo_actividad)) = ''
        SET @v_errores = @v_errores + 'El tipo de actividad es obligatorio. ';

    IF @fecha_inicio IS NULL
        SET @v_errores = @v_errores + 'La fecha de inicio es obligatoria. ';

    IF @fecha_fin IS NOT NULL AND @fecha_fin < @fecha_inicio
        SET @v_errores = @v_errores + 'La fecha de fin no puede ser anterior a la fecha de inicio. ';

    IF @valor_alquiler IS NOT NULL AND @valor_alquiler < 0
        SET @v_errores = @v_errores + 'El valor del alquiler es obligatorio y debe ser positivo. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    INSERT INTO consesiones.Concesion (id_empresa, id_parque, tipo_actividad, fecha_inicio, fecha_fin, valor_alquiler)
    VALUES (@id_empresa, @id_parque, @tipo_actividad, @fecha_inicio, @fecha_fin, @valor_alquiler);
END
GO

CREATE OR ALTER PROCEDURE consesiones.Concesion_Modificar
    @id_concesion INT,
    @tipo_actividad VARCHAR(100) = NULL,
    @fecha_inicio DATE = NULL,
    @fecha_fin DATE = NULL,
    @valor_alquiler DECIMAL(18, 2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM consesiones.Concesion WHERE id_concesion = @id_concesion)
        SET @v_errores = @v_errores + 'La concesión no existe. ';

    IF @fecha_inicio IS NOT NULL AND @fecha_fin IS NOT NULL AND @fecha_fin < @fecha_inicio
        SET @v_errores = @v_errores + 'La fecha de fin no puede ser anterior a la fecha de inicio. ';

    IF @valor_alquiler IS NOT NULL AND @valor_alquiler < 0
        SET @v_errores = @v_errores + 'El valor del alquiler debe ser positivo. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    IF @tipo_actividad IS NOT NULL
        UPDATE consesiones.Concesion
        SET tipo_actividad = @tipo_actividad
        WHERE id_concesion = @id_concesion;

    IF @fecha_inicio IS NOT NULL
        UPDATE consesiones.Concesion
        SET fecha_inicio = @fecha_inicio
        WHERE id_concesion = @id_concesion;

    IF @fecha_fin IS NOT NULL
        UPDATE consesiones.Concesion
        SET fecha_fin = @fecha_fin
        WHERE id_concesion = @id_concesion;
    
    IF @valor_alquiler IS NOT NULL
        UPDATE consesiones.Concesion
        SET valor_alquiler = @valor_alquiler
        WHERE id_concesion = @id_concesion;

END
GO

CREATE OR ALTER PROCEDURE consesiones.Concesion_Eliminar
    @id_concesion INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM consesiones.Concesion WHERE id_concesion = @id_concesion)
        SET @v_errores = @v_errores + 'La concesión no existe. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    UPDATE consesiones.Concesion SET estado = 1 WHERE id_concesion = @id_concesion;
END
GO

-- PagoConcesion

CREATE OR ALTER PROCEDURE consesiones.PagoConcesion_Nuevo
    @id_concesion INT,
    @fecha_pago DATE,
    @periodo DATE,
    @monto DECIMAL(18, 2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM consesiones.Concesion WHERE id_concesion = @id_concesion AND estado = 0)
        SET @v_errores = @v_errores + 'La concesión no existe o está inactiva. ';

    IF @fecha_pago IS NULL
        SET @v_errores = @v_errores + 'La fecha de pago es obligatoria. ';

    IF @periodo IS NULL
        SET @v_errores = @v_errores + 'El período es obligatorio. ';

    IF @monto IS NULL OR @monto < 0
        SET @v_errores = @v_errores + 'El monto es obligatorio y debe ser positivo. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    INSERT INTO consesiones.PagoConcesion (id_concesion, fecha_pago, periodo, monto)
    VALUES (@id_concesion, @fecha_pago, @periodo, @monto);
END
GO

CREATE OR ALTER PROCEDURE consesiones.PagoConcesion_Modificar
    @id_pago_concesion INT,
    @fecha_pago DATE = NULL,
    @periodo DATE = NULL,
    @monto DECIMAL(18, 2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM consesiones.PagoConcesion WHERE id_pago_concesion = @id_pago_concesion)
        SET @v_errores = @v_errores + 'El pago de concesión no existe. ';

    IF @monto IS NOT NULL AND @monto < 0
        SET @v_errores = @v_errores + 'El monto debe ser positivo. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    IF @fecha_pago IS NOT NULL
        UPDATE consesiones.PagoConcesion
        SET fecha_pago = @fecha_pago
        WHERE id_pago_concesion = @id_pago_concesion;

    IF @periodo IS NOT NULL
        UPDATE consesiones.PagoConcesion
        SET periodo = @periodo
        WHERE id_pago_concesion = @id_pago_concesion;

    IF @monto IS NOT NULL
        UPDATE consesiones.PagoConcesion
        SET monto = @monto  
        WHERE id_pago_concesion = @id_pago_concesion;
END
GO

CREATE OR ALTER PROCEDURE consesiones.PagoConcesion_Eliminar
    @id_pago_concesion INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_errores VARCHAR(MAX) = '';

    IF NOT EXISTS (SELECT 1 FROM consesiones.PagoConcesion WHERE id_pago_concesion = @id_pago_concesion)
        SET @v_errores = @v_errores + 'El pago de concesión no existe. ';

    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    UPDATE consesiones.PagoConcesion SET estado = 1 WHERE id_pago_concesion = @id_pago_concesion;
END
GO