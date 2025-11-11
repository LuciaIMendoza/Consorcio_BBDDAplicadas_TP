USE AltosSaintJust;
GO

CREATE OR ALTER PROCEDURE csc.p_CalcularExpensas
    @mes INT = NULL,     -- Mes de la expensa (si no se indica, se toma el mes anterior)
    @anio INT = NULL     -- Año de la expensa (si no se indica, se calcula según el mes)
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------------
    -- Si no se pasa mes/año, se calcula el mes anterior
    ------------------------------------------------------------
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
    SELECT 
        c.consorcioID,
        c.nombre AS consorcio,
        @mes AS mes,
        @anio AS anio,

        -- Total ordinario
        ISNULL(go_total.totalOrdinario, 0) AS totalOrdinario,

        -- Total extraordinario
        ISNULL(gex_total.totalExtraordinario, 0) AS totalExtraordinario,

        -- Total general
        ISNULL(go_total.totalOrdinario, 0) + ISNULL(gex_total.totalExtraordinario, 0) AS totalGeneral

    FROM csc.Consorcio c

    -- Subconsulta 1: totales ordinarios por consorcio
    LEFT JOIN (
        SELECT 
            consorcioID,
            SUM(importeTotal) AS totalOrdinario
        FROM csc.Gasto_Ordinario
        WHERE YEAR(fecha) = @anio AND MONTH(fecha) = @mes
        GROUP BY consorcioID
    ) go_total ON go_total.consorcioID = c.consorcioID

    -- Subconsulta 2: totales extraordinarios por consorcio (total o cuotas)
    LEFT JOIN (
        SELECT 
            gex.consorcioID,
            SUM(
                CASE 
                    WHEN gex.formaPago = 'TOTAL' THEN gex.importeTotal
                    WHEN gex.formaPago = 'CUOTAS' THEN ISNULL(cg.importeCuota, 0)
                    ELSE 0
                END
            ) AS totalExtraordinario
        FROM csc.Gasto_Extraordinario gex
		left join csc.Cuota_Gasto cg on cg.gastoExtraordinarioID = gex.gastoExtraordinarioID
		and DATEFROMPARTS(@anio, @mes, 1) <= DATEADD(MONTH, cg.nroCuota - 1, gex.fecha) 

        WHERE YEAR(gex.fecha) = @anio AND MONTH(gex.fecha) = @mes
        GROUP BY gex.consorcioID
    ) gex_total ON gex_total.consorcioID = c.consorcioID

    ORDER BY c.consorcioID;

    ------------------------------------------------------------
    -- Asociar GASTOS ORDINARIOS sin documentoID a su expensa correspondiente
    ------------------------------------------------------------
    UPDATE g
    SET g.documentoID = e.documentoID
    FROM csc.Gasto_Ordinario g
    INNER JOIN csc.Expensas e
        ON e.consorcioID = g.consorcioID
       AND MONTH(g.fecha) = e.mes
       AND YEAR(g.fecha) = e.anio
    WHERE g.documentoID IS NULL;

    ------------------------------------------------------------
    -- Asociar GASTOS EXTRAORDINARIOS sin documentoID a su expensa correspondiente
    ------------------------------------------------------------
    UPDATE ge
    SET ge.documentoID = e.documentoID
    FROM csc.Gasto_Extraordinario ge
    INNER JOIN csc.Expensas e
        ON e.consorcioID = ge.consorcioID
       AND MONTH(ge.fecha) = e.mes
       AND YEAR(ge.fecha) = e.anio
    WHERE ge.documentoID IS NULL;


    ------------------------------------------------------------
    -- Cargar estados de cuentas
 --   ------------------------------------------------------------

 --trae los saldos anteriores de las UF por cada 
 SELECT 
	ec.unidadFuncionalID,
	ec.totalPagar as saldoAnterior, 
	ec.deuda
 INTO #SaldoAnterior
 FROM csc.Estado_Cuentas ec 
 join csc.Expensas e on e.documentoID = ec.documentoID
 where e.anio =  csc.fn_AnioAnterior(@mes, @anio) and e.mes = csc.fn_MesAnterior(@mes)

--inserta todo
INSERT INTO csc.Estado_Cuentas(documentoID, unidadFuncionalID,saldoAnterior,pagosRecibidos, 
deuda, InteresesPorMora, expensasOrdinarias,expensasExtraordinarias, totalPagar)
 SELECT 
    e.documentoID,
    uf.unidadFuncionalID,
    ISNULL(sa.saldoAnterior, 0) AS saldoAnterior, 
    ISNULL(pagos_mes.totalPagos, 0) AS pagosRecibidos,
		(ISNULL(sa.saldoAnterior, 0) - ISNULL(pagos_mes.totalPagos, 0)) AS deuda,  
	ISNULL(sa.saldoAnterior, 0) * 0.02 
        + ISNULL(sa.deuda, 0) * 0.05 as InteresesPorMora, -- Si es saldo anterior (1er vto) por 0.02, si es deuda (mas de 2do vto) por 0.05
    exp_mes.expOrdinarias AS expensasOrdinarias,
	exp_mes.expExtraordinarias AS expensasExtraordinarias,
   (
        ISNULL(
            (ISNULL(sa.saldoAnterior, 0) - ISNULL(pagos_mes.totalPagos, 0)), 0
        ) -- deuda 
        + ISNULL(sa.saldoAnterior, 0) * 0.02 + ISNULL(sa.deuda, 0) * 0.05 --INTERESES POR MORA
        + ISNULL(exp_mes.expOrdinarias, 0) --ORDINARIAS 
        + ISNULL(exp_mes.expExtraordinarias, 0) --EXTRAORDINARIAS
    ) AS totalPagar

FROM csc.Expensas e
JOIN csc.Unidad_Funcional uf ON uf.consorcioID = e.consorcioID
left join #SaldoAnterior sa on sa.unidadFuncionalID = uf.unidadFuncionalID
OUTER APPLY (
    SELECT 
        SUM(p.monto) AS totalPagos,
        MAX(d.fechaPago) AS fechaUltimoPago
    FROM csc.Pago p
	join csc.Detalle_CSV d on d.pagoID = p.pagoID
    WHERE p.cuentaOrigen = uf.CBU_CVU
      AND YEAR(d.fechaPago) = csc.fn_AnioAnterior(@mes, @anio)
      AND MONTH(d.fechaPago) = csc.fn_MesAnterior(@mes)
) pagos_mes
OUTER APPLY (
    SELECT 
        -- Expensas ordinarias
        ISNULL(SUM(g.importeTotal), 0) * (uf.coeficiente / 100.0) AS expOrdinarias,

        -- Expensas extraordinarias
        ISNULL((
            SELECT SUM(
                CASE 
                    WHEN ge.formaPago = 'TOTAL' THEN ge.importeTotal
                    WHEN ge.formaPago = 'CUOTAS' THEN ISNULL(cg.importeCuota, 0)
                    ELSE 0
                END
            )
            FROM csc.Gasto_Extraordinario ge
            OUTER APPLY (
                SELECT cg.importeCuota
                FROM csc.Cuota_Gasto cg
                WHERE cg.gastoExtraordinarioID = ge.gastoExtraordinarioID
                  AND DATEADD(MONTH, cg.nroCuota - 1, EOMONTH(ge.fecha, -1))
                        BETWEEN DATEFROMPARTS(@anio, @mes, 1)
                        AND EOMONTH(DATEFROMPARTS(@anio, @mes, 1))
            ) cg
            WHERE YEAR(ge.fecha) <= @anio AND MONTH(ge.fecha) <= @mes
        ), 0) * (uf.coeficiente / 100.0) AS expExtraordinarias
    FROM csc.Gasto_Ordinario g
    WHERE YEAR(g.fecha) = @anio AND MONTH(g.fecha) = @mes
) exp_mes
where e.anio = @anio and e.mes = @mes
and not exists (select 1 from csc.Estado_Cuentas where e.documentoID = documentoID)


drop table #SaldoAnterior

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

------------------------------------------------------------
-- 🔹 Prueba 1: Generar expensas de OCTUBRE 2025
------------------------------------------------------------
--EXEC csc.p_CalcularExpensas @mes = 10, @anio = 2025;

------------------------------------------------------------
-- 🔹 Verificar resultado de octubre
------------------------------------------------------------
SELECT * FROM csc.Expensas;
SELECT * FROM csc.Gasto_Ordinario;
SELECT * FROM csc.Gasto_Extraordinario;
select *  FROM csc.cuota_gasto;
select * from csc.Estado_Cuentas
GO

SELECT
			Uf.unidadFuncionalID AS [uf],
			uf.coeficiente AS [Porcentaje],
			concat(uf.piso, '-' ,uf.departamento) AS [PisoDepto],
			concat(p.apellido, ' ',p.nombre) AS [Propietario],
			ec.saldoAnterior  AS [SaldoAnterior],
			ec.pagosRecibidos  AS [PagosRecibidos],
			ec.deuda AS [Deuda],
			ec.InteresesPorMora AS [InteresMora],
			ec.expensasOrdinarias  AS [ExpensasOrdinarias],
			uf.cochera  AS [Cocheras],
			ec.expensasExtraordinarias AS [ExpensasExtraordinarias],
			ec.totalPagar AS [TotalPagar]
		FROM csc.Expensas e
		JOIN csc.Estado_Cuentas ec on e.documentoID = ec.documentoID
		join csc.Unidad_Funcional uf on uf.unidadFuncionalID = ec.unidadFuncionalID
		join csc.Propietario p on p.unidadFuncionalID = uf.unidadFuncionalID
		where e.anio = 2025 and e.mes = 11
		FOR XML PATH('Expensa'), ROOT('Expensas');
--------------------------------------------------
----- LOTE DE PRUEBA
--------------------------------------------------
--INSERT INTO csc.Gasto_Ordinario (consorcioID, fecha, importeTotal)
--VALUES
--(1, '2025-09-15', 80000.00),   -- Azcuenaga, septiembre
--(1, '2025-10-05', 90000.00),   -- Azcuenaga, octubre
--(2, '2025-10-10', 50000.00),   -- Alzaga, octubre
--(3, '2025-08-20', 70000.00);   -- Alberdi, agosto
--GO

--INSERT INTO csc.Gasto_Extraordinario (consorcioID, razonSocial, fecha, importeTotal, formaPago)
--VALUES
--(2, 'Cambio ascensor', '2025-10-25', 50000.00, 'CUOTAS'), -- Alzaga, octubre
--(1, 'Pintura fachada', '2025-10-08', 100000.00, 'TOTAL'),  -- Azcuenaga, octubre
--(2, 'Cambio ascensor', '2025-10-09', 150000.00, 'CUOTAS'), -- Alzaga, octubre
--(2, 'Reparación caldera', '2025-09-15', 120000.00, 'TOTAL'), -- Alzaga, septiembre
--(3, 'Impermeabilización techo', '2025-08-10', 200000.00, 'CUOTAS'); -- Alberdi, agosto
--GO

--INSERT INTO csc.Cuota_Gasto (gastoExtraordinarioID, nroCuota, totalCuota, importeCuota)
--VALUES
--(2, 3, 150000.00, 50000.00);

--INSERT INTO csc.Cuota_Gasto (gastoExtraordinarioID, nroCuota, totalCuota, importeCuota)
--VALUES
--(4, 4, 200000.00, 50000.00);

--INSERT INTO csc.Cuota_Gasto (gastoExtraordinarioID, nroCuota, totalCuota, importeCuota)
--VALUES
--(5, 5, 50000.00, 10000.00);
--GO
