USE AltosSaintJust;
GO

CREATE OR ALTER PROCEDURE csc.p_CalcularExpensas
    @mes INT = NULL,     
    @anio INT = NULL     
AS
BEGIN
    SET NOCOUNT ON;
--DECLARE @mes INT = 5
--DECLARE    @anio INT = 2025 

    IF @mes IS NULL OR @anio IS NULL
    BEGIN
        DECLARE @hoy DATE = GETDATE();
        SET @mes = MONTH(DATEADD(MONTH, -1, @hoy));
        SET @anio = YEAR(DATEADD(MONTH, -1, @hoy));
    END;

    DECLARE @fechaProceso DATE = GETDATE();

    ------------------------------------------------------------
    -- Insertar expensas del mes indicado si no existen
    ------------------------------------------------------------
    INSERT INTO csc.Expensas (consorcioID, mes, anio, fechaGenerado, fechaEnvio, medioEnvio, aPropietario, aInquilino)
    SELECT 
        c.consorcioID,
        @mes,
        @anio,
        @fechaProceso,
        @fechaProceso,
        'Mail',
        1, 0
    FROM csc.Consorcio c
    WHERE NOT EXISTS (
        SELECT 1 
        FROM csc.Expensas e 
        WHERE e.consorcioID = c.consorcioID 
          AND e.mes = @mes 
          AND e.anio = @anio
    );

    ------------------------------------------------------------
    -- Calcular totales ordinarios y extraordinarios
    ------------------------------------------------------------
    CREATE TABLE #TotalesGastos (
        consorcioID INT,
        consorcio NVARCHAR(200),
        mes INT,
        anio INT,
        expOrdinarias DECIMAL(18,2),
        expExtraordinarias DECIMAL(18,2),
        totalGeneral DECIMAL(18,2)
    );

    INSERT INTO #TotalesGastos (
        consorcioID, consorcio, mes, anio,
        expOrdinarias, expExtraordinarias, totalGeneral
    )
    SELECT 
        c.consorcioID,
        c.nombre AS consorcio,
        @mes AS mes,
        @anio AS anio,
        ISNULL(go_total.totalOrdinario, 0),
        ISNULL(gex_total.totalExtraordinario, 0),
        ISNULL(go_total.totalOrdinario, 0) + ISNULL(gex_total.totalExtraordinario, 0)
    FROM csc.Consorcio c
    LEFT JOIN (
        SELECT consorcioID, SUM(importeTotal) AS totalOrdinario
        FROM csc.Gasto_Ordinario
        WHERE YEAR(fecha) = @anio AND MONTH(fecha) = @mes
        GROUP BY consorcioID
    ) go_total ON go_total.consorcioID = c.consorcioID
    LEFT JOIN (
        SELECT gex.consorcioID,
            SUM(
                CASE 
                    WHEN gex.formaPago = 'TOTAL' THEN gex.importeTotal
                    WHEN gex.formaPago = 'CUOTAS' THEN ISNULL(gex.importeTotal/ gex.nroCuota, 0)
                    ELSE 0
                END
            ) AS totalExtraordinario
        FROM csc.Gasto_Extraordinario gex
        WHERE (YEAR(gex.fecha) = @anio AND MONTH(gex.fecha) = @mes)
           OR (DATEFROMPARTS(@anio, @mes, 1) >= gex.fecha 
               AND DATEADD(MONTH, gex.nroCuota -1 ,gex.fecha) >= EOMONTH(DATEFROMPARTS(@anio, @mes, 1)))
        GROUP BY gex.consorcioID
    ) gex_total ON gex_total.consorcioID = c.consorcioID
    ORDER BY c.consorcioID;

    ------------------------------------------------------------
    -- Asociar gastos ordinarios y extraordinarios
    ------------------------------------------------------------
    UPDATE g
    SET g.documentoID = e.documentoID
    FROM csc.Gasto_Ordinario g
    INNER JOIN csc.Expensas e
        ON e.consorcioID = g.consorcioID
       AND MONTH(g.fecha) = e.mes
       AND YEAR(g.fecha) = e.anio
    WHERE g.documentoID IS NULL;

    UPDATE ge
    SET ge.documentoID = e.documentoID
    FROM csc.Gasto_Extraordinario ge
    INNER JOIN csc.Expensas e
        ON e.consorcioID = ge.consorcioID
       AND MONTH(ge.fecha) = e.mes
       AND YEAR(ge.fecha) = e.anio
    WHERE ge.documentoID IS NULL;

    ------------------------------------------------------------
    -- Cargar estados de cuentas con lógica de mora
    ------------------------------------------------------------
    SELECT 
        ec.unidadFuncionalID,
        ec.totalPagar as saldoAnterior, 
        ec.saldo
    INTO #SaldoAnterior
    FROM csc.Estado_Cuentas ec 
    JOIN csc.Expensas e ON e.documentoID = ec.documentoID
    WHERE e.anio =  csc.fn_AnioAnterior(@mes, @anio) 
      AND e.mes = csc.fn_MesAnterior(@mes);

--INSERT INTO csc.Estado_Cuentas(
--    documentoID, unidadFuncionalID, saldoAnterior, pagosRecibidos, 
--    saldo, InteresesPorMora, expensasOrdinarias, expensasExtraordinarias, totalPagar
--)
SELECT 
    e.documentoID,
    uf.unidadFuncionalID,
    ISNULL(sa.saldoAnterior, 0) AS saldoAnterior,
    ISNULL(pagos_mes.totalPagos, 0) AS pagosRecibidos,
    (ISNULL(sa.saldoAnterior, 0) - ISNULL(pagos_mes.totalPagos, 0)) AS saldo,

       -- Intereses por mora
    (
	CASE WHEN (
	CASE WHEN saldoAnterior > 0
	THEN (
	(saldoAnterior - ISNULL(pagosMora.pagosHasta10, 0)) * 0.02
	+
	(saldoAnterior - ISNULL(pagosMora.pagosHasta15, 0)) * 0.05
	)
	ELSE 0 END) > 0 THEN 
	(CASE WHEN saldoAnterior > 0
	THEN (
	(saldoAnterior - ISNULL(pagosMora.pagosHasta10, 0)) * 0.02
	+
	(saldoAnterior - ISNULL(pagosMora.pagosHasta15, 0)) * 0.05
	)
	ELSE 0 END)
	ELSE 0 END
    ) 
	
	AS InteresesPorMora,

    -- Expensas proporcionales por UF
    (exp_mes.expOrdinarias * (uf.coeficiente / 100)) AS expensasOrdinarias,
    (exp_mes.expExtraordinarias * (uf.coeficiente / 100)) AS expensasExtraordinarias,

    -- Total por UF usando las mismas columnas ya calculadas
		( CASE WHEN (
		CASE WHEN saldoAnterior > 0
		THEN (
		(saldoAnterior - ISNULL(pagosMora.pagosHasta10, 0)) * 0.02
		+
		(saldoAnterior - ISNULL(pagosMora.pagosHasta15, 0)) * 0.05
		)
		ELSE 0 END
		) > 0 
	THEN 
	(
		CASE WHEN saldoAnterior > 0
		THEN (
		(saldoAnterior - ISNULL(pagosMora.pagosHasta10, 0)) * 0.02
		+
		(saldoAnterior - ISNULL(pagosMora.pagosHasta15, 0)) * 0.05
		)
		ELSE 0 END
    ) ELSE 0 END
        + (exp_mes.expOrdinarias * (uf.coeficiente / 100))
        + (exp_mes.expExtraordinarias * (uf.coeficiente / 100))
    )
 AS totalPagar

FROM csc.Expensas e
JOIN csc.Unidad_Funcional uf ON uf.consorcioID = e.consorcioID
LEFT JOIN #SaldoAnterior sa ON sa.unidadFuncionalID = uf.unidadFuncionalID
OUTER APPLY (
    SELECT 
        SUM(p.monto) AS totalPagos,
        MAX(d.fechaPago) AS fechaUltimoPago
    FROM csc.Pago p
    JOIN csc.Detalle_CSV d ON d.pagoID = p.pagoID
    WHERE p.cuentaOrigen = uf.CBU_CVU
      AND YEAR(d.fechaPago) = csc.fn_AnioAnterior(@mes, @anio)
      AND MONTH(d.fechaPago) = csc.fn_MesAnterior(@mes)
) pagos_mes
OUTER APPLY (
    SELECT
        SUM(CASE 
                WHEN dq.fechaPago BETWEEN DATEFROMPARTS(csc.fn_AnioAnterior(@mes,@anio), csc.fn_MesAnterior(@mes), 1)
                                     AND DATEFROMPARTS(csc.fn_AnioAnterior(@mes,@anio), csc.fn_MesAnterior(@mes), 10)
                THEN pq.monto 
            END
        ) AS pagosHasta10,

        SUM(CASE 
                WHEN dq.fechaPago BETWEEN DATEFROMPARTS(csc.fn_AnioAnterior(@mes,@anio), csc.fn_MesAnterior(@mes), 1)
                                     AND DATEFROMPARTS(csc.fn_AnioAnterior(@mes,@anio), csc.fn_MesAnterior(@mes), 15)
                THEN pq.monto 
            END
        ) AS pagosHasta15
    FROM csc.pago pq
    JOIN csc.Detalle_CSV dq ON dq.pagoID = pq.pagoID
    WHERE pq.unidadFuncionalID = uf.unidadFuncionalID
) pagosMora
LEFT JOIN #TotalesGastos exp_mes ON exp_mes.consorcioID = e.consorcioID
WHERE e.anio = @anio AND e.mes = @mes
  AND NOT EXISTS (SELECT 1 FROM csc.Estado_Cuentas WHERE e.documentoID = documentoID);


    DROP TABLE #SaldoAnterior;
    DROP TABLE #TotalesGastos;
	--CREACION DEL XML
DECLARE @sql VARCHAR(8000);
DECLARE @sCommand VARCHAR(8000);
DECLARE @ruta VARCHAR(200) = 'C:\Reportes\';
DECLARE @filename VARCHAR(200);

set @filename = 'ArchivoExpensas_' + CAST(@anio AS VARCHAR(4)) + CAST(@mes AS VARCHAR(2))

SET @sql = 'SELECT Uf.unidadFuncionalID AS [uf],' +
			' uf.coeficiente AS [Porcentaje],' +
			' CONCAT(uf.piso, ''-'', uf.departamento) AS [PisoDepto],' +
			' CONCAT(p.apellido, '' '', p.nombre) AS [Propietario],' +
			' ec.saldoAnterior AS [SaldoAnterior],' +
			' ec.pagosRecibidos AS [PagosRecibidos],' +
			' ec.deuda AS [Deuda],' +
			' ec.InteresesPorMora AS [InteresMora],' +
			' ec.expensasOrdinarias AS [ExpensasOrdinarias],' +
			' uf.cochera AS [Cocheras],' +
			' ec.expensasExtraordinarias AS [ExpensasExtraordinarias],' +
			' ec.totalPagar AS [TotalPagar]' +
		' FROM csc.Expensas e' +
		' JOIN csc.Estado_Cuentas ec ON e.documentoID = ec.documentoID' +
		' JOIN csc.Unidad_Funcional uf ON uf.unidadFuncionalID = ec.unidadFuncionalID' +
		' JOIN csc.Propietario p ON p.unidadFuncionalID = uf.unidadFuncionalID' +
		' WHERE e.anio = ' + CAST(@anio AS VARCHAR(4)) + 
		' AND e.mes = ' + CAST(@mes AS VARCHAR(2)) + 
		'  FOR XML PATH(''Expensa''), ROOT(''Expensas'')';

select @sCommand = 'bcp "'
		+rtrim(@sql) + '" queryout "'
		+ltrim(rtrim(@ruta)) 
		+ltrim(rtrim(@filename)) + '.xml'
		+ '" -c -T -S localhost\SQLEXPRESS -d AltosSaintJust'

EXEC master..xp_cmdshell @sCommand;


END;

GO





