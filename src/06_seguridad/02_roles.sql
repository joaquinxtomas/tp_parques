--  21/06/2026
--  INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
--  Descripcion: Creacion de roles de seguridad con permisos granulares.
--
--  Roles:
--  Rol                 Descripcion
--  rol_administrador   Control total de la base de datos (DDL + DML + ejecucion de SPs)
--  rol_operaciones     Ejecutar SPs de ABM en todos los modulos operativos
--  rol_importacion     Ejecutar SPs de importacion de datos externos
--  rol_consultas       Solo lectura sobre todas las tablas y vistas

USE ParquesNacionales;
GO

-- CREACION DE ROLES

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rol_administrador' AND type = 'R')
    CREATE ROLE rol_administrador;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rol_operaciones' AND type = 'R')
    CREATE ROLE rol_operaciones;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rol_importacion' AND type = 'R')
    CREATE ROLE rol_importacion;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rol_consultas' AND type = 'R')
    CREATE ROLE rol_consultas;
GO


-- ROL: rol_administrador
-- Control total sobre la base: creacion/modificacion de objetos, ejecucion de SPs, lectura y escritura en todas las tablas.

GRANT CONTROL ON DATABASE::ParquesNacionales TO rol_administrador;
GO


-- ROL: rol_operaciones
-- Puede ejecutar todos los SPs de ABM de los modulos operativos y leer las tablas para listar datos en la aplicacion.

GRANT EXECUTE ON SCHEMA::parques      TO rol_operaciones;
GRANT EXECUTE ON SCHEMA::ventas       TO rol_operaciones;
GRANT EXECUTE ON SCHEMA::personal     TO rol_operaciones;
GRANT EXECUTE ON SCHEMA::concesiones  TO rol_operaciones;
GRANT EXECUTE ON SCHEMA::actividades  TO rol_operaciones;
GO

GRANT SELECT ON SCHEMA::parques      TO rol_operaciones;
GRANT SELECT ON SCHEMA::ventas       TO rol_operaciones;
GRANT SELECT ON SCHEMA::personal     TO rol_operaciones;
GRANT SELECT ON SCHEMA::concesiones  TO rol_operaciones;
GRANT SELECT ON SCHEMA::actividades  TO rol_operaciones;
GO


-- ROL: rol_importacion
-- Puede ejecutar los SPs del modulo de importacion y ver el log de sus propias importaciones.

GRANT EXECUTE ON SCHEMA::importacion TO rol_importacion;
GRANT SELECT  ON SCHEMA::importacion TO rol_importacion;
GO


-- ROL: rol_consultas
-- Solo lectura sobre todas las tablas y vistas de la base. No puede ejecutar SPs de modificacion ni acceder a datos descifrados (el DNI cifrado se muestra como VARBINARY; descifrar requiere la clave).

GRANT SELECT ON SCHEMA::parques      TO rol_consultas;
GRANT SELECT ON SCHEMA::ventas       TO rol_consultas;
GRANT SELECT ON SCHEMA::personal     TO rol_consultas;
GRANT SELECT ON SCHEMA::concesiones  TO rol_consultas;
GRANT SELECT ON SCHEMA::actividades  TO rol_consultas;
GRANT SELECT ON SCHEMA::importacion  TO rol_consultas;
GO