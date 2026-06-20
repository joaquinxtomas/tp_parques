--	18/06/2026
--  INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
--  Descripcion: Creacion del STORED PROCEDURES de la operación baja y sus respectivas pruebas en AsignacionGP


USE ParquesNacionales;
GO
CREATE OR ALTER PROCEDURE personal.asignacionGP_baja	--	BAJA
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