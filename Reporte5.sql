USE AltosSaintJust;
GO

CREATE OR ALTER PROCEDURE csc.p_ReportePropietariosMorosos
    @ConsorcioID INT = NULL,
    @Anio INT = NULL,
    @Mes INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @http INT, @json NVARCHAR(MAX), @url NVARCHAR(200) = 'https://api.bluelytics.com.ar/v2/latest';
    DECLARE @DolarBlue DECIMAL(10,2);

    BEGIN TRY
        EXEC sp_OACreate 'MSXML2.XMLHTTP', @http OUT;
        EXEC sp_OAMethod @http, 'open', NULL, 'GET', @url, 'false';
        EXEC sp_OAMethod @http, 'send';
        EXEC sp_OAGetProperty @http, 'responseText', @json OUT;
        EXEC sp_OADestroy @http;

        SELECT @DolarBlue = TRY_CAST(JSON_VALUE(@json, '$.blue.value_sell') AS DECIMAL(10,2));
    END TRY
    BEGIN CATCH
        SET @DolarBlue = NULL;
    END CATCH;

    IF @DolarBlue IS NULL
        SET @DolarBlue = 1000; -- valor de respaldo si la API falla


    SELECT TOP 3
        p.apellido + ', ' + p.nombre AS Propietario,
        p.DNI,
        p.mail,
        p.telefono,
        p.modoEntrega,
        c.nombre AS Consorcio,
        SUM(ISNULL(ec.deuda, 0) + ISNULL(ec.InteresesPorMora, 0)) AS TotalAdeudado_Pesos,
        ROUND(SUM(ISNULL(ec.deuda, 0) + ISNULL(ec.InteresesPorMora, 0)) / @DolarBlue, 2) AS TotalAdeudado_Dolares,
        @DolarBlue AS CotizacionDolar
    FROM csc.Propietario p
    INNER JOIN csc.Unidad_Funcional uf ON p.unidadFuncionalID = uf.unidadFuncionalID
    INNER JOIN csc.Consorcio c ON uf.consorcioID = c.consorcioID
    INNER JOIN csc.Estado_Cuentas ec ON ec.unidadFuncionalID = uf.unidadFuncionalID
    INNER JOIN csc.Expensas e ON e.documentoID = ec.documentoID
    WHERE (@ConsorcioID IS NULL OR c.consorcioID = @ConsorcioID)
      AND (@Anio IS NULL OR e.anio = @Anio)
      AND (@Mes IS NULL OR e.mes = @Mes)
    GROUP BY 
        p.apellido, p.nombre, p.DNI, p.mail, p.telefono, p.modoEntrega, c.nombre
    ORDER BY TotalAdeudado_Pesos DESC;
END;
GO

-- Ejemplo 1: todos los consorcios, todos los años
--EXEC csc.p_ReportePropietariosMorosos;

-- Ejemplo 2: filtrando por consorcio específico
--EXEC csc.p_ReportePropietariosMorosos @ConsorcioID = 2;

-- Ejemplo 3: filtrando por año y mes
--EXEC csc.p_ReportePropietariosMorosos @Anio = 2025, @Mes = 10;

--select * from csc.Estado_Cuentas
