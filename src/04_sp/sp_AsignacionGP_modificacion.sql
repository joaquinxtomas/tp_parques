--	18/06/2026
--  INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
--  Descripcion: Creacion del STORED PROCEDURES de la operación modificación y sus respectivas pruebas en AsignacionGP
USE ParquesNacionales;
GO
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