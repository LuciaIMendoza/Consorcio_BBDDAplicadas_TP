USE AltosSaintJust
go
CREATE or ALTER PROCEDURE p_CalcularExpensas @fecha DATE
AS
BEGIN
    SET NOCOUNT ON;

		
		DECLARE @fechaInicio DATE = SELECT DATEADD(MONTH, DATEDIFF(MONTH, 0, @fechaProceso), 0)
		DECLARE @fechaFin DATE = EOMONTH(@fechaProceso)



			SELECTs
				Uf.unidadFuncionalID AS [uf],
				uf.coeficiente AS [Porcentaje],
				concat(uf.piso, '-' ,uf.departamento) AS [PisoDepto],
				concat(p.apellido, ' ',p.nombre) AS [Propietario],
				g.importeTotal  AS [SaldoAnterior],
				g.importeTotal  AS [PagosRecibidos],
				0 AS [Deuda],
				0 AS [InteresMora],
				CAST(g.importeTotal * (uf.coeficiente / 100) AS DECIMAL(14,2))  AS [ExpensasOrdinarias],
				CASE WHEN (uf.cochera =1 ) THEN CAST(50000 AS DECIMAL(14,2)) ELSE CAST(0 AS decimal(14,2)) END AS [Cocheras],
				0 AS [ExpensasExtraordinarias],
				g.importeTotal  AS [TotalPagar]
			from csc.unidad_funcional uf
		join csc.consorcio c on c.consorcioID = uf.consorcioID
		join csc.gasto_ordinario g on g.consorcioID = uf.consorcioID
		join csc.propietario p on p.unidadFuncionalID = uf.unidadFuncionalID
		WHERE g.fecha between ()
			FOR XML PATH('Expensa'), ROOT('Expensas');

	END
	GO
