--	18/06/2026
--  INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
--  Descripcion: Creacion del STORED PROCEDURES de la operación baja
--  y sus respectivas pruebas en Guardaparque

USE ParquesNacionales;
GO
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

-- Pruebas de validaciones

-- Guardaparque inexistente
EXEC personal.guardaparque_baja @id_guardaparque = 99999;

-- Ejecución Exitosa
EXEC personal.guardaparque_baja @id_guardaparque = 2;
