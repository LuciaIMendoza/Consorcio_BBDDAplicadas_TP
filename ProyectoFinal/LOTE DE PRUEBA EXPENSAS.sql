USE AltosSaintJust
go
------------------------------------------------------------
-- Gastos extraordinarios de abril
------------------------------------------------------------
INSERT INTO csc.Gasto_Extraordinario
    (documentoID, consorcioID, razonSocial, fecha, importeTotal, formaPago, nroCuota)
VALUES
    (NULL, 1, 'Reparación ascensor', '2025-04-05', 250000.00, 'TOTAL', 1),
    (NULL, 2, 'Cambio cañerías', '2025-04-12', 450000.00, 'CUOTAS', 3);
------------------------------------------------------------
-- Prueba 1: Generar expensas de ABRIL 2025
------------------------------------------------------------
EXEC csc.p_CalcularExpensas @mes = 4, @anio = 2025;
select * from csc.estado_cuentas

------------------------------------------------------------
-- Prueba 2: Generar expensas de MAYO 2025
------------------------------------------------------------

EXEC csc.p_CalcularExpensas @mes = 5, @anio = 2025;
select * from csc.estado_cuentas

------------------------------------------------------------
-- Limpieza
------------------------------------------------------------
--DELETE FROM csc.Servicio_Publico;
--DBCC CHECKIDENT ('csc.Servicio_Publico', RESEED, 0);

--DELETE FROM csc.Servicio_Limpieza;
--DBCC CHECKIDENT ('csc.Servicio_Limpieza', RESEED, 0);

--DELETE FROM csc.Gasto_General;
--DBCC CHECKIDENT ('csc.Gasto_General', RESEED, 0);

--DELETE FROM csc.Gasto_Ordinario;
--DBCC CHECKIDENT ('csc.Gasto_Ordinario', RESEED, 0);

--DELETE FROM csc.Gasto_Extraordinario;
--DBCC CHECKIDENT ('csc.Gasto_Extraordinario', RESEED, 0);

--DELETE FROM csc.Estado_Cuentas;
--DBCC CHECKIDENT ('csc.Estado_Cuentas', RESEED, 0);

--DELETE FROM csc.Expensas;
--DBCC CHECKIDENT ('csc.Expensas', RESEED, 0);