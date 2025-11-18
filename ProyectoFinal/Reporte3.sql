USE AltosSaintJust;
GO

CREATE OR ALTER PROCEDURE csc.p_ReporteRecaudacionPorProcedencia_XML
    @FechaDesde DATE,
    @FechaHasta DATE,
    @ConsorcioID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH GastosOrdinarios AS (
        SELECT 
            go.consorcioID,
            go.fecha,
            gg.importe AS importe,
            'Gasto General' AS tipoGasto
        FROM csc.Gasto_Ordinario go
        INNER JOIN csc.Gasto_General gg ON go.gastoOrdinarioID = gg.gastoOrdinarioID
        WHERE go.fecha BETWEEN @FechaDesde AND @FechaHasta
          AND (@ConsorcioID IS NULL OR go.consorcioID = @ConsorcioID)

        UNION ALL

        SELECT 
            go.consorcioID,
            go.fecha,
            sl.importe,
            'Servicio Limpieza'
        FROM csc.Gasto_Ordinario go
        INNER JOIN csc.Servicio_Limpieza sl ON go.gastoOrdinarioID = sl.gastoOrdinarioID
        WHERE go.fecha BETWEEN @FechaDesde AND @FechaHasta
          AND (@ConsorcioID IS NULL OR go.consorcioID = @ConsorcioID)

        UNION ALL

        SELECT 
            go.consorcioID,
            go.fecha,
            sp.importe,
            'Servicio Público'
        FROM csc.Gasto_Ordinario go
        INNER JOIN csc.Servicio_Publico sp ON go.gastoOrdinarioID = sp.gastoOrdinarioID
        WHERE go.fecha BETWEEN @FechaDesde AND @FechaHasta
          AND (@ConsorcioID IS NULL OR go.consorcioID = @ConsorcioID)
    ),
    GastosExtraordinarios AS (
        SELECT 
            ge.consorcioID,
            ge.fecha,
            ge.importeTotal AS importe,
            'Gasto Extraordinario' AS tipoGasto
        FROM csc.Gasto_Extraordinario ge
        WHERE ge.fecha BETWEEN @FechaDesde AND @FechaHasta
          AND (@ConsorcioID IS NULL OR ge.consorcioID = @ConsorcioID)
    ),
    UnionGastos AS (
        SELECT * FROM GastosOrdinarios
        UNION ALL
        SELECT * FROM GastosExtraordinarios
    )
    SELECT 
        c.nombre AS [@Consorcio],
        (
            SELECT 
                tipoGasto AS [@Tipo],
                MONTH(ug2.fecha) AS [@Mes],
                SUM(importe) AS Total
            FROM UnionGastos ug2
            WHERE ug2.consorcioID = ug.consorcioID
            GROUP BY tipoGasto, MONTH(ug2.fecha)
            FOR XML PATH('Gasto'), TYPE
        )
    FROM UnionGastos ug
    INNER JOIN csc.Consorcio c ON ug.consorcioID = c.consorcioID
    GROUP BY c.nombre, ug.consorcioID
    FOR XML PATH('Consorcio'), ROOT('ReporteRecaudacionPorProcedencia');
END;
GO


--- Todas los reportes del año
--EXEC csc.p_ReporteRecaudacionPorProcedencia_XML 
    --@FechaDesde = '2025-01-01', 
    --@FechaHasta = '2025-12-31',
    --@ConsorcioID = NULL;

