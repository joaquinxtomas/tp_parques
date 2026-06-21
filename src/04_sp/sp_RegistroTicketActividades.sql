--	21/06/2026
-- INTEGRANTES: Jimenez Mauricio, Palacios Joaquin, Kamegawa Tomas, Patri Juan Tiago
-- Descripcion: Creacion de SP de registro de actividades con logica de negocio

Use ParquesNacionales
GO

CREATE OR ALTER PROCEDURE actividades.RegistrarTicketActividad
	@id_atraccion INT,
	@cantidad INT ,
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

	DECLARE @v_errores VARCHAR (MAX) = '';
	DECLARE @v_costo DECIMAL (10,2);
	DECLARE @v_cupo INT;
	DECLARE @v_estado BIT;
	DECLARE @v_existe BIT = 0;
	DECLARE @v_ocupado INT;
	DECLARE @v_subtotal DECIMAL (12,2);
	DECLARE @v_fecha DATETIME2(0)= SYSDATETIME();

BEGIN TRANSACTION
BEGIN TRY
	-- (a) cantidad positiva
    IF @cantidad IS NULL OR @cantidad <= 0
		SET @v_errores += '- La cantidad debe ser mayor a cero.';

	SELECT @v_costo  = costo,
           @v_cupo   = cupo_maximo,
           @v_estado = estado,
           @v_existe = 1 -- me indica si encontro la atraccion 
	FROM actividades.Atraccion WHERE id_atraccion = @id_atraccion;

	IF @v_existe = 0
		SET @v_errores += 'La atraccion no existe. ';
    ELSE IF @v_estado = 1
		SET @v_errores += 'La atraccion esta dada de baja. ';

	IF @v_existe = 1 AND @v_estado = 0 AND @cantidad > 0 AND @v_cupo IS NOT NULL 
	-- si existe el ticket, atraccion activa, cantidad valida y tiene cupo definido, chequeo cuantos cupos ya voy ocupados hoy
	BEGIN -- CALCULO LA CANTIDAD DE CUPOS ACTUALMENTE PARA EL DIA DE HOY
		SELECT @v_ocupado = ISNULL(SUM(cantidad), 0)
		FROM   actividades.TicketsAtraccion
		WHERE  id_atraccion = @id_atraccion
		AND  fecha >= CAST(@v_fecha AS DATE) -- casteo la fecha solo como dia -- ej: 21/6/26 00:00 hs
		AND  fecha <  DATEADD(DAY, 1, CAST(@v_fecha AS DATE))  -- casteo tmb como dia y le sumo 1 dia-- 22/6/26 00:00
		AND  estado = 0;  
		IF @v_usado + @cantidad > @v_cupo
                SET @v_errores += 'Cupo insuficiente para la jornada. Disponible: '
                    + CAST(@v_cupo - @v_usado AS VARCHAR(10))
                    + ', solicitado: ' + CAST(@cantidad AS VARCHAR(10)) + '. ';
   END
   IF @v_errores <> '' -- si hubo errores, cierro la transaccion antes de salir
   BEGIN
       ROLLBACK TRANSACTION;
	   RAISERROR(@v_errores, 16, 1);
       RETURN;
   END
       SET @v_subtotal = @cantidad * @v_costo;

	   INSERT INTO actividades.TicketsAtraccion (id_atraccion, fecha, cantidad, subtotal)
       VALUES (@id_atraccion, @v_fecha, @cantidad, @v_subtotal);

COMMIT TRANSACTION;
END TRY
BEGIN CATCH 
	IF @@TRANCOUNT > 0
       ROLLBACK TRANSACTION;

    DECLARE @v_msg VARCHAR(MAX) = ERROR_MESSAGE();
    DECLARE @v_sev INT          = ERROR_SEVERITY();
    DECLARE @v_est INT          = ERROR_STATE();
    RAISERROR(@v_msg, @v_sev, @v_est);
    RETURN;
END CATCH;
END