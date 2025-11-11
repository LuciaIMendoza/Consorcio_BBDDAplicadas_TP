USE AltosSaintJust
go
CREATE or ALTER PROCEDURE p_CalcularExpensas @fechaProceso DATE
AS
BEGIN
    SET NOCOUNT ON;

		--declare @fechaProceso date;



		set @fechaProceso = '2025-09-06'

		DECLARE @fechaInicio DATE = DATEADD(MONTH, DATEDIFF(MONTH, 0, @fechaProceso) - 1, 0);
		DECLARE @fechaFin DATE = EOMONTH(@fechaInicio)

		--alter table csc.gasto_Extraordinario
		--add fecha DATE 
		--alter table csc.gasto_Extraordinario
		--add  detalle char(300)
		--alter table csc.gasto_Extraordinario
		--add  consorcioID int
		--alter table csc.gasto_Extraordinario
		--drop  column detalle 

		alter table csc.cuota_gasto
		alter column nroCuota int

		--insert into csc.gasto_extraordinario(tipoGasto, importetotal, formapago, fecha)
		--values('construccion', 600000, 'CUOTAS', '2025-08-06')
		--,('construccion', 150000, 'TOTAL', '2025-08-06')
		--,('Arreglo ascensor', 14652.52, 'TOTAL', '2025-08-10')
		--,('Reparacion loby', 14444.4, 'TOTAL', '2025-08-01')
		--,('EXTRAORDINARIOS', 100000, 'CUOTAS', '2025-09-20')
		--,('reparacion areas comunes', 968500, 'TOTAL', '2025-09-14')


		--values('construccion', 600000, 'CUOTAS', '2025-08-06')
		--,('construccion', 150000, 'TOTAL', '2025-08-06')
		--,('Arreglo ascensor', 14652.52, 'TOTAL', '2025-08-10')
		--,('Reparacion loby', 14444.4, 'TOTAL', '2025-08-01')
		--,('EXTRAORDINARIOS', 100000, 'CUOTAS', '2025-09-20')
		--,('reparacion areas comunes', 968500, 'TOTAL', '2025-09-14')

		--select * from csc.gasto_extraordinario
		--insert into csc.cuota_gasto (gastoextraordinarioid, nrocuota, totalcuota, importecuota)
		--values(1, 12, 600000, 50000), (5, 6, 100000, 33333.33)
		--select * from csc.cuota_gasto

		--UPDATE CSC.gasto_extraordinario set consorcioid = 1

		
		CREATE TABLE #TempExpensasExtra (
			ConsorcioID         int,
			importeTotal          DECIMAL(18,2)
		);
		insert into #TempExpensasExtra (ConsorcioID, importetotal)
		select
			c.consorcioID,
			SUM ( CASE WHEN ge.tipoGasto = 'CUOTAS' THEN cg.importecuota ELSE ge.importetotal END ) 
			
		FROM csc.consorcio c
		JOIN csc.gasto_extraordinario ge on ge.consorcioID = c.consorcioID
		LEFT join csc.cuota_gasto cg on cg.gastoExtraordinarioID = ge.gastoExtraordinarioID
		where  ge.fecha between @fechaInicio and @fechaFin -- si la factura es del mes corriente
		OR DATEADD(MONTH, CAST(cg.nroCuota AS INT), ge.fecha) between @fechaInicio and @fechaFin --si es en cuota que haya cuotas vigentes a la fecha
		GROUP BY c.consorcioID



		INSERT INTO csc.Expensas(consorcioID, mes, anio, fechaGenerado, fechaEnvio, medioEnvio, aPropietario, aInquilino)
		SELECT
			c.consorcioID,
			 MONTH(@fechaInicio), 
			YEAR(@fechaInicio),
			@fechaProceso,
			@fechaProceso,
			'Mail',
			1, 0
		FROM csc.consorcio c
		join csc.gasto_ordinario g on g.consorcioID = c.consorcioID
		join csc.#TempExpensasExtra ee on ee.consorcioID = c.consorcioID
		WHERE g.fecha between @fechaInicio and @fechaFin
		and not exists (select 1 from csc.Expensas where mes =  MONTH(@fechaInicio) and anio = YEAR(@fechaInicio))

		--select * from csc.Expensas

		--	SELECT
		--		Uf.unidadFuncionalID AS [uf],
		--		uf.coeficiente AS [Porcentaje],
		--		concat(uf.piso, '-' ,uf.departamento) AS [PisoDepto],
		--		--concat(p.apellido, ' ',p.nombre) AS [Propietario],
		--		--g.importeTotal  AS [SaldoAnterior],
		--		--g.importeTotal  AS [PagosRecibidos],
		--		0 AS [Deuda],
		--		0 AS [InteresMora],
		--		CAST(g.importeTotal * (uf.coeficiente / 100) AS DECIMAL(14,2))  AS [ExpensasOrdinarias],
		--		CASE WHEN (uf.cochera =1 ) THEN CAST(50000 AS DECIMAL(14,2)) ELSE CAST(0 AS decimal(14,2)) END AS [Cocheras],
		--		CAST(ee.importeTotal * (uf.coeficiente / 100) AS DECIMAL(14,2)) AS [ExpensasExtraordinarias],
		--		g.importeTotal  AS [TotalPagar]
		--	from csc.unidad_funcional uf
		--join csc.consorcio c on c.consorcioID = uf.consorcioID
		--join csc.gasto_ordinario g on g.consorcioID = uf.consorcioID
		--join csc.propietario p on p.unidadFuncionalID = uf.unidadFuncionalID
		--join csc.#TempExpensasExtra ee on ee.consorcioID = c.consorcioID
		--WHERE g.fecha between @fechaInicio and @fechaFin
		

		--	SELECT
		--		Uf.unidadFuncionalID AS [uf],
		--		uf.coeficiente AS [Porcentaje],
		--		concat(uf.piso, '-' ,uf.departamento) AS [PisoDepto],
		--		--concat(p.apellido, ' ',p.nombre) AS [Propietario],
		--		--g.importeTotal  AS [SaldoAnterior],
		--		--g.importeTotal  AS [PagosRecibidos],
		--		0 AS [Deuda],
		--		0 AS [InteresMora],
		--		CAST(g.importeTotal * (uf.coeficiente / 100) AS DECIMAL(14,2))  AS [ExpensasOrdinarias],
		--		CASE WHEN (uf.cochera =1 ) THEN CAST(50000 AS DECIMAL(14,2)) ELSE CAST(0 AS decimal(14,2)) END AS [Cocheras],
		--		CAST(ee.importeTotal * (uf.coeficiente / 100) AS DECIMAL(14,2)) AS [ExpensasExtraordinarias],
		--		g.importeTotal  AS [TotalPagar]
		--	from csc.unidad_funcional uf
		--join csc.consorcio c on c.consorcioID = uf.consorcioID
		--join csc.gasto_ordinario g on g.consorcioID = uf.consorcioID
		--join csc.propietario p on p.unidadFuncionalID = uf.unidadFuncionalID
		--join csc.#TempExpensasExtra ee on ee.consorcioID = c.consorcioID
		--WHERE g.fecha between @fechaInicio and @fechaFin
		--	FOR XML PATH('Expensa'), ROOT('Expensas');
		DROP TABLE #TempExpensasExtra;
		--select * from csc.gasto_ordinario update  csc.gasto_ordinario set fecha =  DATEADD(MONTH,  4, fecha) 

	END
	GO
