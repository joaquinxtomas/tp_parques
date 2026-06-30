--  21/06/2026
--  INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
--  Descripcion: Creacion de logins, usuarios de base de datos y asignacion a roles.
--
--  Usuarios definidos:
--  Login               Usuario DB          Rol asignado
--  parques_admin       parques_admin       rol_administrador
--  parques_operador    parques_operador    rol_operaciones
--  parques_impor       parques_impor       rol_importacion
--  parques_consultas   parques_consultas   rol_consultas


-- Crear logins en el servidor

/*USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'parques_admin')
    CREATE LOGIN parques_admin WITH PASSWORD = -- Clave de administrador;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'parques_operador')
    CREATE LOGIN parques_operador WITH PASSWORD = -- Clave de operador;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'parques_impor')
    CREATE LOGIN parques_impor WITH PASSWORD = -- Clave de importador;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'parques_consultas')
    CREATE LOGIN parques_consultas WITH PASSWORD = -- Clave de consultas;
GO
*/
-- Crear usuarios en la base de datos

USE ParquesNacionales;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'parques_admin')
    CREATE USER parques_admin FOR LOGIN parques_admin;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'parques_operador')
    CREATE USER parques_operador FOR LOGIN parques_operador;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'parques_impor')
    CREATE USER parques_impor FOR LOGIN parques_impor;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'parques_consultas')
    CREATE USER parques_consultas FOR LOGIN parques_consultas;
GO

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

-- Asignar usuarios a sus roles

ALTER ROLE rol_administrador ADD MEMBER parques_admin;
GO

ALTER ROLE rol_operaciones ADD MEMBER parques_operador;
GO

ALTER ROLE rol_importacion ADD MEMBER parques_impor;
GO

ALTER ROLE rol_consultas ADD MEMBER parques_consultas;
GO