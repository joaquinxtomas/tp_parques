--	18/06/2026
--  INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
--  Descripcion: Creacion del STORED PROCEDURES de la operación modificación 
--  y sus respectivas pruebas en GuiaAutorizado

USE ParquesNacionales;
GO
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

-- Pruebas sobre validaciones

-- Guía inexistente
EXEC personal.guia_modificacion 
@id_guia = 99999, 
@nombre = 'Laura Benítez', 
@dni = '38444555', 
@especialidad = 'Trekking y Alta Montaña', 
@titulo = 'Guía Profesional de Turismo', 
@vigencia_desde = '2024-01-01', 
@vigencia_hasta = '2027-01-01';


-- Nombre obligatorio
EXEC personal.guia_modificacion 
@id_guia = 1, 
@nombre = NULL, 
@dni = '38444555', 
@especialidad = 'Trekking y Alta Montaña', 
@titulo = 'Guía Profesional de Turismo', 
@vigencia_desde = '2024-01-01', 
@vigencia_hasta = '2027-01-01';


-- DNI obligatorio
EXEC personal.guia_modificacion 
@id_guia = 1, 
@nombre = 'Laura Benítez', 
@dni = NULL, 
@especialidad = 'Trekking y Alta Montaña', 
@titulo = 'Guía Profesional de Turismo', 
@vigencia_desde = '2024-01-01', 
@vigencia_hasta = '2027-01-01';


-- Fecha de comienzo obligatoria
EXEC personal.guia_modificacion 
@id_guia = 1, 
@nombre = 'Laura Benítez', 
@dni = '38444555', 
@especialidad = 'Trekking y Alta Montaña', 
@titulo = 'Guía Profesional de Turismo', 
@vigencia_desde = NULL, 
@vigencia_hasta = '2027-01-01';
