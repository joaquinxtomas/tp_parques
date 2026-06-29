--	18/06/2026
--  INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
--  Descripcion: Creacion del STORED PROCEDURES de la operación modificación
--  y sus respectivas pruebas en Guardaparque


USE ParquesNacionales;
GO

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
