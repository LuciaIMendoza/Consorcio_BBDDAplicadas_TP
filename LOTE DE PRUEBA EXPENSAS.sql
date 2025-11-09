------------------------------------------------
--- LOTE DE PRUEBA
------------------------------------------------
INSERT INTO csc.Gasto_Ordinario (consorcioID, fecha, importeTotal)
VALUES
(1, '2025-09-15', 80000.00),   -- Azcuenaga, septiembre
(1, '2025-10-05', 90000.00),   -- Azcuenaga, octubre
(2, '2025-10-10', 50000.00),   -- Alzaga, octubre
(3, '2025-08-20', 70000.00);   -- Alberdi, agosto
GO

INSERT INTO csc.Gasto_Extraordinario (consorcioID, razonSocial, fecha, importeTotal, formaPago)
VALUES
(1, 'Pintura fachada', '2025-10-08', 100000.00, 'TOTAL'),  -- Azcuenaga, octubre
(2, 'Cambio ascensor', '2025-10-09', 150000.00, 'CUOTAS'), -- Alzaga, octubre
(2, 'Reparación caldera', '2025-09-15', 120000.00, 'TOTAL'), -- Alzaga, septiembre
(3, 'Impermeabilización techo', '2025-08-10', 200000.00, 'CUOTAS'); -- Alberdi, agosto
GO

INSERT INTO csc.Cuota_Gasto (gastoExtraordinarioID, nroCuota, totalCuota, importeCuota)
VALUES
(2, '001', 150000.00, 50000.00),
(2, '002', 150000.00, 50000.00),
(2, '003', 150000.00, 50000.00);

INSERT INTO csc.Cuota_Gasto (gastoExtraordinarioID, nroCuota, totalCuota, importeCuota)
VALUES
(4, '001', 200000.00, 50000.00),
(4, '002', 200000.00, 50000.00),
(4, '003', 200000.00, 50000.00),
(4, '004', 200000.00, 50000.00);
GO

------------------------------------------------------------
-- 🔹 Prueba 1: Generar expensas de OCTUBRE 2025
------------------------------------------------------------
EXEC csc.p_CalcularExpensas @mes = 10, @anio = 2025;

------------------------------------------------------------
-- 🔹 Verificar resultado de octubre
------------------------------------------------------------
SELECT * FROM csc.Expensas;
SELECT * FROM csc.Gasto_Ordinario;
SELECT * FROM csc.Gasto_Extraordinario;
GO

------------------------------------------------------------
-- 🔹 Prueba 2: Generar expensas de SEPTIEMBRE 2025
------------------------------------------------------------
EXEC csc.p_CalcularExpensas @mes = 9, @anio = 2025;

SELECT * FROM csc.Expensas;
SELECT * FROM csc.Gasto_Ordinario;
SELECT * FROM csc.Gasto_Extraordinario;
GO


------------------------------------------------------------
-- 🔹 Prueba 3: Generar expensas de AGOSTO 2025
------------------------------------------------------------
EXEC csc.p_CalcularExpensas @mes = 8, @anio = 2025;

SELECT * FROM csc.Expensas;
SELECT * FROM csc.Gasto_Ordinario;
SELECT * FROM csc.Gasto_Extraordinario;
GO
