--	18/06/2026
--  INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
--  Descripcion: Creacion del STORED PROCEDURES de la operación modificación
--  y sus respectivas pruebas en Guardaparque


USE ParquesNacionales;
GO
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

-- Pruebas sobre validaciones

-- Guardaparque inexistente
EXEC personal.guardaparque_modificacion 
@id_guardaparque = 99999,
@nombre = 'Carlos Gómez', 
@dni = '32456789', 
@vigencia_desde = '2020-01-15', 
@vigencia_hasta = '2028-12-31';

-- Nombre obligatorio
EXEC personal.guardaparque_modificacion 
@id_guardaparque = 1, 
@nombre = NULL, 
@dni = '32456789', 
@vigencia_desde = '2020-01-15', 
@vigencia_hasta = '2028-12-31';

-- DNI obligatorio
EXEC personal.guardaparque_modificacion 
@id_guardaparque = 1, 
@nombre = 'Carlos Gómez', 
@dni = NULL, 
@vigencia_desde = '2020-01-15', 
@vigencia_hasta = '2028-12-31';

-- Fecha de comienzo obligatoria
EXEC personal.guardaparque_modificacion 
@id_guardaparque = 1, 
@nombre = 'Carlos Gómez', 
@dni = '32456789', 
@vigencia_desde = NULL, 
@vigencia_hasta = '2028-12-31';
