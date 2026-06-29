--	18/06/2026
--  INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
--  Descripcion: Creacion del STORED PROCEDURES de la operación baja
--  y sus respectivas pruebas en Guardaparque

USE ParquesNacionales;
GO


-- Pruebas de validaciones

-- Guardaparque inexistente
EXEC personal.guardaparque_baja @id_guardaparque = 99999;

-- Ejecución Exitosa
EXEC personal.guardaparque_baja @id_guardaparque = 2;
