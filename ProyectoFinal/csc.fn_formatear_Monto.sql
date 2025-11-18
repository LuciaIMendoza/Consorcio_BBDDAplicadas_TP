USE AltosSaintJust
GO

create or alter function csc.formatear_Monto(@monto NVARCHAR(50))
RETURNS DECIMAL(18,2)
AS
BEGIN
	--Cuenta comas en la cadena
	DECLARE @cantComas INT = LEN(@monto) - LEN(REPLACE(@monto, ',', ''));

	--Mas de 1 coma elimina la primera y reemplaza la restante por un punto
	IF @cantComas > 1
	BEGIN
		SET @monto = STUFF(@monto, CHARINDEX(',', @monto), LEN(','), '')
		SET @monto = REPLACE(REPLACE(@monto, '.', ''), ',', '.')
	END;
	ELSE 
	BEGIN
		--si hay al menos un punto o una coma
		IF CHARINDEX('.', @monto) > 0 AND CHARINDEX(',', @monto) > 0
		BEGIN
			 IF CHARINDEX('.', @monto) < CHARINDEX(',', @monto) 
				SET @monto = REPLACE(REPLACE(@monto, '.', ''), ',', '.')
			ELSE
				SET @monto = REPLACE(@monto, ',', '');
		END
		ELSE --Si no hay al menos un punto o una coma, cero
		BEGIN 
		SET @monto = 0 
		END
		
	END

    RETURN CAST(@monto AS DECIMAL(18,2));
END;


--select csc.formatear_Monto('12,000.0')
--select csc.formatear_Monto('12.000,0')
--select csc.formatear_Monto('12,000,0')
--select csc.formatear_Monto('12.000.0')