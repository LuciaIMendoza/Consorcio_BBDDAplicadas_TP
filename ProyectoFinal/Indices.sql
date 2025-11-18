USE AltosSaintJust
GO

-- Reporte 3: Recaudación por Procedencia
CREATE NONCLUSTERED INDEX IX_GastoOrdinario_ConsorcioID
ON csc.Gasto_Ordinario(consorcioID);

CREATE NONCLUSTERED INDEX IX_GastoExtraordinario_ConsorcioID
ON csc.Gasto_Extraordinario(consorcioID);

-- Reporte 4: Top meses gastos e ingresos
CREATE NONCLUSTERED INDEX IX_GastoOrdinario_Fecha
ON csc.Gasto_Ordinario(fecha);

CREATE NONCLUSTERED INDEX IX_GastoExtraordinario_Fecha
ON csc.Gasto_Extraordinario(fecha);

CREATE NONCLUSTERED INDEX IX_Pago_Fecha
ON csc.Detalle_CSV(fechaPago);

-- Reporte 5: Propietarios morosos
CREATE NONCLUSTERED INDEX IX_Propietario_UF
ON csc.Propietario(unidadFuncionalID);

CREATE NONCLUSTERED INDEX IX_EstadoCuentas_UF
ON csc.Estado_Cuentas(unidadFuncionalID);

CREATE NONCLUSTERED INDEX IX_Expensas_AnioMes
ON csc.Expensas(anio, mes);

-- Reporte 6: Fechas de pagos de expensas y días entre pagos
CREATE NONCLUSTERED INDEX IX_DetalleCSV_UF
ON csc.Detalle_CSV(pagoID);

CREATE NONCLUSTERED INDEX IX_Pago_UF
ON csc.Pago(unidadFuncionalID);

CREATE NONCLUSTERED INDEX IX_DetalleCSV_FechaPago
ON csc.Detalle_CSV(fechaPago);