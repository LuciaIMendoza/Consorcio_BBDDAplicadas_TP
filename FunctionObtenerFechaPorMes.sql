CREATE FUNCTION dbo.fn_ObtenerFechaPorMes
(
    @Fecha DATE,
    @MesNombre NVARCHAR(20)
)
RETURNS DATE
AS
BEGIN
    DECLARE @Mes INT;

    SELECT @Mes = CASE LOWER(@MesNombre)
        WHEN 'enero' THEN 1
        WHEN 'febrero' THEN 2
        WHEN 'marzo' THEN 3
        WHEN 'abril' THEN 4
        WHEN 'mayo' THEN 5
        WHEN 'junio' THEN 6
        WHEN 'julio' THEN 7
        WHEN 'agosto' THEN 8
        WHEN 'septiembre' THEN 9
        WHEN 'octubre' THEN 10
        WHEN 'noviembre' THEN 11
        WHEN 'diciembre' THEN 12
    END;

    RETURN DATEFROMPARTS(YEAR(@Fecha), @Mes, 1);
END;
GO
