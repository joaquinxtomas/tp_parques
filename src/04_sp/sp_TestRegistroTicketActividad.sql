-- 21/06/2026
-- INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
-- Descripcion: Script de testing de los SP de registro/cancelacion de actividades

USE ParquesNacionales;
GO

EXEC parques.InsertarTipoDeParque @descripcion = 'Tipo Test Tickets'; -- creo un tipo de parque de prueba
GO

DECLARE @id_tipo INT = (SELECT id_tipo_parque FROM parques.TipoParque
                        WHERE descripcion = 'Tipo Test Tickets');

IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE nombre = 'Parque Test Tickets') -- creo un parque de preuba 
    EXEC parques.InsertarParque
        @nombre = 'Parque Test Tickets',
        @id_tipo_parque = @id_tipo;
GO

DECLARE @id_parque INT = (SELECT id_parque FROM parques.Parque WHERE nombre = 'Parque Test Tickets'); -- almaceno el id del parque

IF NOT EXISTS (SELECT 1 FROM actividades.Atraccion WHERE nombre = 'TEST_Cupo10')
    INSERT INTO actividades.Atraccion (id_parque, nombre, costo, duracion, cupo_maximo, tipo)
    VALUES (@id_parque, 'TEST_Cupo10', 1000.00, 60, 10, 'paga');

IF NOT EXISTS (SELECT 1 FROM actividades.Atraccion WHERE nombre = 'TEST_DeBaja')
    INSERT INTO actividades.Atraccion (id_parque, nombre, costo, duracion, cupo_maximo, tipo, estado)
    VALUES (@id_parque, 'TEST_DeBaja', 500.00, 30, 20, 'paga', 1);

IF NOT EXISTS (SELECT 1 FROM actividades.Atraccion WHERE nombre = 'TEST_SinLimite')
    INSERT INTO actividades.Atraccion (id_parque, nombre, costo, duracion, cupo_maximo, tipo)
    VALUES (@id_parque, 'TEST_SinLimite', 0.00, NULL, NULL, 'gratuita');



PRINT 'Precondiciones cargadas.';
GO

SELECT * FROM actividades.Atraccion;
-- ============================================================
-- CASO 1: Contratacion valida (4 sobre cupo 10) -> OK
-- ============================================================
BEGIN TRY
    DECLARE @a1 INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Cupo10');
    EXEC actividades.RegistrarTicketActividad @id_atraccion = @a1, @cantidad = 4;
    PRINT 'CASO 1 OK: registro insertado (4 de 10)';
END TRY
BEGIN CATCH
    PRINT 'CASO 1 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO
-- ============================================================
-- CASO 2: Completar cupo justo (6 mas, total 10 de 10) -> OK
-- ============================================================
BEGIN TRY
    DECLARE @a2 INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Cupo10');
    EXEC actividades.RegistrarTicketActividad @id_atraccion = @a2, @cantidad = 6;
    PRINT 'CASO 2 OK: cupo completado justo (10 de 10)';
END TRY
BEGIN CATCH
    PRINT 'CASO 2 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- CASO 3: Pasarse del cupo (1 mas con 10 de 10) -> RECHAZO
-- ============================================================
BEGIN TRY
    DECLARE @a3 INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Cupo10');
    EXEC actividades.RegistrarTicketActividad @id_atraccion = @a3, @cantidad = 1;
    PRINT 'CASO 3 FALLO: no deberia haber registrado';
END TRY
BEGIN CATCH
    PRINT 'CASO 3 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- CASO 4: Atraccion inexistente -> RECHAZO
-- ============================================================
BEGIN TRY
    EXEC actividades.RegistrarTicketActividad @id_atraccion = 999999, @cantidad = 2;
    PRINT 'CASO 4 FALLO: no deberia haber registrado';
END TRY
BEGIN CATCH
    PRINT 'CASO 4 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- CASO 5: Cantidad invalida (cero) -> RECHAZO
-- ============================================================
BEGIN TRY
    DECLARE @a5 INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Cupo10');
    EXEC actividades.RegistrarTicketActividad @id_atraccion = @a5, @cantidad = 0;
    PRINT 'CASO 5 FALLO: no deberia haber registrado';
END TRY
BEGIN CATCH
    PRINT 'CASO 5 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- CASO 6: Atraccion dada de baja -> RECHAZO
-- ============================================================
BEGIN TRY
    DECLARE @a6 INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_DeBaja');
    EXEC actividades.RegistrarTicketActividad @id_atraccion = @a6, @cantidad = 2;
    PRINT 'CASO 6 FALLO: no deberia haber registrado';
END TRY
BEGIN CATCH
    PRINT 'CASO 6 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- CASO 7: Atraccion con cupo NULL (sin limite) -> OK
-- ============================================================
BEGIN TRY
    DECLARE @a7 INT = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_SinLimite');
    EXEC actividades.RegistrarTicketActividad @id_atraccion = @a7, @cantidad = 9999;
    PRINT 'CASO 7 OK: registrado sin limite de cupo';
END TRY
BEGIN CATCH
    PRINT 'CASO 7 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

select * from actividades.TicketsAtraccion

-- Verificacion intermedia: registros de la atraccion con cupo 10
SELECT id_ticket_atraccion, id_atraccion, fecha, cantidad, subtotal, estado
FROM   actividades.TicketsAtraccion
WHERE  id_atraccion = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Cupo10')
ORDER BY id_ticket_atraccion;
GO

-- ============================================================
-- CASO 8: Cancelar un registro existente -> OK
-- ============================================================
BEGIN TRY
    DECLARE @tk INT = (
        SELECT MIN(id_ticket_atraccion) FROM actividades.TicketsAtraccion
        WHERE id_atraccion = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Cupo10')
          AND estado = 0
    );
    EXEC actividades.CancelarTicketActividad @id_ticketAtraccion = @tk;
    PRINT 'CASO 8 OK: registro cancelado (estado = 1)';
END TRY
BEGIN CATCH
    PRINT 'CASO 8 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- CASO 9: Cancelar un registro ya dado de baja -> RECHAZO
-- ============================================================
BEGIN TRY
    DECLARE @tk2 INT = (
        SELECT MIN(id_ticket_atraccion) FROM actividades.TicketsAtraccion
        WHERE id_atraccion = (SELECT id_atraccion FROM actividades.Atraccion WHERE nombre = 'TEST_Cupo10')
          AND estado = 1
    );
    EXEC actividades.CancelarTicketActividad @id_ticketAtraccion = @tk2;
    PRINT 'CASO 9 FALLO: no deberia haber cancelado';
END TRY
BEGIN CATCH
    PRINT 'CASO 9 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- CASO 10: Cancelar un registro inexistente -> RECHAZO
-- ============================================================
BEGIN TRY
    EXEC actividades.CancelarTicketActividad @id_ticketAtraccion = 999999;
    PRINT 'CASO 10 FALLO: no deberia haber cancelado';
END TRY
BEGIN CATCH
    PRINT 'CASO 10 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- Verificacion final
SELECT id_ticket_atraccion, id_atraccion, cantidad, subtotal, estado
FROM   actividades.TicketsAtraccion
WHERE  id_atraccion IN (
        SELECT id_atraccion FROM actividades.Atraccion
        WHERE nombre IN ('TEST_Cupo10', 'TEST_SinLimite'))
ORDER BY id_ticket_atraccion;
GO