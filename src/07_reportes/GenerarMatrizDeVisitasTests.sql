--	21/06/2026
-- INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
-- Descripcion: Test de generacion de matriz de visitas.

USE ParquesNacionales;
GO

-- CASO 1: año con datos -> debe devolver filas
BEGIN TRY
    EXEC reportes.GenerarMatrizVisitas @anio = 2024;
    PRINT 'CASO 1 OK: matriz generada para 2024';
END TRY
BEGIN CATCH
    PRINT 'CASO 1 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 2: año sin datos -> debe devolver vacío (no error)
BEGIN TRY
    EXEC reportes.GenerarMatrizVisitas @anio = 1995;
    PRINT 'CASO 2 OK: ejecuta sin error (resultado vacío esperado)';
END TRY
BEGIN CATCH
    PRINT 'CASO 2 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 3: año inválido (NULL) -> RECHAZO
BEGIN TRY
    EXEC reportes.GenerarMatrizVisitas @anio = NULL;
    PRINT 'CASO 3 FALLO: no debería haber ejecutado';
END TRY
BEGIN CATCH
    PRINT 'CASO 3 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO

-- CASO 4: año absurdo -> RECHAZO
BEGIN TRY
    EXEC reportes.GenerarMatrizVisitas @anio = 1850;
    PRINT 'CASO 4 FALLO: no debería haber ejecutado';
END TRY
BEGIN CATCH
    PRINT 'CASO 4 OK (rechazo esperado): ' + ERROR_MESSAGE();
END CATCH
GO