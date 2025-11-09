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

INSERT INTO csc.Gasto_General (gastoOrdinarioID, tipo, empresaoPersona, nroFactura, importe)
VALUES
(1, 'ADMINISTRACION', 1, 'FAC001', 20000.00),
(1, 'SEGUROS', 1, 'FAC002', 10000.00),
(2, 'BANCARIOS', 1, 'FAC010', 15000.00),
(3, 'GASTOS GENERALES', 1, 'FAC020', 8000.00),
(4, 'ADMINISTRACION', 1, 'FAC030', 12000.00);
GO

INSERT INTO csc.Servicio_Limpieza (gastoOrdinarioID, modalidad, nombre, importe, nroFactura)
VALUES
(1, 'PERSONA', 'Juan Pérez', 20000.00, 'LIM001'),
(2, 'EMPRESA', 'Brillo S.A.', 25000.00, 'LIM010'),
(3, 'PERSONA', 'Carlos Gómez', 15000.00, 'LIM020'),
(4, 'EMPRESA', 'Clean Express', 18000.00, 'LIM030');
GO

INSERT INTO csc.Servicio_Publico (gastoOrdinarioID, tipo, Empresa, nroFactura, importe)
VALUES
(1, 'SERVICIOS PUBLICOS-Agua', 'Aguas Argentinas', 'PUB001', 15000.00),
(1, 'SERVICIOS PUBLICOS-Luz', 'Edesur', 'PUB002', 15000.00),
(2, 'SERVICIOS PUBLICOS-Luz', 'Edenor', 'PUB010', 20000.00),
(3, 'SERVICIOS PUBLICOS-Internet', 'Fibertel', 'PUB020', 27000.00),
(4, 'SERVICIOS PUBLICOS-Agua', 'AySA', 'PUB030', 40000.00);
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

