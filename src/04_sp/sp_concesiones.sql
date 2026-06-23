--	18/06/2026
--  INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
--  Descripcion: Creacion de los STORED PROCEDURES de las operaciones ABM en tipos de concesiones

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
-- Empresa_Nueva
-- ============================================================

-- CASO 1: razon_social vacía → error
BEGIN TRY
    EXEC concesiones.Empresa_Nueva @razon_social = '', @cuit = '30714591230', @contacto = 'info@empresa.com';
    PRINT 'CASO 1 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 1 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 2: cuit NULL → error
BEGIN TRY
    EXEC concesiones.Empresa_Nueva @razon_social = 'Empresa Test', @cuit = NULL, @contacto = 'info@empresa.com';
    PRINT 'CASO 2 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 2 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 3: contacto NULL → error
BEGIN TRY
    EXEC concesiones.Empresa_Nueva @razon_social = 'Empresa Test', @cuit = '30714591230', @contacto = NULL;
    PRINT 'CASO 3 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 3 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 4: altas correctas (3 empresas para los tests siguientes)
BEGIN TRY
    EXEC concesiones.Empresa_Nueva @razon_social = 'Patagonia Aventuras SA',    @cuit = '30714591230', @contacto = 'info@aventuras.com';
    PRINT 'CASO 4a OK';
END TRY
BEGIN CATCH
    PRINT 'CASO 4a: ' + ERROR_MESSAGE();
END CATCH
GO
BEGIN TRY
    EXEC concesiones.Empresa_Nueva @razon_social = 'Servicios Turisticos SRL',  @cuit = '30714591241', @contacto = 'servicios@turismo.com';
    PRINT 'CASO 4b OK';
END TRY
BEGIN CATCH
    PRINT 'CASO 4b: ' + ERROR_MESSAGE();
END CATCH
GO
BEGIN TRY
    EXEC concesiones.Empresa_Nueva @razon_social = 'Gastronomia del Sur SA',    @cuit = '30714591252', @contacto = 'admin@gastrosur.com';
    PRINT 'CASO 4c OK';
END TRY
BEGIN CATCH
    PRINT 'CASO 4c: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 5: cuit duplicado → error
BEGIN TRY
    EXEC concesiones.Empresa_Nueva @razon_social = 'Otra Empresa SRL', @cuit = '30714591230', @contacto = 'otro@empresa.com';
    PRINT 'CASO 5 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 5 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

SELECT id_empresa, razon_social, cuit, estado FROM concesiones.Empresa;
GO


-- ============================================================
-- Empresa_Modificar
-- ============================================================

-- CASO 6: empresa inexistente → error
BEGIN TRY
    EXEC concesiones.Empresa_Modificar @id_empresa = 9999, @razon_social = 'X';
    PRINT 'CASO 6 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 6 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 7: razon_social ya usada por otra empresa → error
BEGIN TRY
    DECLARE @id INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit = '30714591241');
    EXEC concesiones.Empresa_Modificar @id_empresa = @id, @razon_social = 'Patagonia Aventuras SA';
    PRINT 'CASO 7 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 7 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 8: cuit ya usado por otra empresa → error
BEGIN TRY
    DECLARE @id INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit = '30714591241');
    EXEC concesiones.Empresa_Modificar @id_empresa = @id, @cuit = '30714591230';
    PRINT 'CASO 8 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 8 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 9: modificación correcta (actualizar contacto)
BEGIN TRY
    DECLARE @id INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit = '30714591252');
    EXEC concesiones.Empresa_Modificar @id_empresa = @id, @contacto = 'nuevo@gastrosur.com';
    PRINT 'CASO 9 OK: contacto actualizado';
END TRY
BEGIN CATCH
    PRINT 'CASO 9 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO


-- ============================================================
-- Empresa_Eliminar
-- ============================================================

-- CASO 10: empresa inexistente → error
BEGIN TRY
    EXEC concesiones.Empresa_Eliminar @id_empresa = 9999;
    PRINT 'CASO 10 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 10 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 11: baja correcta (Gastronomia del Sur)
BEGIN TRY
    DECLARE @id INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit = '30714591252');
    EXEC concesiones.Empresa_Eliminar @id_empresa = @id;
    PRINT 'CASO 11 OK: empresa dada de baja';
END TRY
BEGIN CATCH
    PRINT 'CASO 11 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 12: ya deshabilitada → error
BEGIN TRY
    DECLARE @id INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit = '30714591252');
    EXEC concesiones.Empresa_Eliminar @id_empresa = @id;
    PRINT 'CASO 12 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 12 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO


-- ============================================================
-- Concesion_Nueva
-- ============================================================

-- CASO 13: empresa inactiva → error
BEGIN TRY
    DECLARE @id_emp INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit = '30714591252');
    DECLARE @id_p   INT = (SELECT id_parque  FROM parques.Parque          WHERE nombre = 'Nahuel Huapi');
    EXEC concesiones.Concesion_Nueva @id_empresa = @id_emp, @id_parque = @id_p,
        @tipo_actividad = 'Restaurante', @fecha_inicio = '2026-01-01', @valor_alquiler = 50000.00;
    PRINT 'CASO 13 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 13 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 14: parque inexistente → error
BEGIN TRY
    DECLARE @id_emp INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit = '30714591230');
    EXEC concesiones.Concesion_Nueva @id_empresa = @id_emp, @id_parque = 9999,
        @tipo_actividad = 'Restaurante', @fecha_inicio = '2026-01-01', @valor_alquiler = 50000.00;
    PRINT 'CASO 14 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 14 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 15: tipo_actividad vacío → error
BEGIN TRY
    DECLARE @id_emp INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit = '30714591230');
    DECLARE @id_p   INT = (SELECT id_parque  FROM parques.Parque          WHERE nombre = 'Nahuel Huapi');
    EXEC concesiones.Concesion_Nueva @id_empresa = @id_emp, @id_parque = @id_p,
        @tipo_actividad = '', @fecha_inicio = '2026-01-01', @valor_alquiler = 50000.00;
    PRINT 'CASO 15 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 15 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 16: fecha_inicio NULL → error
BEGIN TRY
    DECLARE @id_emp INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit = '30714591230');
    DECLARE @id_p   INT = (SELECT id_parque  FROM parques.Parque          WHERE nombre = 'Nahuel Huapi');
    EXEC concesiones.Concesion_Nueva @id_empresa = @id_emp, @id_parque = @id_p,
        @tipo_actividad = 'Restaurante', @fecha_inicio = NULL, @valor_alquiler = 50000.00;
    PRINT 'CASO 16 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 16 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 17: fecha_fin < fecha_inicio → error
BEGIN TRY
    DECLARE @id_emp INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit = '30714591230');
    DECLARE @id_p   INT = (SELECT id_parque  FROM parques.Parque          WHERE nombre = 'Nahuel Huapi');
    EXEC concesiones.Concesion_Nueva @id_empresa = @id_emp, @id_parque = @id_p,
        @tipo_actividad = 'Restaurante', @fecha_inicio = '2026-06-01', @valor_alquiler = 50000.00, @fecha_fin = '2026-05-31';
    PRINT 'CASO 17 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 17 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 18: valor_alquiler = 0 → error
BEGIN TRY
    DECLARE @id_emp INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit = '30714591230');
    DECLARE @id_p   INT = (SELECT id_parque  FROM parques.Parque          WHERE nombre = 'Nahuel Huapi');
    EXEC concesiones.Concesion_Nueva @id_empresa = @id_emp, @id_parque = @id_p,
        @tipo_actividad = 'Restaurante', @fecha_inicio = '2026-01-01', @valor_alquiler = 0;
    PRINT 'CASO 18 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 18 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 19: altas correctas (2 concesiones para los tests siguientes)
BEGIN TRY
    DECLARE @id_emp INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit = '30714591230');
    DECLARE @id_p   INT = (SELECT id_parque  FROM parques.Parque          WHERE nombre = 'Nahuel Huapi');
    EXEC concesiones.Concesion_Nueva @id_empresa = @id_emp, @id_parque = @id_p,
        @tipo_actividad = 'Restaurante', @fecha_inicio = '2026-01-01', @valor_alquiler = 80000.00;
    PRINT 'CASO 19a OK: concesion Restaurante insertada';
END TRY
BEGIN CATCH
    PRINT 'CASO 19a ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO
BEGIN TRY
    DECLARE @id_emp INT = (SELECT id_empresa FROM concesiones.Empresa WHERE cuit = '30714591241');
    DECLARE @id_p   INT = (SELECT id_parque  FROM parques.Parque          WHERE nombre = 'Nahuel Huapi');
    EXEC concesiones.Concesion_Nueva @id_empresa = @id_emp, @id_parque = @id_p,
        @tipo_actividad = 'Alquiler de equipos', @fecha_inicio = '2026-01-01', @valor_alquiler = 45000.00;
    PRINT 'CASO 19b OK: concesion Alquiler de equipos insertada';
END TRY
BEGIN CATCH
    PRINT 'CASO 19b ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO


-- ============================================================
-- Concesion_Modificar
-- ============================================================

-- CASO 20: concesion inexistente → error
BEGIN TRY
    EXEC concesiones.Concesion_Modificar @id_concesion = 9999, @tipo_actividad = 'X';
    PRINT 'CASO 20 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 20 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 21: fecha_fin < fecha_inicio → error
BEGIN TRY
    DECLARE @id INT = (SELECT MIN(id_concesion) FROM concesiones.Concesion WHERE estado = 0);
    EXEC concesiones.Concesion_Modificar @id_concesion = @id, @fecha_inicio = '2026-06-01', @fecha_fin = '2026-05-01';
    PRINT 'CASO 21 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 21 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 22: valor_alquiler negativo → error
BEGIN TRY
    DECLARE @id INT = (SELECT MIN(id_concesion) FROM concesiones.Concesion WHERE estado = 0);
    EXEC concesiones.Concesion_Modificar @id_concesion = @id, @valor_alquiler = -1000.00;
    PRINT 'CASO 22 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 22 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 23: modificación correcta
BEGIN TRY
    DECLARE @id INT = (SELECT MIN(id_concesion) FROM concesiones.Concesion WHERE estado = 0);
    EXEC concesiones.Concesion_Modificar @id_concesion = @id, @valor_alquiler = 90000.00, @fecha_fin = '2027-12-31';
    PRINT 'CASO 23 OK: valor_alquiler y fecha_fin actualizados';
END TRY
BEGIN CATCH
    PRINT 'CASO 23 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO


-- ============================================================
-- Concesion_Eliminar
-- ============================================================

-- CASO 24: concesion inexistente → error
BEGIN TRY
    EXEC concesiones.Concesion_Eliminar @id_concesion = 9999;
    PRINT 'CASO 24 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 24 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 25: baja correcta (segunda concesion, Alquiler de equipos)
BEGIN TRY
    DECLARE @id INT = (SELECT MAX(id_concesion) FROM concesiones.Concesion WHERE estado = 0);
    EXEC concesiones.Concesion_Eliminar @id_concesion = @id;
    PRINT 'CASO 25 OK: concesion dada de baja';
END TRY
BEGIN CATCH
    PRINT 'CASO 25 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 26: ya deshabilitada → error
BEGIN TRY
    DECLARE @id INT = (SELECT MAX(id_concesion) FROM concesiones.Concesion WHERE estado = 1);
    EXEC concesiones.Concesion_Eliminar @id_concesion = @id;
    PRINT 'CASO 26 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 26 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO


-- ============================================================
-- PagoConcesion_Nuevo
-- ============================================================

-- CASO 27: concesion inactiva → error
BEGIN TRY
    DECLARE @id INT = (SELECT MAX(id_concesion) FROM concesiones.Concesion WHERE estado = 1);
    EXEC concesiones.PagoConcesion_Nuevo @id_concesion = @id, @fecha_pago = '2026-02-05', @periodo = '2026-01-01', @monto = 45000.00;
    PRINT 'CASO 27 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 27 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 28: fecha_pago NULL → error
BEGIN TRY
    DECLARE @id INT = (SELECT MIN(id_concesion) FROM concesiones.Concesion WHERE estado = 0);
    EXEC concesiones.PagoConcesion_Nuevo @id_concesion = @id, @fecha_pago = NULL, @periodo = '2026-01-01', @monto = 90000.00;
    PRINT 'CASO 28 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 28 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 29: monto = 0 → error
BEGIN TRY
    DECLARE @id INT = (SELECT MIN(id_concesion) FROM concesiones.Concesion WHERE estado = 0);
    EXEC concesiones.PagoConcesion_Nuevo @id_concesion = @id, @fecha_pago = '2026-02-05', @periodo = '2026-01-01', @monto = 0;
    PRINT 'CASO 29 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 29 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 30: pago correcto
BEGIN TRY
    DECLARE @id INT = (SELECT MIN(id_concesion) FROM concesiones.Concesion WHERE estado = 0);
    EXEC concesiones.PagoConcesion_Nuevo @id_concesion = @id, @fecha_pago = '2026-02-05', @periodo = '2026-01-01', @monto = 90000.00;
    PRINT 'CASO 30 OK: pago enero 2026 insertado';
END TRY
BEGIN CATCH
    PRINT 'CASO 30 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 31: periodo duplicado para la misma concesion → error
-- (el SP normaliza cualquier fecha del mes al dia 1, por lo que '2026-01-15' = enero)
BEGIN TRY
    DECLARE @id INT = (SELECT MIN(id_concesion) FROM concesiones.Concesion WHERE estado = 0);
    EXEC concesiones.PagoConcesion_Nuevo @id_concesion = @id, @fecha_pago = '2026-02-10', @periodo = '2026-01-15', @monto = 90000.00;
    PRINT 'CASO 31 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 31 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO


-- ============================================================
-- PagoConcesion_Modificar
-- ============================================================

-- CASO 32: pago inexistente → error
BEGIN TRY
    EXEC concesiones.PagoConcesion_Modificar @id_pago = 9999, @monto = 90000.00;
    PRINT 'CASO 32 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 32 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 33: monto negativo → error
BEGIN TRY
    DECLARE @id INT = (SELECT MIN(id_pago) FROM concesiones.PagoConcesion WHERE estado = 0);
    EXEC concesiones.PagoConcesion_Modificar @id_pago = @id, @monto = -500.00;
    PRINT 'CASO 33 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 33 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 34: modificación correcta
BEGIN TRY
    DECLARE @id INT = (SELECT MIN(id_pago) FROM concesiones.PagoConcesion WHERE estado = 0);
    EXEC concesiones.PagoConcesion_Modificar @id_pago = @id, @monto = 85000.00;
    PRINT 'CASO 34 OK: monto actualizado a $85000';
END TRY
BEGIN CATCH
    PRINT 'CASO 34 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO


-- ============================================================
-- PagoConcesion_Eliminar
-- ============================================================

-- CASO 35: pago inexistente → error
BEGIN TRY
    EXEC concesiones.PagoConcesion_Eliminar @id_pago = 9999;
    PRINT 'CASO 35 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 35 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 36: baja correcta
BEGIN TRY
    DECLARE @id INT = (SELECT MIN(id_pago) FROM concesiones.PagoConcesion WHERE estado = 0);
    EXEC concesiones.PagoConcesion_Eliminar @id_pago = @id;
    PRINT 'CASO 36 OK: pago dado de baja';
END TRY
BEGIN CATCH
    PRINT 'CASO 36 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 37: ya deshabilitado → error
BEGIN TRY
    DECLARE @id INT = (SELECT MIN(id_pago) FROM concesiones.PagoConcesion WHERE estado = 1);
    EXEC concesiones.PagoConcesion_Eliminar @id_pago = @id;
    PRINT 'CASO 37 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 37 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO


-- ============================================================
-- LOTE: 10 pagos válidos de concesion
-- Concesion A (Restaurante): feb-jun 2026  |  Concesion B (Tienda de souvenirs): ene-may 2026
-- ============================================================

DECLARE @id_p     INT = (SELECT id_parque  FROM parques.Parque           WHERE nombre = 'Nahuel Huapi');
DECLARE @id_emp_b INT = (SELECT id_empresa FROM concesiones.Empresa       WHERE cuit   = '30714591241');
DECLARE @id_c1    INT = (SELECT MIN(id_concesion) FROM concesiones.Concesion WHERE estado = 0);
DECLARE @id_c2    INT;

IF NOT EXISTS (
    SELECT 1 FROM concesiones.Concesion
    WHERE id_empresa = @id_emp_b AND tipo_actividad = 'Tienda de souvenirs' AND estado = 0
)
    EXEC concesiones.Concesion_Nueva
        @id_empresa = @id_emp_b, @id_parque = @id_p,
        @tipo_actividad = 'Tienda de souvenirs', @fecha_inicio = '2026-01-01', @valor_alquiler = 35000.00;

SET @id_c2 = (
    SELECT id_concesion FROM concesiones.Concesion
    WHERE id_empresa = @id_emp_b AND tipo_actividad = 'Tienda de souvenirs' AND estado = 0
);

-- 5 pagos Restaurante (feb-jun 2026; enero ya ocupado por CASO 30/36)
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @id_concesion=@id_c1, @fecha_pago='2026-03-05', @periodo='2026-02-01', @monto=90000.00; PRINT 'Lote  1 OK'; END TRY BEGIN CATCH PRINT 'Lote  1 ERROR: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @id_concesion=@id_c1, @fecha_pago='2026-04-05', @periodo='2026-03-01', @monto=90000.00; PRINT 'Lote  2 OK'; END TRY BEGIN CATCH PRINT 'Lote  2 ERROR: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @id_concesion=@id_c1, @fecha_pago='2026-05-05', @periodo='2026-04-01', @monto=90000.00; PRINT 'Lote  3 OK'; END TRY BEGIN CATCH PRINT 'Lote  3 ERROR: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @id_concesion=@id_c1, @fecha_pago='2026-06-05', @periodo='2026-05-01', @monto=90000.00; PRINT 'Lote  4 OK'; END TRY BEGIN CATCH PRINT 'Lote  4 ERROR: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @id_concesion=@id_c1, @fecha_pago='2026-07-05', @periodo='2026-06-01', @monto=90000.00; PRINT 'Lote  5 OK'; END TRY BEGIN CATCH PRINT 'Lote  5 ERROR: '+ERROR_MESSAGE(); END CATCH
-- 5 pagos Tienda de souvenirs (ene-may 2026)
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @id_concesion=@id_c2, @fecha_pago='2026-02-05', @periodo='2026-01-01', @monto=35000.00; PRINT 'Lote  6 OK'; END TRY BEGIN CATCH PRINT 'Lote  6 ERROR: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @id_concesion=@id_c2, @fecha_pago='2026-03-05', @periodo='2026-02-01', @monto=35000.00; PRINT 'Lote  7 OK'; END TRY BEGIN CATCH PRINT 'Lote  7 ERROR: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @id_concesion=@id_c2, @fecha_pago='2026-04-05', @periodo='2026-03-01', @monto=35000.00; PRINT 'Lote  8 OK'; END TRY BEGIN CATCH PRINT 'Lote  8 ERROR: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @id_concesion=@id_c2, @fecha_pago='2026-05-05', @periodo='2026-04-01', @monto=35000.00; PRINT 'Lote  9 OK'; END TRY BEGIN CATCH PRINT 'Lote  9 ERROR: '+ERROR_MESSAGE(); END CATCH
BEGIN TRY EXEC concesiones.PagoConcesion_Nuevo @id_concesion=@id_c2, @fecha_pago='2026-06-05', @periodo='2026-05-01', @monto=35000.00; PRINT 'Lote 10 OK'; END TRY BEGIN CATCH PRINT 'Lote 10 ERROR: '+ERROR_MESSAGE(); END CATCH
GO

SELECT pc.id_pago, c.tipo_actividad, e.razon_social,
       pc.periodo, pc.fecha_pago, pc.monto, pc.estado
FROM   concesiones.PagoConcesion pc
JOIN   concesiones.Concesion     c  ON c.id_concesion = pc.id_concesion
JOIN   concesiones.Empresa       e  ON e.id_empresa   = c.id_empresa
WHERE  pc.estado = 0
ORDER BY pc.id_concesion, pc.periodo;
GO