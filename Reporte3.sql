USE AltosSaintJust;
GO

CREATE OR ALTER PROCEDURE csc.p_ReporteRecaudacionPorProcedencia_XML
    @FechaDesde DATE,
    @FechaHasta DATE,
    @ConsorcioID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

	DECLARE @XML XML;
	DECLARE @sql VARCHAR(8000);
	DECLARE @sCommand VARCHAR(8000);
	DECLARE @ruta VARCHAR(200) = 'C:\Reportes\';
	DECLARE @filename VARCHAR(200);



		CREATE TABLE ##ReporteXML
	(
		ReporteID INT IDENTITY(1,1) PRIMARY KEY,
		NombreReporte VARCHAR(100),
		ContenidoXML XML
	);

	--INSERT INTO #ReporteXML (NombreReporte, ContenidoXML)
	--SELECT ('ReporteRecaudacionPorProcedencia_' + CAST(@ConsorcioID AS VARCHAR(2))+ '_' +CONVERT(VARCHAR(10), @FechaDesde, 120) + '_' + CONVERT(VARCHAR(10), @FechaHasta, 120) ) ,
	--(
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
    SELECT  @XML = (
      SELECT  c.nombre AS [@nombre],
        (
            SELECT 
                tipoGasto AS [@Tipo],
                SUM(importe) AS Total
            FROM UnionGastos ug2
            WHERE ug2.consorcioID = ug.consorcioID
            GROUP BY tipoGasto
            FOR XML PATH('Gasto'), TYPE
        )
    FROM UnionGastos ug
    INNER JOIN csc.Consorcio c ON ug.consorcioID = c.consorcioID
    GROUP BY c.nombre, ug.consorcioID
    FOR XML PATH('Consorcio'), ROOT('ReporteRecaudacionPorProcedencia')
	);

	INSERT INTO ##ReporteXML (NombreReporte, ContenidoXML)
    VALUES (
        'ReporteRecaudacionPorProcedencia_' + ISNULL(CAST(@ConsorcioID AS VARCHAR(10)), 'NULL') 
        + '_' + CONVERT(VARCHAR(10), @FechaDesde, 120) 
        + '_' + CONVERT(VARCHAR(10), @FechaHasta, 120),
        @XML
    );

    -- Seleccionar resultados

	SET  @sql = 'select ContenidoXML from ##ReporteXML';
	SELECT @filename = NombreReporte FROM ##ReporteXML

   select @sCommand = 'bcp "'
		+rtrim(@sql) + '" queryout "'
		+ltrim(rtrim(@ruta)) 
		+ltrim(rtrim(@filename)) + '.xml'
		+ '" -c -T -S localhost\SQLEXPRESS -d AltosSaintJust'


EXEC master..xp_cmdshell @sCommand;

DROP TABLE ##ReporteXML

END;
GO

--- Todas los reportes del año
--EXEC csc.p_ReporteRecaudacionPorProcedencia_XML 
    --@FechaDesde = '2025-01-01', 
    --@FechaHasta = '2025-12-31',
    --@ConsorcioID = NULL;

