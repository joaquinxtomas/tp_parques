USE ParquesNacionales
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'parques')
	EXEC('CREATE SCHEMA parques')
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'ventas')
	EXEC('CREATE SCHEMA ventas')
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'actividades')
	EXEC('CREATE SCHEMA actividades')
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'personal')
	EXEC('CREATE SCHEMA personal')
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'concesiones')
	EXEC('CREATE SCHEMA concesiones')
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'importacion')
	EXEC('CREATE SCHEMA importacion')
GO

-- TEST DE CREACIÓN
SELECT name, schema_id, principal_id
FROM sys.schemas
WHERE name IN ('parques', 'ventas', 'actividades', 'personal', 'concesiones', 'importacion')
ORDER BY name;