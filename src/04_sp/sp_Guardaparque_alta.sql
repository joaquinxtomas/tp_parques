--	18/06/2026
--  INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
--  Descripcion: Creacion del STORED PROCEDURES de la operación alta
--  y sus respectivas pruebas en Guardaparque

USE ParquesNacionales;
GO

-- Pruebas de validaciones

-- Nombre obligatorio
EXEC personal.guardaparque_alta 
@nombre = NULL, 
@dni = '45111222', 
@vigencia_desde = '2026-06-18', 
@vigencia_hasta = '2030-12-31';

-- DNI obligatorio
EXEC personal.guardaparque_alta 
@nombre = 'Pedro Picapiedra', 
@dni = NULL, 
@vigencia_desde = '2026-06-18', 
@vigencia_hasta = '2030-12-31';

-- Fecha de comienzo obligatoria
EXEC personal.guardaparque_alta 
@nombre = 'Pedro Picapiedra', 
@dni = '45111222', 
@vigencia_desde = NULL, 
@vigencia_hasta = '2030-12-31';


