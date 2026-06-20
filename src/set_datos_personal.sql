-- =========================================================================
-- 1. INSERTS PARA LA TABLA: [parques].[TipoParque]
-- =========================================================================
INSERT INTO [parques].[TipoParque] ([descripcion]) 
VALUES ('Parque Nacional');

INSERT INTO [parques].[TipoParque] ([descripcion]) 
VALUES ('Reserva Provincial');

INSERT INTO [parques].[TipoParque] ([descripcion]) 
VALUES ('Monumento Natural');


-- =========================================================================
-- 2. INSERTS PARA LA TABLA: [parques].[Parque]
-- =========================================================================
INSERT INTO [parques].[Parque] ([nombre], [id_tipo_parque], [ubicacion], [latitud], [longitud], [superficie])
VALUES ('Parque Nacional Iguazú', 1, 'Misiones, Argentina', -25.677500, -54.440278, 67720.00);

INSERT INTO [parques].[Parque] ([nombre], [id_tipo_parque], [ubicacion], [latitud], [longitud], [superficie])
VALUES ('Reserva Esteros del Iberá', 2, 'Corrientes, Argentina', -28.533333, -57.166667, 195500.50);

INSERT INTO [parques].[Parque] ([nombre], [id_tipo_parque], [ubicacion], [latitud], [longitud], [superficie])
VALUES ('Parque Nacional Los Glaciares', 1, 'Santa Cruz, Argentina', -50.500000, -73.250000, 726927.00);


-- =========================================================================
-- 3. INSERTS PARA LA TABLA: [personal].[Guardaparque]
-- =========================================================================
INSERT INTO [personal].[Guardaparque] ([nombre], [dni], [vigencia_desde], [vigencia_hasta], [activo])
VALUES ('Carlos Gómez', '32456789', '2020-01-15', '2028-12-31', 1);

INSERT INTO [personal].[Guardaparque] ([nombre], [dni], [vigencia_desde], [vigencia_hasta], [activo])
VALUES ('María Rodríguez', '35123456', '2022-03-01', '2027-03-01', 1);

INSERT INTO [personal].[Guardaparque] ([nombre], [dni], [vigencia_desde], [vigencia_hasta], [activo])
VALUES ('Jorge Altieri', '28999111', '2015-06-10', '2025-06-10', 0);


-- =========================================================================
-- 4. INSERTS PARA LA TABLA: [personal].[GuiaAutorizado]
-- =========================================================================
INSERT INTO [personal].[GuiaAutorizado] ([nombre], [dni], [especialidad], [titulo], [vigencia_desde], [vigencia_hasta])
VALUES ('Laura Benítez', '38444555', 'Trekking y Alta Montaña', 'Guía Profesional de Turismo', '2024-01-01', '2027-01-01');

INSERT INTO [personal].[GuiaAutorizado] ([nombre], [dni], [especialidad], [titulo], [vigencia_desde], [vigencia_hasta])
VALUES ('Diego Álvarez', '40111222', 'Avistaje de Aves y Fauna', 'Técnico en Biología', '2025-05-10', '2028-05-10');

INSERT INTO [personal].[GuiaAutorizado] ([nombre], [dni], [especialidad], [titulo], [vigencia_desde], [vigencia_hasta])
VALUES ('Ana Martínez', '33777888', 'Paseos Náuticos', 'Guía Naval Avanzado', '2023-08-20', '2026-08-20');


-- =========================================================================
-- 5. INSERTS PARA LA TABLA: [personal].[AsignacionGP]
-- =========================================================================

-- Solo Guardaparque
INSERT INTO [personal].[AsignacionGP] ([id_guardaparque], [id_parque], [id_guia], [fecha_desde], [fecha_hasta], [motivo])
VALUES (1, 1, NULL, '2026-01-01', '2026-06-30', 'Campaña de Verano y control de senderos');

INSERT INTO [personal].[AsignacionGP] ([id_guardaparque], [id_parque], [id_guia], [fecha_desde], [fecha_hasta], [motivo])
VALUES (2, 2, NULL, '2026-03-15', '2026-09-15', 'Monitoreo de fauna protegida');

-- Solo Guía
INSERT INTO [personal].[AsignacionGP] ([id_guardaparque], [id_parque], [id_guia], [fecha_desde], [fecha_hasta], [motivo])
VALUES (NULL, 3, 3, '2026-07-01', '2026-12-31', 'Refuerzo de temporada invernal en glaciares');