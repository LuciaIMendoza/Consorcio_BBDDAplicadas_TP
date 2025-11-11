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
                    WHEN gex.formaPago = 'CUOTAS' THEN ISNULL(cg_sum.totalCuotaMes, 0)
                    ELSE 0
                END
            ) AS totalExtraordinario
        FROM csc.Gasto_Extraordinario gex
        OUTER APPLY (
            SELECT 
            SUM(cg.importeCuota) AS totalCuotaMes
        FROM csc.Cuota_Gasto cg
        WHERE cg.gastoExtraordinarioID = gex.gastoExtraordinarioID
          AND DATEADD(MONTH, cg.nroCuota - 1, EOMONTH(gex.fecha, -1)) 
                BETWEEN DATEFROMPARTS(@anio, @mes, 1)
                AND EOMONTH(DATEFROMPARTS(@anio, @mes, 1))
        ) cg_sum
        WHERE YEAR(gex.fecha) = @anio AND MONTH(gex.fecha) = @mes
        GROUP BY gex.consorcioID
    ) gex_total ON gex_total.consorcioID = c.consorcioID

    ORDER BY c.consorcioID;

    ------------------------------------------------------------
    -- Asociar GASTOS ORDINARIOS sin documentoID a su expensa correspondiente
    ------------------------------------------------------------
    UPDATE go
    SET go.documentoID = e.documentoID
    FROM csc.Gasto_Ordinario go
    INNER JOIN csc.Expensas e
        ON e.consorcioID = go.consorcioID
       AND MONTH(go.fecha) = e.mes
       AND YEAR(go.fecha) = e.anio
    WHERE go.documentoID IS NULL;

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

END;

GO

    ------------------------------------------------------------
    -- Cargar estados de cuentas
 --   ------------------------------------------------------------
	--INSERT INTO csc.Estado_Cuentas(documentoID, unidadFuncionalID,saldoAnterior,pagosRecibidos, 
	--deuda, InteresesPorMora, expensasOrdinarias,expensasExtraordinarias, totalPagar)
	--SELECT 
	--e.documentoID,
	--uf.unidadFuncionalID,
	----saldoAnterior,
	----pagosRecibidos,
	----deuda,
	----InteresesPorMora,
	----expensasOrdinarias,
	----expensasExtraordinarias,
	----totalPagar
	--FROM csc.Expensas e
	--join csc.Unidad_Funcional uf on uf.consorcioID = e.consorcioID
	--join csc.u
	--where e.mes = @mes 
 --   AND e.anio = @anio

 SELECT 
    uf.unidadFuncionalID,
    e.documentoID,
    ISNULL(ec_prev.totalPagar, 0) AS saldoAnterior, 
    ISNULL(pagos_mes.totalPagos, 0) AS pagosRecibidos,
    (
        ISNULL(ec_prev.totalPagar, 0)
        + ISNULL(exp_mes.expOrdinarias, 0)
        + ISNULL(exp_mes.expExtraordinarias, 0)
        - ISNULL(pagos_mes.totalPagos, 0)
    ) AS deuda,
    CASE 
        WHEN pagos_mes.fechaUltimoPago BETWEEN e.fechaPrimerVto AND e.fechaSegundoVto THEN ISNULL(ec_prev.totalPagar, 0) * 0.02
        WHEN pagos_mes.fechaUltimoPago > e.fechaSegundoVto THEN ISNULL(ec_prev.totalPagar, 0) * 0.05
        ELSE 0
    END AS InteresesPorMora,
    ISNULL(exp_mes.expOrdinarias, 0) AS expensasOrdinarias,
    ISNULL(exp_mes.expExtraordinarias, 0) AS expensasExtraordinarias,

    (
        ISNULL(ec_prev.totalPagar, 0)
        + ISNULL(exp_mes.expOrdinarias, 0)
        + ISNULL(exp_mes.expExtraordinarias, 0)
        + CASE 
            WHEN pagos_mes.fechaUltimoPago BETWEEN e.fechaPrimerVto AND e.fechaSegundoVto THEN ISNULL(ec_prev.totalPagar, 0) * 0.02
            WHEN pagos_mes.fechaUltimoPago > e.fechaSegundoVto THEN ISNULL(ec_prev.totalPagar, 0) * 0.05
            ELSE 0
          END
        - ISNULL(pagos_mes.totalPagos, 0)
    ) AS totalPagar

FROM csc.Expensas e
JOIN csc.Unidad_Funcional uf ON uf.consorcioID = e.consorcioID
LEFT JOIN csc.Estado_Cuentas ec_prev
    ON ec_prev.unidadFuncionalID = uf.unidadFuncionalID
    AND MONTH(DATEADD(MONTH, 1, DATEFROMPARTS(@anio, @mes, 1))) = @mes
    AND YEAR(DATEADD(MONTH, 1, DATEFROMPARTS(@anio, @mes, 1))) = @anio - CASE WHEN @mes = 1 THEN 1 ELSE 0 END
OUTER APPLY (
    SELECT 
        SUM(p.importePago) AS totalPagos,
        MAX(p.fechaPago) AS fechaUltimoPago
    FROM csc.Pago p
    WHERE p.unidadFuncionalID = uf.unidadFuncionalID
      AND YEAR(p.fechaPago) = @anio
      AND MONTH(p.fechaPago) = @mes
) pagos_mes
OUTER APPLY (
    SELECT
        SUM(go.importeTotal * (uf.porcentaje / 100.0)) AS expOrdinarias,
        (
            SELECT SUM(
                CASE 
                    WHEN ge.formaPago = 'TOTAL' THEN ge.importeTotal
                    WHEN ge.formaPago = 'CUOTAS' THEN ISNULL(cg.importeCuota, 0)
                    ELSE 0
                END * (uf.porcentaje / 100.0)
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
        ) AS expExtraordinarias
    FROM csc.Gasto_Ordinario go
    WHERE YEAR(go.fecha) = @anio AND MONTH(go.fecha) = @mes
) exp_mes

ORDER BY uf.unidadFuncionalID;
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
select *  FROM csc.cuota_gasto;
GO

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
