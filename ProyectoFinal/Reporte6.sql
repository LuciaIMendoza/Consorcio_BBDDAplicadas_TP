USE AltosSaintJust
GO

CREATE OR ALTER PROCEDURE csc.p_ReportePagosExpensasOrdinarias
    @ConsorcioID INT = NULL,
    @Anio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Pagos AS (
        SELECT
            c.consorcioID,
            c.nombre AS Consorcio,
            uf.unidadFuncionalID,
            CONCAT('Piso ', uf.piso, ' - Dpto ', uf.departamento) AS UnidadFuncional,
            YEAR(d.fechaPago) AS Anio,
            MONTH(d.fechaPago) AS Mes,
            d.fechaPago AS FechaPago,
            LAG(d.fechaPago) OVER (PARTITION BY uf.unidadFuncionalID ORDER BY d.fechaPago) AS PagoAnterior
        FROM csc.Detalle_CSV d
        INNER JOIN csc.Pago p ON d.pagoID = p.pagoID
        INNER JOIN csc.Unidad_Funcional uf ON p.unidadFuncionalID = uf.unidadFuncionalID
        INNER JOIN csc.Consorcio c ON uf.consorcioID = c.consorcioID
        WHERE (@ConsorcioID IS NULL OR c.consorcioID = @ConsorcioID)
          AND (@Anio IS NULL OR YEAR(d.fechaPago) = @Anio)
    )
    SELECT
        Consorcio,
        UnidadFuncional,
        Anio,
        Mes,
        FechaPago,
        PagoAnterior,
        CASE 
            WHEN PagoAnterior IS NULL THEN NULL
            ELSE DATEDIFF(DAY, PagoAnterior, FechaPago)
        END AS DiasEntrePagos
    FROM Pagos
    ORDER BY Consorcio, UnidadFuncional, FechaPago;
END;
GO

-- muestra todos
--EXEC csc.p_ReportePagosExpensasOrdinarias

-- se puede filtrar por Consorcio o por Año
--EXEC csc.p_ReportePagosExpensasOrdinarias @ConsorcioID = 1