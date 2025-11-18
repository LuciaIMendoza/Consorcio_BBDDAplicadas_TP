USE AltosSaintJust;
GO

CREATE OR ALTER PROCEDURE csc.p_ReporteRecaudacionPorMesYDepto
    @Anio INT,
    @ConsorcioID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Recaudacion AS (
        SELECT 
            c.nombre AS Consorcio,
            uf.piso + uf.departamento AS UnidadFuncional,
            MONTH(dc.fechaPago) AS Mes,
            SUM(dc.importe) AS TotalPagado
        FROM csc.Detalle_CSV dc
        INNER JOIN csc.Pago p ON dc.pagoID = p.pagoID
        INNER JOIN csc.Unidad_Funcional uf ON p.unidadFuncionalID = uf.unidadFuncionalID
        INNER JOIN csc.Consorcio c ON uf.consorcioID = c.consorcioID
        WHERE YEAR(dc.fechaPago) = @Anio
          AND (@ConsorcioID IS NULL OR uf.consorcioID = @ConsorcioID)
        GROUP BY c.nombre, uf.piso, uf.departamento, MONTH(dc.fechaPago)
    )

    SELECT 
        Consorcio,
        UnidadFuncional,
        ISNULL([1], 0) AS Enero,
        ISNULL([2], 0) AS Febrero,
        ISNULL([3], 0) AS Marzo,
        ISNULL([4], 0) AS Abril,
        ISNULL([5], 0) AS Mayo,
        ISNULL([6], 0) AS Junio,
        ISNULL([7], 0) AS Julio,
        ISNULL([8], 0) AS Agosto,
        ISNULL([9], 0) AS Septiembre,
        ISNULL([10], 0) AS Octubre,
        ISNULL([11], 0) AS Noviembre,
        ISNULL([12], 0) AS Diciembre,
        (ISNULL([1],0)+ISNULL([2],0)+ISNULL([3],0)+ISNULL([4],0)+ISNULL([5],0)+ISNULL([6],0)+
         ISNULL([7],0)+ISNULL([8],0)+ISNULL([9],0)+ISNULL([10],0)+ISNULL([11],0)+ISNULL([12],0)) AS TotalAnual
    FROM Recaudacion
    PIVOT
    (
        SUM(TotalPagado)
        FOR Mes IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])
    ) AS PivotMensual
    ORDER BY Consorcio, UnidadFuncional;
END;
GO

--- Todos los consorcios en el 2025
--EXEC csc.p_ReporteRecaudacionPorMesYDepto @Anio = 2025;

--- Solo el consorcio Alzaga
--EXEC csc.p_ReporteRecaudacionPorMesYDepto @Anio = 2025, @ConsorcioID = 2;