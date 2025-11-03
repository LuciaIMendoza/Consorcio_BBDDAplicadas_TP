USE AltosSaintJust;
GO

CREATE OR ALTER PROCEDURE  [csc].[p_ImportarGastos]
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
		DECLARE @SQL NVARCHAR(MAX);
		DECLARE @JSON NVARCHAR(MAX);

		SET @SQL = '
		SELECT @JSONOut = BulkColumn
		FROM OPENROWSET(BULK ''' + @RutaArchivo + ''', SINGLE_CLOB) AS j;
		';

		IF OBJECT_ID('tempdb..#TempGastosImport') IS NOT NULL DROP TABLE #TempGastosImport;

		CREATE TABLE #TempGastosImport (
			Consorcio          NVARCHAR(200),
			Mes                NVARCHAR(50),
			Bancarios          DECIMAL(18,2),
			Limpieza           DECIMAL(18,2),
			Administracion     DECIMAL(18,2),
			Seguros            DECIMAL(18,2),
			GastosGenerales    DECIMAL(18,2),
			Agua               DECIMAL(18,2),
			Luz                DECIMAL(18,2)
		);


		EXEC sp_executesql @SQL,
			N'@JSONOut NVARCHAR(MAX) OUTPUT',
			@JSONOut = @JSON OUTPUT;


		-- Insert from JSON
		INSERT INTO #TempGastosImport
		SELECT
			JSON_VALUE(j.value,'$."Nombre del consorcio"'),
			JSON_VALUE(j.value,'$.Mes'),
			TRY_CONVERT(DECIMAL(18,2), REPLACE(REPLACE(JSON_VALUE(j.value,'$.BANCARIOS'),'.',''),',','.')),
			TRY_CONVERT(DECIMAL(18,2), REPLACE(REPLACE(JSON_VALUE(j.value,'$.LIMPIEZA'),'.',''),',','.')),
			TRY_CONVERT(DECIMAL(18,2), REPLACE(REPLACE(JSON_VALUE(j.value,'$.ADMINISTRACION'),'.',''),',','.')),
			TRY_CONVERT(DECIMAL(18,2), REPLACE(REPLACE(JSON_VALUE(j.value,'$.SEGUROS'),'.',''),',','.')),
			TRY_CONVERT(DECIMAL(18,2), REPLACE(REPLACE(JSON_VALUE(j.value,'$."GASTOS GENERALES"'),'.',''),',','.')),
			TRY_CONVERT(DECIMAL(18,2), REPLACE(REPLACE(JSON_VALUE(j.value,'$."SERVICIOS PUBLICOS-Agua"'),'.',''),',','.')),
			TRY_CONVERT(DECIMAL(18,2), REPLACE(REPLACE(JSON_VALUE(j.value,'$."SERVICIOS PUBLICOS-Luz"'),'.',''),',','.'))
		FROM OPENJSON(@JSON) j;

		-- Check result
		SELECT * FROM #TempGastosImport;

				--------------------------------------------------------------
				-- Insertar Gasto Ordinario (solo si no existen)
				--------------------------------------------------------------
		INSERT INTO csc.Gasto_Ordinario (consorcioID, Mes, importeTotal)
		SELECT 
			c.consorcioID,
			 CASE LOWER(Mes)
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
				ELSE NULL
			END AS Mes,
			ISNULL(t.Bancarios, 0) + ISNULL(t.Limpieza, 0) + ISNULL(t.Administracion, 0) +
			ISNULL(t.Seguros, 0) + ISNULL(t.GastosGenerales, 0) + ISNULL(t.Agua, 0) +
			ISNULL(t.Luz, 0)
		FROM #TempGastosImport t
		join csc.consorcio c on c.nombre = t.Consorcio
		 AND NOT EXISTS (SELECT 1 FROM csc.Gasto_Ordinario g WHERE g.consorcioID = c.consorcioID and g.mes = mes);
		

				--------------------------------------------------------------
				-- Insertar Servicio Publico (solo si no existen)
				--------------------------------------------------------------

		INSERT INTO csc.Servicio_Publico (gastoOrdinarioID, tipo, importe)
		SELECT 
			g.gastoOrdinarioID,
			v.concepto,
			v.Monto
		FROM #TempGastosImport t
		join csc.consorcio c on c.nombre = t.consorcio
		join csc.gasto_ordinario g on g.consorcioID = c.consorcioID and 
				g.mes = CASE LOWER(t.Mes)
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
				ELSE NULL
			END 
		CROSS APPLY (VALUES
			('SERVICIOS PUBLICOS-Agua', t.Agua),
			('SERVICIOS PUBLICOS-Luz', t.Luz)
		) v (Concepto, Monto)
		WHERE v.Monto IS NOT NULL 
		AND NOT EXISTS (select 1 FROM csc.Servicio_Publico sp
				WHERE sp.gastoOrdinarioID = g.gastoOrdinarioID and sp.tipo = v.Concepto)

		--------------------------------------------------------------
				-- Insertar Servicio_Limpieza (solo si no existen)
				--------------------------------------------------------------

		INSERT INTO csc.Servicio_Limpieza (gastoOrdinarioID, importe)
		SELECT 
			g.gastoOrdinarioID,
			t.Limpieza
		FROM #TempGastosImport t
		join csc.consorcio c on c.nombre = t.consorcio
		join csc.gasto_ordinario g on g.consorcioID = c.consorcioID and 
				g.mes = CASE LOWER(t.Mes)
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
				ELSE NULL
			END 

		WHERE t.Limpieza IS NOT NULL
		AND NOT EXISTS (select 1 FROM csc.Servicio_Limpieza sp
				WHERE sp.gastoOrdinarioID = g.gastoOrdinarioID)



		--------------------------------------------------------------
				-- Insertar Gasto_General (solo si no existen)
				--------------------------------------------------------------

		INSERT INTO csc.Gasto_General (gastoOrdinarioID, tipo, empresaoPersona, importe)
		SELECT 
			g.gastoOrdinarioID,
			v.Concepto,
			1,
			v.monto
		FROM #TempGastosImport t
		join csc.consorcio c on c.nombre = t.consorcio
		join csc.gasto_ordinario g on g.consorcioID = c.consorcioID and 
				g.mes = CASE LOWER(t.Mes)
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
				ELSE NULL
			END 
		CROSS APPLY (VALUES
			('BANCARIOS', t.Bancarios),
			('ADMINISTRACION', t.Administracion),
			('SEGUROS', t.Seguros),
			('GASTOS GENERALES', t.GastosGenerales)

		) v (Concepto, Monto)
		WHERE v.Monto IS NOT NULL 
		AND NOT EXISTS (select 1 FROM csc.Gasto_General gg
				WHERE gg.gastoOrdinarioID = g.gastoOrdinarioID AND gg.tipo = v.concepto)

				drop table #TempGastosImport;
END TRY

    BEGIN CATCH
        DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
        PRINT 'Error durante la importación: ' + @Msg;

        IF OBJECT_ID('tempdb..#TempPersonas') IS NOT NULL
            DROP TABLE #TempPersonas;

        RAISERROR(@Msg, 16, 1);
    END CATCH
END;
GO