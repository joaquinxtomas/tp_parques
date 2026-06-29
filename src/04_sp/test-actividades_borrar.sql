-- =============================================
-- SCRIPTS TESTING - ATRACCION
-- =============================================

USE ParquesNacionales;
GO

-- PRECONDICIONES: asegurar que existan datos base
EXEC parques.InsertarTipoDeParque 'Parque Nacional';

IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = 'Parque Nacional Iguazu')
    INSERT INTO parques.Parque (nombre, id_tipo_parque, region)
    VALUES ('Parque Nacional Iguazu',
            (SELECT id_tipo_parque FROM parques.TipoParque WHERE descripcion = 'Parque Nacional'),
            'Litoral');

IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = 'Parque Nacional Nahuel Huapi')
    INSERT INTO parques.Parque (nombre, id_tipo_parque, region)
    VALUES ('Parque Nacional Nahuel Huapi',
            (SELECT id_tipo_parque FROM parques.TipoParque WHERE descripcion = 'Parque Nacional'),
            'Cuyo');
GO

-- =============================================
-- InsertarAtraccion
-- =============================================

-- CASO 1: inserción normal
BEGIN TRY
    DECLARE @id_p INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Iguazu');
    EXEC actividades.InsertarAtraccion
        @id_parque = @id_p, @nombre = 'Paseo por la Garganta del Diablo',
        @costo = 5000.00, @duracion = 90, @cupo_maximo = 25, @tipo = 'Senderismo';
    PRINT 'CASO 1 OK: atracción insertada';
END TRY
BEGIN CATCH
    PRINT 'CASO 1 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 2: insertar con costo 0 (gratuita)
BEGIN TRY
    DECLARE @id_p INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Iguazu');
    EXEC actividades.InsertarAtraccion
        @id_parque = @id_p, @nombre = 'Mirador Salto Bossetti',
        @costo = 0.00, @duracion = 30, @cupo_maximo = NULL, @tipo = 'Avistaje';
    PRINT 'CASO 2 OK: atracción gratuita insertada';
END TRY
BEGIN CATCH
    PRINT 'CASO 2 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 3: insertar con duración y cupo NULL
BEGIN TRY
    DECLARE @id_p INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Nahuel Huapi');
    EXEC actividades.InsertarAtraccion
        @id_parque = @id_p, @nombre = 'Acceso libre al Cerro Campanario',
        @costo = 0.00, @duracion = NULL, @cupo_maximo = NULL, @tipo = 'Senderismo';
    PRINT 'CASO 3 OK: atracción con NULLs insertada';
END TRY
BEGIN CATCH
    PRINT 'CASO 3 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 4: mismo nombre en otro parque (debe funcionar)
BEGIN TRY
    DECLARE @id_p INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Nahuel Huapi');
    EXEC actividades.InsertarAtraccion
        @id_parque = @id_p, @nombre = 'Paseo por la Garganta del Diablo',
        @costo = 3500.00, @duracion = 60, @cupo_maximo = 20, @tipo = 'Senderismo';
    PRINT 'CASO 4 OK: mismo nombre en otro parque insertado';
END TRY
BEGIN CATCH
    PRINT 'CASO 4 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 5: nombre duplicado en el mismo parque → error
BEGIN TRY
    DECLARE @id_p INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Iguazu');
    EXEC actividades.InsertarAtraccion
        @id_parque = @id_p, @nombre = 'Paseo por la Garganta del Diablo',
        @costo = 5500.00, @duracion = 90, @cupo_maximo = 25, @tipo = 'Senderismo';
    PRINT 'CASO 5 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 5 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 6: parque inexistente → error
BEGIN TRY
    EXEC actividades.InsertarAtraccion
        @id_parque = 99999, @nombre = 'Atraccion en parque fantasma',
        @costo = 1000.00, @duracion = 45, @cupo_maximo = 15, @tipo = 'Cultural';
    PRINT 'CASO 6 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 6 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- ver lo que quedó cargado
SELECT a.id_atraccion, p.nombre AS parque, a.nombre AS atraccion,
       a.costo, a.duracion AS duracion_min, a.cupo_maximo, a.tipo
FROM actividades.Atraccion a
INNER JOIN parques.Parque p ON p.id_parque = a.id_parque
ORDER BY a.id_atraccion;
GO

-- =============================================
-- ActualizarAtraccion
-- =============================================

-- limpieza
DELETE FROM actividades.Atraccion WHERE nombre LIKE 'TEST_%';
GO

-- prerequisitos
BEGIN TRY
    DECLARE @id_ig INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Iguazu');
    DECLARE @id_na INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Nahuel Huapi');
    EXEC actividades.InsertarAtraccion @id_ig, 'TEST_Sendero', 1000, 60, 20, 'Senderismo';
    EXEC actividades.InsertarAtraccion @id_ig, 'TEST_Mirador', 0, 30, NULL, 'Avistaje';
    EXEC actividades.InsertarAtraccion @id_na, 'TEST_Kayak', 2500, 90, 10, 'Acuatica';
    PRINT 'PREREQUISITOS MODIFICACION OK';
END TRY
BEGIN CATCH
    PRINT 'PREREQUISITOS MODIFICACION ERROR: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 7: modificación válida, cambia costo y duración
BEGIN TRY
    DECLARE @id INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Sendero');
    EXEC actividades.ActualizarAtraccion
        @id_atraccion = @id, @nombre = 'TEST_Sendero',
        @costo = 1500, @duracion = 75, @cupo_maximo = 20, @tipo = 'Senderismo';
    PRINT 'CASO 7 OK: costo y duración actualizados';
END TRY
BEGIN CATCH
    PRINT 'CASO 7 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 8: cambio de nombre
BEGIN TRY
    DECLARE @id INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Mirador');
    EXEC actividades.ActualizarAtraccion
        @id_atraccion = @id, @nombre = 'TEST_Mirador Renovado',
        @costo = 0, @duracion = 30, @cupo_maximo = NULL, @tipo = 'Avistaje';
    PRINT 'CASO 8 OK: nombre actualizado';
END TRY
BEGIN CATCH
    PRINT 'CASO 8 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 9: id de atracción inexistente → error
BEGIN TRY
    EXEC actividades.ActualizarAtraccion
        @id_atraccion = 99999, @nombre = 'Fantasma',
        @costo = 100, @duracion = 30, @cupo_maximo = 10, @tipo = 'Senderismo';
    PRINT 'CASO 9 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 9 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 10: nombre duplicado pero en otro parque (debe funcionar)
BEGIN TRY
    DECLARE @id INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Sendero');
    EXEC actividades.ActualizarAtraccion
        @id_atraccion = @id, @nombre = 'TEST_Kayak',
        @costo = 1500, @duracion = 75, @cupo_maximo = 20, @tipo = 'Senderismo';
    PRINT 'CASO 10 OK: nombre duplicado en otro parque permitido';
END TRY
BEGIN CATCH
    PRINT 'CASO 10 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 11: nombre existente en otro parque (debe funcionar)
BEGIN TRY
    DECLARE @id INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Kayak'
        AND id_parque = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Nahuel Huapi'));
    EXEC actividades.ActualizarAtraccion
        @id_atraccion = @id, @nombre = 'TEST_Mirador Renovado',
        @costo = 2500, @duracion = 90, @cupo_maximo = 10, @tipo = 'Acuatica';
    PRINT 'CASO 11 OK: nombre de otro parque permitido';
END TRY
BEGIN CATCH
    PRINT 'CASO 11 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 12: múltiples errores (nombre vacío, costo negativo, duración negativa, cupo 0, tipo vacío) → error
BEGIN TRY
    DECLARE @id INT = (SELECT TOP 1 id_atraccion FROM actividades.Atraccion WHERE nombre LIKE 'TEST_%'
        AND id_parque = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Iguazu'));
    EXEC actividades.ActualizarAtraccion
        @id_atraccion = @id, @nombre = '',
        @costo = -100, @duracion = -5, @cupo_maximo = 0, @tipo = '';
    PRINT 'CASO 12 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 12 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- =============================================
-- EliminarAtraccion
-- =============================================

-- CASO 13: baja correcta
BEGIN TRY
    DECLARE @id INT = (SELECT MIN(id_atraccion) FROM actividades.Atraccion WHERE estado = 0);
    EXEC actividades.EliminarAtraccion @id_atraccion = @id;
    PRINT 'CASO 13 OK: atracción dada de baja';
END TRY
BEGIN CATCH
    PRINT 'CASO 13 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 14: atracción inexistente → error
BEGIN TRY
    EXEC actividades.EliminarAtraccion @id_atraccion = 99999;
    PRINT 'CASO 14 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 14 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 15: ya dada de baja → error
BEGIN TRY
    DECLARE @id INT = (SELECT MIN(id_atraccion) FROM actividades.Atraccion WHERE estado = 1);
    EXEC actividades.EliminarAtraccion @id_atraccion = @id;
    PRINT 'CASO 15 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 15 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- ver cómo quedó la tabla
SELECT id_atraccion, nombre, costo, duracion, cupo_maximo, tipo, estado
FROM actividades.Atraccion
WHERE nombre LIKE 'TEST_%'
ORDER BY id_atraccion;
GO

-- =============================================
-- SCRIPTS TESTING - TOURGUIA
-- =============================================

USE ParquesNacionales;
GO

PRINT('--------- TESTS TOUR GUIA ----------');

-- PRECONDICIONES (ejecutar una sola vez)
DECLARE @id_iguazu INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Nacional Iguazu');

IF NOT EXISTS (SELECT 1 FROM personal.GuiaAutorizado WHERE dni = '11111111')
    INSERT INTO personal.GuiaAutorizado (nombre, dni, especialidad, titulo, vigencia_desde)
    VALUES ('Guia Test 1', '11111111', 'Flora', 'Licenciado', '2024-01-01');

IF NOT EXISTS (SELECT 1 FROM personal.GuiaAutorizado WHERE dni = '22222222')
    INSERT INTO personal.GuiaAutorizado (nombre, dni, especialidad, titulo, vigencia_desde)
    VALUES ('Guia Test 2', '22222222', 'Fauna', NULL, '2024-01-01');

IF NOT EXISTS (SELECT 1 FROM actividades.Atraccion WHERE nombre = 'TEST_Tour_Selva')
    EXEC actividades.InsertarAtraccion @id_iguazu, 'TEST_Tour_Selva', 3000, 120, 15, 'Senderismo';
GO

-- =============================================
-- InsertarTourGuia
-- =============================================

-- CASO 1: asignar guía a atracción
BEGIN TRY
    DECLARE @id_tour INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Tour_Selva');
    DECLARE @id_guia INT = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni = '11111111');
    EXEC actividades.InsertarTourGuia @id_atraccion = @id_tour, @id_guia = @id_guia;
    PRINT 'CASO 1 OK: guía asignado a atracción';
END TRY
BEGIN CATCH
    PRINT 'CASO 1 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 2: asignar segundo guía a la misma atracción
BEGIN TRY
    DECLARE @id_tour INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Tour_Selva');
    DECLARE @id_guia INT = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni = '22222222');
    EXEC actividades.InsertarTourGuia @id_atraccion = @id_tour, @id_guia = @id_guia;
    PRINT 'CASO 2 OK: segundo guía asignado';
END TRY
BEGIN CATCH
    PRINT 'CASO 2 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 3: guía ya asignado (duplicado) → error
BEGIN TRY
    DECLARE @id_tour INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Tour_Selva');
    DECLARE @id_guia INT = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni = '11111111');
    EXEC actividades.InsertarTourGuia @id_atraccion = @id_tour, @id_guia = @id_guia;
    PRINT 'CASO 3 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 3 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 4: guía inexistente → error
BEGIN TRY
    DECLARE @id_tour INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Tour_Selva');
    EXEC actividades.InsertarTourGuia @id_atraccion = @id_tour, @id_guia = 99999;
    PRINT 'CASO 4 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 4 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 5: atracción inexistente → error
BEGIN TRY
    DECLARE @id_guia INT = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni = '11111111');
    EXEC actividades.InsertarTourGuia @id_atraccion = 99999, @id_guia = @id_guia;
    PRINT 'CASO 5 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 5 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 6: ambos NULL → error
BEGIN TRY
    EXEC actividades.InsertarTourGuia @id_atraccion = NULL, @id_guia = NULL;
    PRINT 'CASO 6 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 6 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- verificar altas
SELECT tg.id_tour_guia, a.nombre AS atraccion, g.nombre AS guia, tg.estado
FROM actividades.TourGuia tg
INNER JOIN actividades.Atraccion a ON a.id_atraccion = tg.id_atraccion
INNER JOIN personal.GuiaAutorizado g ON g.id_guia = tg.id_guia
WHERE a.nombre = 'TEST_Tour_Selva';
GO

-- =============================================
-- EliminarTourGuia
-- =============================================

-- CASO 7: baja válida
BEGIN TRY
    DECLARE @id INT = (
        SELECT TOP 1 id_tour_guia FROM actividades.TourGuia
        WHERE id_guia = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni = '11111111')
          AND estado = 0
    );
    EXEC actividades.EliminarTourGuia @id_tour_guia = @id;
    PRINT 'CASO 7 OK: tour dado de baja';
END TRY
BEGIN CATCH
    PRINT 'CASO 7 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 8: ya dada de baja → error
BEGIN TRY
    DECLARE @id INT = (
        SELECT TOP 1 id_tour_guia FROM actividades.TourGuia
        WHERE id_guia = (SELECT id_guia FROM personal.GuiaAutorizado WHERE dni = '11111111')
          AND estado = 1
    );
    EXEC actividades.EliminarTourGuia @id_tour_guia = @id;
    PRINT 'CASO 8 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 8 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 9: tour inexistente → error
BEGIN TRY
    EXEC actividades.EliminarTourGuia @id_tour_guia = 99999;
    PRINT 'CASO 9 FALLO';
END TRY
BEGIN CATCH
    PRINT 'CASO 9 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- verificar bajas
SELECT tg.id_tour_guia, a.nombre AS atraccion, g.nombre AS guia, tg.estado
FROM actividades.TourGuia tg
INNER JOIN actividades.Atraccion a ON a.id_atraccion = tg.id_atraccion
INNER JOIN personal.GuiaAutorizado g ON g.id_guia = tg.id_guia
WHERE a.nombre = 'TEST_Tour_Selva';
GO