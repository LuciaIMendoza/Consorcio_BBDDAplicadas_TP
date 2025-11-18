USE AltosSaintJust
GO

CREATE FUNCTION csc.fn_MesAnterior
(
    @mes INT
)
RETURNS INT
AS
BEGIN
    RETURN (
        CASE 
            WHEN @mes = 1 THEN 12
            ELSE @mes - 1
        END
    );
END;