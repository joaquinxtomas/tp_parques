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

USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'parques_admin')
    CREATE LOGIN parques_admin WITH PASSWORD = 'Admin#Parques2026!';
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'parques_operador')
    CREATE LOGIN parques_operador WITH PASSWORD = 'Operador#Parques2026!';
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'parques_impor')
    CREATE LOGIN parques_impor WITH PASSWORD = 'Importacion#Parques2026!';
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'parques_consultas')
    CREATE LOGIN parques_consultas WITH PASSWORD = 'Consultas#Parques2026!';
GO

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

-- Asignar usuarios a sus roles

ALTER ROLE rol_administrador ADD MEMBER parques_admin;
GO

ALTER ROLE rol_operaciones ADD MEMBER parques_operador;
GO

ALTER ROLE rol_importacion ADD MEMBER parques_impor;
GO

ALTER ROLE rol_consultas ADD MEMBER parques_consultas;
GO