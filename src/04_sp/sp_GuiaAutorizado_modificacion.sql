--	18/06/2026
--  INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
--  Descripcion: Creacion del STORED PROCEDURES de la operación modificación 
--  y sus respectivas pruebas en GuiaAutorizado

USE ParquesNacionales;
GO

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
