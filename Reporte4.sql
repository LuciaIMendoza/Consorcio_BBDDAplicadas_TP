USE AltosSaintJust;
GO

CREATE OR ALTER PROCEDURE csc.p_ReporteTopMesesGastosIngresos
    @AnioInicio INT,
    @AnioFin INT,
    @ConsorcioID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH GastosUnidos AS (
        SELECT 
            YEAR(fecha) AS Anio,
            MONTH(fecha) AS Mes,
            SUM(importeTotal) AS TotalGasto
        FROM csc.Gasto_Ordinario
        WHERE YEAR(fecha) BETWEEN @AnioInicio AND @AnioFin
          AND (@ConsorcioID IS NULL OR consorcioID = @ConsorcioID)
        GROUP BY YEAR(fecha), MONTH(fecha)

        UNION ALL

        SELECT 
            YEAR(fecha) AS Anio,
            MONTH(fecha) AS Mes,
            SUM(importeTotal) AS TotalGasto
        FROM csc.Gasto_Extraordinario
        WHERE YEAR(fecha) BETWEEN @AnioInicio AND @AnioFin
          AND (@ConsorcioID IS NULL OR consorcioID = @ConsorcioID)
        GROUP BY YEAR(fecha), MONTH(fecha)
    ),
    GastosTotales AS (
        SELECT 
            Anio,
            Mes,
            SUM(TotalGasto) AS Monto
        FROM GastosUnidos
        GROUP BY Anio, Mes
    ),
    IngresosTotales AS (
        SELECT 
            YEAR(d.fechaPago) AS Anio,
            MONTH(d.fechaPago) AS Mes,
            SUM(d.importe) AS Monto
        FROM csc.Detalle_CSV d
        INNER JOIN csc.Pago p ON p.pagoID = d.pagoID
        INNER JOIN csc.Unidad_Funcional uf ON uf.unidadFuncionalID = p.unidadFuncionalID
        INNER JOIN csc.Consorcio c ON c.consorcioID = uf.consorcioID
        WHERE YEAR(d.fechaPago) BETWEEN @AnioInicio AND @AnioFin
          AND (@ConsorcioID IS NULL OR c.consorcioID = @ConsorcioID)
        GROUP BY YEAR(d.fechaPago), MONTH(d.fechaPago)
    )

    ------------------------------------------------------------
    -- Combinar resultados correctamente
    ------------------------------------------------------------
    SELECT *
    FROM (
        SELECT TOP 5 
            Anio, 
            Mes, 
            Monto, 
            'Gasto' AS Tipo
        FROM GastosTotales
        ORDER BY Monto DESC
    ) AS TopGastos

    UNION ALL

    SELECT *
    FROM (
        SELECT TOP 5 
            Anio, 
            Mes, 
            Monto, 
            'Ingreso' AS Tipo
        FROM IngresosTotales
        ORDER BY Monto DESC
    ) AS TopIngresos
    ORDER BY Tipo, Monto DESC;
END;
GO


---El top de gastos del Consorcio 1 entre 2024 y 2025
--EXEC csc.p_ReporteTopMesesGastosIngresos 
    --@AnioInicio = 2024, 
    --@AnioFin = 2025, 
    --@ConsorcioID = 1; --(se puede cambiar a cualquier otro consorcio o dejar Null para que muestre el top 5 entre todos)