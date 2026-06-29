-- ============================================================
-- FECHA: 28/06/2026
-- INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
-- Descripción: Testing del Reporte 5 - Parques y concesiones (XML).
--              Verifica ejecución sin error y contrasta el contenido
--              contra una consulta de control plana.
-- ============================================================
USE ParquesNacionales;
GO

-- ============================================================
-- CASO 1: el reporte ejecuta sin error y devuelve XML
-- Esperado: OK, se muestra el XML de parques y concesiones
-- ============================================================
BEGIN TRY
    EXEC reportes.ReporteParquesConcesionesGenerar;
    PRINT 'CASO 1 OK: el reporte se ejecutó y devolvió resultado';
END TRY
BEGIN CATCH
    PRINT 'CASO 1 ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- CASO 2: CONTROL - cuántos parques deberían aparecer
-- El reporte solo lista parques con al menos una concesión activa.
-- Esperado: este número debe coincidir con la cantidad de <Parque>
-- del XML (con tus datos: 6 parques).
-- ============================================================
SELECT COUNT(DISTINCT c.id_parque) AS parques_con_concesiones_esperados
FROM concesiones.Concesion c
WHERE c.estado = 0;
GO

-- ============================================================
-- CASO 3: CONTROL / EVIDENCIA - detalle plano de lo que debe
-- mostrar el XML (parque + sus concesiones activas).
-- Sirve para corroborar a ojo contra el XML: mismos parques,
-- mismos titulares, mismas concesiones.
-- Nahuel Huapi debe aparecer con 2 filas (vector de 2 elementos).
-- ============================================================
SELECT
    p.nombre          AS parque,
    e.razon_social    AS titular,
    c.tipo_actividad  AS servicio,
    c.fecha_inicio,
    c.fecha_fin,
    c.valor_alquiler
FROM parques.Parque p
INNER JOIN concesiones.Concesion c ON c.id_parque  = p.id_parque AND c.estado = 0
INNER JOIN concesiones.Empresa e   ON e.id_empresa = c.id_empresa
WHERE p.estado = 0
ORDER BY p.nombre, c.fecha_inicio;
GO

-- ============================================================
-- CASO 4: CONTROL - parques con MÁS de una concesión
-- Verifica que el "vector anidado" realmente agrupe varios
-- elementos bajo un mismo parque.
-- Esperado: Nahuel Huapi con 2 concesiones.
-- ============================================================
SELECT
    p.nombre                AS parque,
    COUNT(*)                AS cant_concesiones
FROM parques.Parque p
INNER JOIN concesiones.Concesion c ON c.id_parque = p.id_parque AND c.estado = 0
WHERE p.estado = 0
GROUP BY p.nombre
HAVING COUNT(*) > 1
ORDER BY p.nombre;
GO