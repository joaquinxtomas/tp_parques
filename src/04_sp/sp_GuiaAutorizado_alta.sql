--	18/06/2026
--  INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
--  Descripcion: Creacion del STORED PROCEDURES de la operación alta
--  y sus respectivas pruebas en GuiaAutorizado


USE ParquesNacionales;
GO
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

-- Pruebas sobre validaciones

-- Guía existente
EXEC personal.guiaAutorizado_alta 
@nombre = 'Carlos Gómez', 
@dni = '32456789', 
@especialidad = 'Trekking', 
@titulo = 'Guía Profesional', 
@vigencia_desde = '2026-06-18', 
@vigencia_hasta = '2029-12-31';

-- Nombre obligatorio
EXEC personal.guiaAutorizado_alta 
@nombre = NULL, 
@dni = '49111222', 
@especialidad = 'Fotografía', 
@titulo = 'Guía Local', 
@vigencia_desde = '2026-06-18', 
@vigencia_hasta = '2029-12-31';

-- DNI obligatorio
EXEC personal.guiaAutorizado_alta 
@nombre = 'Esteban Quito', 
@dni = NULL, 
@especialidad = 'Fotografía', 
@titulo = 'Guía Local', 
@vigencia_desde = '2026-06-18', 
@vigencia_hasta = '2029-12-31';

-- Fecha de comienzo obligatoria
EXEC personal.guiaAutorizado_alta 
@nombre = 'Esteban Quito', 
@dni = '49111222', 
@especialidad = 'Fotografía', 
@titulo = 'Guía Local', 
@vigencia_desde = NULL, 
@vigencia_hasta = '2029-12-31';