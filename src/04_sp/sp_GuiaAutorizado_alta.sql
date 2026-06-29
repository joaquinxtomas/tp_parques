--	18/06/2026
--  INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
--  Descripcion: Creacion del STORED PROCEDURES de la operación alta
--  y sus respectivas pruebas en GuiaAutorizado


USE ParquesNacionales;
GO

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