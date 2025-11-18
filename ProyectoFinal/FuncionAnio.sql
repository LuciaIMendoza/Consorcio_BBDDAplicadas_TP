USE AltosSaintJust
go

CREATE FUNCTION csc.fn_AnioAnterior
(
	@mes INT,
    @anio INT
)
RETURNS INT
AS
BEGIN
    RETURN (
        CASE 
            WHEN @mes = 1 THEN @anio -1
            ELSE @anio
        END
    );
END;