--	18/06/2026
--  INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
--  Descripcion: Creacion del STORED PROCEDURES de la operación alta
--  y sus respectivas pruebas en Guardaparque

USE ParquesNacionales;
GO
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

-- Pruebas de validaciones

-- Nombre obligatorio
EXEC personal.guardaparque_alta 
@nombre = NULL, 
@dni = '45111222', 
@vigencia_desde = '2026-06-18', 
@vigencia_hasta = '2030-12-31';

-- DNI obligatorio
EXEC personal.guardaparque_alta 
@nombre = 'Pedro Picapiedra', 
@dni = NULL, 
@vigencia_desde = '2026-06-18', 
@vigencia_hasta = '2030-12-31';

-- Fecha de comienzo obligatoria
EXEC personal.guardaparque_alta 
@nombre = 'Pedro Picapiedra', 
@dni = '45111222', 
@vigencia_desde = NULL, 
@vigencia_hasta = '2030-12-31';


