--	18/06/2026
--  INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
--  Descripcion: Creacion del STORED PROCEDURES de la operación baja 
--  y sus respectivas pruebas en GuiaAutorizado


USE ParquesNacionales;
GO
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

-- Pruebas sobre validaciones

-- Guía inexistente
EXEC personal.guia_baja @id_guia = 99999;


-- Ejecución Exitosa 
EXEC personal.guia_baja @id_guia = 2;
