--	18/06/2026
--  INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
--  Descripcion: Creacion del STORED PROCEDURES de la operación alta y sus respectivas pruebas en AsignacionGP


USE ParquesNacionales;
GO
CREATE OR ALTER PROCEDURE personal.asignacionGP_alta
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
    
    IF @id_parque IS NULL
        SET @v_errores += 'La id del parque es obligatoria. ';
    ELSE
        IF not exists (select 1 from parques.Parque where id_parque = @id_parque)
            set @v_errores += 'No existe el parque seleccionado. ';
    IF @id_guardaparque IS NULL
        SET @v_errores += 'La id del guardaparque es obligatoria. ';
    ELSE
        IF not exists (select 1 from personal.Guardaparque where id_guardaparque = @id_guardaparque)
            set @v_errores += 'No existe el guardaparque seleccionado. ';
    IF @id_guia IS not NULL
        IF not exists (select 1 from personal.GuiaAutorizado where id_guia = @id_guia)
            set @v_errores += 'No existe el guía seleccionado. ';
    IF @fecha_desde IS NULL
        SET @v_errores += 'La fecha de comienzo es obligatoria. ';

    IF EXISTS (SELECT 1 FROM personal.AsignacionGP WHERE id_guardaparque = @id_guardaparque and id_parque = @id_parque and fecha_desde = @fecha_desde)
        SET @v_errores += 'Ya existe la asignación del guardaparque en este parque para la fecha indicada. ';
            
    IF @v_errores <> ''
    BEGIN
        RAISERROR(@v_errores, 16, 1);
        RETURN;
    END

    INSERT INTO personal.AsignacionGP(id_guardaparque, id_parque, id_guia, fecha_desde, fecha_hasta, motivo)
    VALUES (@id_guardaparque, @id_parque, @id_guia, @fecha_desde, @fecha_hasta, @motivo);
END

insert into parques.Parque(nombre, 

exec personal.asignacionGP_alta 1, 1, null, '2026-06-18', null, 'prueba alta'

select * from personal.AsignacionGP

select * from personal.Guardaparque
select * from parques.Parque
select * from personal.GuiaAutorizado

-- Pruebas asignacionGP_alta

-- 1: Id de parque obligatorio
EXEC personal.asignacionGP_alta @id_guardaparque = 1, @id_parque = NULL, @id_guia = 1, @fecha_desde = '2026-07-01', @fecha_hasta = '2026-12-31', @motivo = 'Error Parque NULL';

-- 2: Parque inexistente
EXEC personal.asignacionGP_alta @id_guardaparque = 1, @id_parque = 999, @id_guia = 1, @fecha_desde = '2026-07-01', @fecha_hasta = '2026-12-31', @motivo = 'Error Parque Inexistente';

-- 3: Id de guardaparque obligatorio
EXEC personal.asignacionGP_alta @id_guardaparque = NULL, @id_parque = 1, @id_guia = 1, @fecha_desde = '2026-07-01', @fecha_hasta = '2026-12-31', @motivo = 'Error Guardaparque NULL';

-- 4: Guardaparque inexistente
EXEC personal.asignacionGP_alta @id_guardaparque = 999, @id_parque = 1, @id_guia = 1, @fecha_desde = '2026-07-01', @fecha_hasta = '2026-12-31', @motivo = 'Error Guardaparque Inexistente';

-- 5: Guía inexistente
EXEC personal.asignacionGP_alta @id_guardaparque = 1, @id_parque = 1, @id_guia = 999, @fecha_desde = '2026-07-01', @fecha_hasta = '2026-12-31', @motivo = 'Error Guía Inexistente';

-- 6: Fecha de comienzo obligatoria
EXEC personal.asignacionGP_alta @id_guardaparque = 1, @id_parque = 1, @id_guia = 1, @fecha_desde = NULL, @fecha_hasta = '2026-12-31', @motivo = 'Error Fecha NULL';

-- 7: Asignación duplicada
EXEC personal.asignacionGP_alta @id_guardaparque = 1, @id_parque = 1, @id_guia = NULL, @fecha_desde = '2026-01-01', @fecha_hasta = '2026-06-30', @motivo = 'Error Duplicado';



-- =========================================================================
-- 1. INSERTS PARA LA TABLA: [parques].[TipoParque]
-- =========================================================================
INSERT INTO [parques].[TipoParque] ([descripcion]) 
VALUES ('Parque Nacional');

INSERT INTO [parques].[TipoParque] ([descripcion]) 
VALUES ('Reserva Provincial');

INSERT INTO [parques].[TipoParque] ([descripcion]) 
VALUES ('Monumento Natural');


-- =========================================================================
-- 2. INSERTS PARA LA TABLA: [parques].[Parque]
-- =========================================================================
INSERT INTO [parques].[Parque] ([nombre], [id_tipo_parque], [ubicacion], [latitud], [longitud], [superficie])
VALUES ('Parque Nacional Iguazú', 1, 'Misiones, Argentina', -25.677500, -54.440278, 67720.00);

INSERT INTO [parques].[Parque] ([nombre], [id_tipo_parque], [ubicacion], [latitud], [longitud], [superficie])
VALUES ('Reserva Esteros del Iberá', 2, 'Corrientes, Argentina', -28.533333, -57.166667, 195500.50);

INSERT INTO [parques].[Parque] ([nombre], [id_tipo_parque], [ubicacion], [latitud], [longitud], [superficie])
VALUES ('Parque Nacional Los Glaciares', 1, 'Santa Cruz, Argentina', -50.500000, -73.250000, 726927.00);


-- =========================================================================
-- 3. INSERTS PARA LA TABLA: [personal].[Guardaparque]
-- =========================================================================
INSERT INTO [personal].[Guardaparque] ([nombre], [dni], [vigencia_desde], [vigencia_hasta], [activo])
VALUES ('Carlos Gómez', '32456789', '2020-01-15', '2028-12-31', 1);

INSERT INTO [personal].[Guardaparque] ([nombre], [dni], [vigencia_desde], [vigencia_hasta], [activo])
VALUES ('María Rodríguez', '35123456', '2022-03-01', '2027-03-01', 1);

INSERT INTO [personal].[Guardaparque] ([nombre], [dni], [vigencia_desde], [vigencia_hasta], [activo])
VALUES ('Jorge Altieri', '28999111', '2015-06-10', '2025-06-10', 0);


-- =========================================================================
-- 4. INSERTS PARA LA TABLA: [personal].[GuiaAutorizado]
-- =========================================================================
INSERT INTO [personal].[GuiaAutorizado] ([nombre], [dni], [especialidad], [titulo], [vigencia_desde], [vigencia_hasta])
VALUES ('Laura Benítez', '38444555', 'Trekking y Alta Montaña', 'Guía Profesional de Turismo', '2024-01-01', '2027-01-01');

INSERT INTO [personal].[GuiaAutorizado] ([nombre], [dni], [especialidad], [titulo], [vigencia_desde], [vigencia_hasta])
VALUES ('Diego Álvarez', '40111222', 'Avistaje de Aves y Fauna', 'Técnico en Biología', '2025-05-10', '2028-05-10');

INSERT INTO [personal].[GuiaAutorizado] ([nombre], [dni], [especialidad], [titulo], [vigencia_desde], [vigencia_hasta])
VALUES ('Ana Martínez', '33777888', 'Paseos Náuticos', 'Guía Naval Avanzado', '2023-08-20', '2026-08-20');


-- =========================================================================
-- 5. INSERTS PARA LA TABLA: [personal].[AsignacionGP]
-- =========================================================================

-- Solo Guardaparque
INSERT INTO [personal].[AsignacionGP] ([id_guardaparque], [id_parque], [id_guia], [fecha_desde], [fecha_hasta], [motivo])
VALUES (1, 1, NULL, '2026-01-01', '2026-06-30', 'Campaña de Verano y control de senderos');

INSERT INTO [personal].[AsignacionGP] ([id_guardaparque], [id_parque], [id_guia], [fecha_desde], [fecha_hasta], [motivo])
VALUES (2, 2, NULL, '2026-03-15', '2026-09-15', 'Monitoreo de fauna protegida');

-- Solo Guía
INSERT INTO [personal].[AsignacionGP] ([id_guardaparque], [id_parque], [id_guia], [fecha_desde], [fecha_hasta], [motivo])
VALUES (NULL, 3, 3, '2026-07-01', '2026-12-31', 'Refuerzo de temporada invernal en glaciares');

*/