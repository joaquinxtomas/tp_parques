USE ParquesNacionales;
GO

--SCHEMA PARQUES
IF NOT EXISTS (
	SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'parques'
	AND TABLE_NAME = 'TipoParque')
BEGIN 
	CREATE TABLE parques.TipoParque(
		id_tipo_parque INT IDENTITY(1,1) NOT NULL,
		descripcion VARCHAR(200) NOT NULL,
		estado BIT NOT NULL CONSTRAINT DF_tipo_parque_estado DEFAULT(0),

		CONSTRAINT PK_TipoParque PRIMARY KEY (id_tipo_parque),
		CONSTRAINT UQ_TipoParque_Descripcion UNIQUE(descripcion)
	);
END
GO


IF NOT EXISTS (
	SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'parques'
	AND TABLE_NAME = 'Parque')
BEGIN
	CREATE TABLE parques.Parque(
		id_parque INT IDENTITY(1,1) NOT NULL,
		nombre VARCHAR(100) NOT NULL,
		id_tipo_parque INT NOT NULL,
		provincia VARCHAR(100) NULL,
		region VARCHAR(100) NULL,
		latitud DECIMAL(9,6) NULL,
		longitud DECIMAL(9,6) NULL,
		superficie DECIMAL(12,2) NULL,
		estado BIT NOT NULL CONSTRAINT DF_parque_estado DEFAULT(0),

		CONSTRAINT PK_Parque PRIMARY KEY (id_parque),
		CONSTRAINT UQ_Parque_Nombre UNIQUE(nombre),
		CONSTRAINT FK_Parque_TipoParque FOREIGN KEY (id_tipo_parque)
			REFERENCES parques.TipoParque(id_tipo_parque),
		CONSTRAINT CK_Parque_Latitud  CHECK (latitud  IS NULL OR latitud  BETWEEN -90  AND 90),
		CONSTRAINT CK_Parque_Longitud CHECK (longitud IS NULL OR longitud BETWEEN -180 AND 180),
		--garantiza que las coordenadas estén ambas o no esté ninguna, evitando que estén incompletas
		CONSTRAINT CK_Parque_CoordenadasCompletas CHECK (
            (latitud IS NULL AND longitud IS NULL) OR 
            (latitud IS NOT NULL AND longitud IS NOT NULL)
        ),
		CONSTRAINT CK_Parque_Superficie CHECK(superficie IS NULL OR superficie > 0)
	);
END
GO

--SCHEMA PERSONAL
IF NOT EXISTS (
	SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'personal'
	AND TABLE_NAME = 'GuiaAutorizado')
BEGIN
	CREATE TABLE personal.GuiaAutorizado(
		id_guia INT IDENTITY(1,1) NOT NULL,
		nombre VARCHAR(50) NOT NULL,
		dni VARBINARY(256) NOT NULL,
		dni_hash VARBINARY(32) NOT NULL,
		especialidad VARCHAR(100) NULL,
		titulo VARCHAR(100) NULL,
		vigencia_desde DATE NOT NULL,
		vigencia_hasta DATE NULL,
		estado BIT NOT NULL CONSTRAINT DF_guia_autorizado DEFAULT(0),

		CONSTRAINT PK_GuiaAutorizado PRIMARY KEY (id_guia),
		CONSTRAINT UQ_GuiaAutorizado_DNI UNIQUE (dni_hash),
		CONSTRAINT CK_GuiaAutorizado_VigenciaValida CHECK(
			vigencia_hasta IS NULL OR vigencia_hasta >= vigencia_desde
		)
	);
END
GO

IF NOT EXISTS (
	SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'personal'
	AND TABLE_NAME = 'Guardaparque')
BEGIN
	CREATE TABLE personal.Guardaparque(
		id_guardaparque INT IDENTITY (1,1) NOT NULL,
		nombre VARCHAR(100) NOT NULL,
		dni VARBINARY(256) NOT NULL,
		dni_hash VARBINARY(32) NOT NULL,
		vigencia_desde DATE NOT NULL,
		vigencia_hasta DATE NULL,
		activo BIT NOT NULL CONSTRAINT DF_Guardaparque_Activo DEFAULT(0),
		estado BIT NOT NULL CONSTRAINT DF_guardparque_estado DEFAULT(0),

		CONSTRAINT PK_Guardaparque PRIMARY KEY (id_guardaparque),
		CONSTRAINT UQ_Guardaparque_DNI UNIQUE(dni_hash),
		CONSTRAINT CK_Guardaparque_VigenciaValida CHECK(
			vigencia_hasta IS NULL OR vigencia_hasta >= vigencia_desde
		)
	);
END
GO

IF NOT EXISTS (
	SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'personal'
	AND TABLE_NAME = 'AsignacionGP')
BEGIN
	CREATE TABLE personal.AsignacionGP(
		id_asignacion INT IDENTITY(1,1) NOT NULL,
		id_guardaparque INT NULL,
		id_parque INT NOT NULL,
		id_guia INT NULL,
		fecha_desde DATE NOT NULL,
		fecha_hasta DATE NULL,
		motivo VARCHAR(255) NULL,
		estado BIT NOT NULL CONSTRAINT DF_asignacion_gp DEFAULT(0),

		CONSTRAINT PK_AsignacionGP PRIMARY KEY (id_asignacion),
		CONSTRAINT FK_AsignacionGP_Guardaparque FOREIGN KEY (id_guardaparque)
			REFERENCES personal.Guardaparque (id_guardaparque),
		CONSTRAINT FK_AsignacionGP_Guia FOREIGN KEY (id_guia)
			REFERENCES personal.GuiaAutorizado(id_guia),
		CONSTRAINT FK_AsignacionGP_Parque FOREIGN KEY (id_parque)
			REFERENCES parques.Parque(id_parque),
		CONSTRAINT CK_AsignacionGP_UnPersonal CHECK(
			(id_guardaparque IS NOT NULL AND id_guia IS NULL) OR
			(id_guardaparque IS NULL AND id_guia IS NOT NULL)
		),
		CONSTRAINT CK_AsignacionGP_FechaValida CHECK(
			fecha_hasta IS NULL OR fecha_hasta >= fecha_desde
		)
	);
END
GO


-- SCHEMA ACTIVIDADES
IF NOT EXISTS(
	SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'actividades'
	AND TABLE_NAME = 'Atraccion')
BEGIN
	CREATE TABLE actividades.Atraccion(
		id_atraccion INT IDENTITY(1,1) NOT NULL,
		id_parque INT NOT NULL,
		nombre VARCHAR(100) NOT NULL,
		costo DECIMAL(10,2) NOT NULL,
		duracion INT NULL,
		cupo_maximo INT NULL,
		tipo VARCHAR(20) NOT NULL,
		estado BIT NOT NULL CONSTRAINT DF_atraccion_estado DEFAULT(0),

		CONSTRAINT PK_Atraccion PRIMARY KEY(id_atraccion),
		CONSTRAINT FK_Atraccion_Parque FOREIGN KEY (id_parque)
			REFERENCES parques.Parque(id_parque),
		CONSTRAINT CK_Atraccion_CostoPositivo CHECK(costo >= 0),
		CONSTRAINT CK_Atraccion_DuracionPositiva CHECK(
			duracion IS NULL OR duracion > 0
		),
		CONSTRAINT CK_Atraccion_CupoPositivo CHECK(
			cupo_maximo IS NULL OR cupo_maximo > 0
		)
		-- se puede agregar un check para el tipo de atraccion (paga, gratuita, etc): definir tipos

	);
END
GO

IF NOT EXISTS (
	SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'actividades'
	AND TABLE_NAME = 'TicketsAtraccion')
BEGIN
	CREATE TABLE actividades.TicketsAtraccion(
		id_ticket_atraccion INT IDENTITY(1,1) NOT NULL,
		id_atraccion INT NOT NULL,
		fecha DATETIME2(0) NOT NULL,
		cantidad INT NOT NULL,
		subtotal DECIMAL(12,2) NOT NULL,
		estado BIT NOT NULL CONSTRAINT DF_TicketsAstraccion_estado DEFAULT(0),

		CONSTRAINT PK_TicketsAtraccion PRIMARY KEY(id_ticket_atraccion),
		CONSTRAINT FK_TicketsAtraccion_Atraccion FOREIGN KEY (id_atraccion)
			REFERENCES actividades.Atraccion(id_atraccion),
		CONSTRAINT CK_TicketsAtraccion_CantidadPositiva CHECK (cantidad > 0),
		CONSTRAINT CK_TicketsAtraccion_Subtotal CHECK (subtotal >= 0)
	);
END
GO

IF NOT EXISTS (
	SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'actividades'
	AND TABLE_NAME = 'TourGuia')
BEGIN
	CREATE TABLE actividades.TourGuia(
		id_tour_guia INT IDENTITY(1,1) NOT NULL,
		id_atraccion INT NOT NULL,
		id_guia INT NOT NULL,
		estado BIT NOT NULL CONSTRAINT DF_tourguia_estado DEFAULT(0),

		CONSTRAINT PK_TourGuia PRIMARY KEY(id_tour_guia),
		CONSTRAINT FK_TourGuia_Atraccion FOREIGN KEY(id_atraccion)
			REFERENCES actividades.Atraccion(id_atraccion),
		CONSTRAINT FK_TourGuia_Guia FOREIGN KEY (id_guia)
			REFERENCES personal.GuiaAutorizado(id_guia),
		CONSTRAINT UQ_TourGuia_AtraccionGuia UNIQUE(id_atraccion, id_guia)
	);
END
GO


--SCHEMA VENTAS
IF NOT EXISTS (
	SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'ventas'
	AND TABLE_NAME = 'TipoVisitante')
BEGIN
	CREATE TABLE ventas.TipoVisitante(
		id_tipo_visitante INT IDENTITY(1,1) NOT NULL,
		descripcion VARCHAR(50) NOT NULL,
		estado BIT NOT NULL CONSTRAINT DF_tipo_visitante_estado DEFAULT(0),

		CONSTRAINT PK_TipoVisitante PRIMARY KEY (id_tipo_visitante),
		CONSTRAINT UQ_TipoVisitante_Descripcion UNIQUE (descripcion)
	);
END
GO

IF NOT EXISTS(
	SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'ventas'
	AND TABLE_NAME = 'PrecioEntrada')
BEGIN
	CREATE TABLE ventas.PrecioEntrada(
		id_precio INT IDENTITY(1,1) NOT NULL,
		id_parque INT NOT NULL,
		id_tipo_visitante INT NOT NULL,
		precio DECIMAL (10,2) NOT NULL,
		fecha_inicio DATE NOT NULL,
		fecha_fin DATE NULL,
		estado BIT NOT NULL CONSTRAINT DF_precio_entrada_estado DEFAULT(0),

		CONSTRAINT PK_PrecioEntrada PRIMARY KEY (id_precio),
		CONSTRAINT FK_PrecioEntrada_Parque FOREIGN KEY (id_parque)
			REFERENCES parques.Parque(id_parque),
		CONSTRAINT FK_PrecioEntrada_TipoVisitante FOREIGN KEY(id_tipo_visitante)
			REFERENCES ventas.TipoVisitante(id_tipo_visitante),
		CONSTRAINT CK_PrecioEntrada_PrecioPositivo CHECK (precio >= 0),
		CONSTRAINT CK_PrecioEntrada_FechasValidas CHECK(fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
		CONSTRAINT UQ_PrecioEntrada_ParqueTipoFecha UNIQUE (id_parque, id_tipo_visitante, fecha_inicio)
	);
END
GO

IF NOT EXISTS(
	SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'ventas'
	AND TABLE_NAME = 'Entrada')
BEGIN
	CREATE TABLE ventas.Entrada(
		id_entrada INT IDENTITY(1,1) NOT NULL,
		-- id_tipo_visitante INT NOT NULL, -- ya está en TicketVisitante para permitir tickets con múltiples tipos de visitantes
		id_parque INT NOT NULL,
		pto_venta INT NOT NULL,
		fecha DATETIME2(0) NOT NULL,
		total DECIMAL(12,2) NOT NULL,
		forma_pago VARCHAR(20) NOT NULL,
		nro_ticket INT NOT NULL,
		origen VARCHAR (50) NOT NULL CONSTRAINT DF_entrada_origen DEFAULT('TRANSACCIONAL'),
		estado BIT NOT NULL CONSTRAINT DF_entrada_estado DEFAULT(0),

		CONSTRAINT PK_Entrada PRIMARY KEY (id_entrada),
		CONSTRAINT FK_Entrada_Parque FOREIGN KEY (id_parque)
			REFERENCES parques.Parque(id_parque),
		-- CONSTRAINT FK_Entrada_TipoVisitante FOREIGN KEY (id_tipo_visitante)
		-- 	REFERENCES ventas.TipoVisitante (id_tipo_visitante),
		CONSTRAINT UQ_EntradaPtoVentaNroTicket UNIQUE(pto_venta, nro_ticket),
		CONSTRAINT CK_Entrada_TotalPositivo CHECK (total >= 0),
		CONSTRAINT CK_Entrada_FormaPago CHECK (
			forma_pago IN ('Efectivo', 'Débito', 'Crédito', 'Transferencia', 'QR')
		)
	);
END
GO

IF NOT EXISTS(
	SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'ventas'
	AND TABLE_NAME = 'TicketVisitante')
BEGIN
	CREATE TABLE ventas.TicketVisitante(
		id_ticket_visitantes INT IDENTITY(1,1) NOT NULL,
		id_entrada INT NOT NULL,
		id_tipo_visitante INT NOT NULL,
		cantidad INT NOT NULL,
		precio_unit DECIMAL(10,2) NOT NULL,
		subtotal DECIMAL(12,2) NOT NULL,

		CONSTRAINT PK_TicketVisitante PRIMARY KEY (id_ticket_visitantes),
		CONSTRAINT FK_TicketVisitante_Entrada FOREIGN KEY (id_entrada)
			REFERENCES ventas.Entrada(id_entrada),
		CONSTRAINT FK_TicketVisitante_TipoVisitante FOREIGN KEY (id_tipo_visitante)
			REFERENCES ventas.TipoVisitante(id_tipo_visitante),
		CONSTRAINT CK_TicketVisitante_CantidadPositiva CHECK (cantidad > 0),
		CONSTRAINT CK_TicketVisitante_PrecioPositivo CHECK (precio_unit >= 0),
		CONSTRAINT UQ_TicketVisitante_TicketTipoVisitante UNIQUE(id_entrada, id_tipo_visitante),
		CONSTRAINT CK_TicketVisitante_Subtotal CHECK (subtotal = cantidad * precio_unit)
	)
END
GO

/*IF NOT EXISTS(
	SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'ventas'
	AND TABLE_NAME = 'RegistroVentas'
)
BEGIN
CREATE TABLE ventas.RegistroVentas(
	id_visita INT IDENTITY(1,1) PRIMARY KEY,
	id_parque INT NULL, --CAMBIAR CUANDO TERMINEN LOS TESTEOS
	region VARCHAR(50) NOT NULL,
	anio INT NOT NULL,
	mes VARCHAR(20) NOT NULL,
	total_visitantes INT NOT NULL DEFAULT 0,
	residentes INT NULL,
	no_residentes INT NULL,
	estado BIT NOT NULL DEFAULT 1,

	CONSTRAINT FK_RegistroVentas_Parque
		FOREIGN KEY (id_parque) REFERENCES parques.Parque(id_parque),
	CONSTRAINT CK_RegistroVentas_Mes
		CHECK(mes BETWEEN 1 AND 12)
)
END
GO*/

-- Ya no sería necesaria porque TicketVisitante permite múltiples tipos de visitantes por ticket y las actividades se hace otro ticket a parte, pero se deja para mantener el historial de la primera entrega
-- IF NOT EXISTS (
-- 	SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'ventas' 
-- 	AND TABLE_NAME = 'DetalleTicket')
-- BEGIN
-- 	CREATE TABLE ventas.DetalleTicket(
-- 		id_detalle INT IDENTITY (1,1) NOT NULL,
-- 		id_ticket INT NOT NULL,
-- 		id_atraccion INT NULL,
-- 		cantidad INT NOT NULL,
-- 		precio_unit DECIMAL(10,2) NOT NULL,
-- 		subtotal DECIMAL(12,2) NOT NULL,
-- 		estado BIT NOT NULL CONSTRAINT DF_detalle_ticket_estado DEFAULT(0),
--
--		CONSTRAINT PK_DetalleTicket PRIMARY KEY (id_detalle),
--		CONSTRAINT FK_DetalleTicket_Ticket FOREIGN KEY (id_ticket)
--			REFERENCES ventas.Ticket(id_ticket),
--		CONSTRAINT FK_DetalleTicket_Atraccion FOREIGN KEY (id_atraccion)
--			REFERENCES actividades.Atraccion(id_atraccion),
--		CONSTRAINT CK_DetalleTicket_CantidadPositiva CHECK (cantidad > 0),
--		CONSTRAINT CK_DetalleTicket_PrecioPositivo CHECK (precio_unit >= 0),
--		CONSTRAINT CK_DetalleTicket_Subtotal CHECK (
--			subtotal = cantidad * precio_unit
--		)
--	);
--END
--GO


-- SCHEMA CONCESIONES

IF NOT EXISTS(
	SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'concesiones'
	AND TABLE_NAME = 'Empresa')
BEGIN
	CREATE TABLE concesiones.Empresa(
		id_empresa INT IDENTITY(1,1) NOT NULL,
		razon_social VARCHAR(150) NOT NULL,
		cuit CHAR(11) NOT NULL, --SIN GUIONES
		contacto VARCHAR(100) NULL,
		estado BIT NOT NULL CONSTRAINT DF_empresa_estado DEFAULT(0),

		CONSTRAINT PK_Empresa PRIMARY KEY (id_empresa),
		CONSTRAINT UQ_Empresa_CUIT UNIQUE(cuit),
		CONSTRAINT CK_Empresa_CUITFormato CHECK(
			cuit NOT LIKE '%[^0-9]%' AND LEN(cuit) = 11
		)
	);
END
GO

IF NOT EXISTS(
	SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'concesiones'
	AND TABLE_NAME = 'Concesion')
BEGIN
	CREATE TABLE concesiones.Concesion(
		id_concesion INT IDENTITY(1,1) NOT NULL,
		id_empresa INT NOT NULL,
		id_parque INT NOT NULL,
		tipo_actividad VARCHAR(100) NOT NULL,
		fecha_inicio DATE NOT NULL,
		fecha_fin DATE NULL,
		valor_alquiler DECIMAL(12,2) NOT NULL,
		estado BIT NOT NULL CONSTRAINT DF_concesion_estado DEFAULT(0),


		CONSTRAINT PK_Concesion PRIMARY KEY(id_concesion),
		CONSTRAINT FK_Concesion_Empresa FOREIGN KEY (id_empresa)
			REFERENCES concesiones.Empresa (id_empresa),
		CONSTRAINT FK_Concesion_Parque FOREIGN KEY (id_parque)
			REFERENCES parques.Parque(id_parque),
		CONSTRAINT CK_Concesion_FechasValidas CHECK(
			fecha_fin IS NULL OR fecha_fin >= fecha_inicio
		),
		CONSTRAINT CK_Concesion_ValorAlquilerPositivo CHECK(
			valor_alquiler > 0
		)
	);
END
GO

IF NOT EXISTS(
	SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'concesiones'
	AND TABLE_NAME = 'PagoConcesion')
BEGIN
	CREATE TABLE concesiones.PagoConcesion(
		id_pago INT IDENTITY(1,1) NOT NULL,
		id_concesion INT NOT NULL,
		periodo DATE NOT NULL,
		monto DECIMAL(12,2) NOT NULL,
		fecha_pago DATE NOT NULL,
		estado BIT NOT NULL CONSTRAINT DF_pago_concesion_estado DEFAULT(0),

		CONSTRAINT PK_PagoConcesion PRIMARY KEY(id_pago),
		CONSTRAINT FK_PagoConcesion_Concesion FOREIGN KEY (id_concesion)
			REFERENCES concesiones.Concesion(id_concesion),
		CONSTRAINT UQ_PagoConcesion_ConcesionPeriodo UNIQUE(id_concesion, periodo),
		CONSTRAINT CK_PagoConcesion_MontoPositivo CHECK (monto > 0)
	);
END
GO

-- SCHEMA IMPORTACION

IF NOT EXISTS (
	SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'importacion'
	AND TABLE_NAME = 'LogImportacion'
)
BEGIN 
	CREATE TABLE importacion.LogImportacion(
		id_log INT IDENTITY(1,1) PRIMARY KEY,
		tipo_archivo VARCHAR(50) NOT NULL,
		nombre_archivo VARCHAR(500) NOT NULL,
		fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
		registros_ok INT NOT NULL DEFAULT 0 CHECK (registros_ok >= 0),
		errores INT NOT NULL DEFAULT 0 CHECK (errores >= 0),
		detalle VARCHAR(500) NULL
	)
END
GO

-- tabla de errores (especificos) en importaciones (evito usar tablas temporales)

IF NOT EXISTS (
	SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'importacion'
	AND TABLE_NAME = 'ErroresImportacion'
)
BEGIN
	CREATE TABLE importacion.ErroresImportacion(
		id_error INT IDENTITY(1,1) PRIMARY KEY,
		id_log INT NOT NULL,
		tipo_archivo VARCHAR(50) NOT NULL,
		registro_origen VARCHAR(500),
		dato1 VARCHAR(500),
		dato2 VARCHAR(500),
		motivo VARCHAR(200) NOT NULL,

		CONSTRAINT FK_ErroresImportacion_Log FOREIGN KEY(id_log)
			REFERENCES importacion.LogImportacion(id_log)
	);
END
GO

