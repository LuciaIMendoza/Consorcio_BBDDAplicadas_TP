USE AltosSaintJust;
GO

CREATE OR ALTER PROCEDURE csc.p_ReporteGastosSemanales
    @Anio INT = NULL,
    @ConsorcioID INT = NULL,
    @DesdeSemana INT = NULL,
    @HastaSemana INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Anio IS NULL 
        SET @Anio = YEAR(GETDATE());

    ;WITH GastosOrdinarios AS (
        SELECT 
            c.consorcioID,
            c.nombre AS Consorcio,
            DATEPART(YEAR, go.fecha) AS Anio,
            DATEPART(WEEK, go.fecha) AS Semana,
            SUM(go.importeTotal) AS TotalOrdinarios
        FROM csc.Gasto_Ordinario go
        INNER JOIN csc.Consorcio c ON go.consorcioID = c.consorcioID
        WHERE DATEPART(YEAR, go.fecha) = @Anio
        GROUP BY c.consorcioID, c.nombre, DATEPART(YEAR, go.fecha), DATEPART(WEEK, go.fecha)
    ),
    GastosExtraordinarios AS (
        SELECT 
            c.consorcioID,
            c.nombre AS Consorcio,
            DATEPART(YEAR, ge.fecha) AS Anio,
            DATEPART(WEEK, ge.fecha) AS Semana,
            SUM(ge.importeTotal) AS TotalExtraordinarios
        FROM csc.Gasto_Extraordinario ge
        INNER JOIN csc.Expensas e ON ge.documentoID = e.documentoID
        INNER JOIN csc.Consorcio c ON e.consorcioID = c.consorcioID
        WHERE DATEPART(YEAR, ge.fecha) = @Anio
        GROUP BY c.consorcioID, c.nombre, DATEPART(YEAR, ge.fecha), DATEPART(WEEK, ge.fecha)
    ),
    UnionGastos AS (
        SELECT 
            ISNULL(go.Anio, ge.Anio) AS Anio,
            ISNULL(go.Semana, ge.Semana) AS Semana,
            ISNULL(go.consorcioID, ge.consorcioID) AS consorcioID,
            ISNULL(go.Consorcio, ge.Consorcio) AS Consorcio,
            ISNULL(go.TotalOrdinarios, 0) AS TotalOrdinarios,
            ISNULL(ge.TotalExtraordinarios, 0) AS TotalExtraordinarios,
            ISNULL(go.TotalOrdinarios, 0) + ISNULL(ge.TotalExtraordinarios, 0) AS TotalGeneral
        FROM GastosOrdinarios go
        FULL OUTER JOIN GastosExtraordinarios ge
            ON go.consorcioID = ge.consorcioID
            AND go.Anio = ge.Anio
            AND go.Semana = ge.Semana
    )
    SELECT 
        (
            SELECT 
                Anio AS [@Anio],
                Semana AS [@Semana],
                Consorcio AS [@Consorcio],
                TotalOrdinarios AS [Totales/Ordinarios],
                TotalExtraordinarios AS [Totales/Extraordinarios],
                TotalGeneral AS [Totales/General],
                SUM(TotalGeneral) OVER (PARTITION BY consorcioID ORDER BY Semana ROWS UNBOUNDED PRECEDING) AS [Totales/Acumulado]
            FROM UnionGastos
            WHERE (@ConsorcioID IS NULL OR consorcioID = @ConsorcioID)
              AND (@DesdeSemana IS NULL OR Semana >= @DesdeSemana)
              AND (@HastaSemana IS NULL OR Semana <= @HastaSemana)
            ORDER BY Consorcio, Semana
            FOR XML PATH('Semana'), ROOT('FlujoCajaSemanal'), TYPE
        ) AS XMLResultado;
END;
GO

-- Todo el año actual
--EXEC csc.p_ReporteGastosSemanales;

-- Filtrando un consorcio específico
--EXEC csc.p_ReporteGastosSemanales @ConsorcioID = 2;

-- Rango de semanas
--EXEC csc.p_ReporteGastosSemanales @DesdeSemana = 35, @HastaSemana = 45;
