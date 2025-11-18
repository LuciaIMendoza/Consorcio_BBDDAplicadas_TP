USE AltosSaintJust;
GO

CREATE OR ALTER PROCEDURE csc.p_CalcularExpensas
    @mes INT = NULL,     
    @anio INT = NULL     
AS
BEGIN
    SET NOCOUNT ON;

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

INSERT INTO csc.Estado_Cuentas(
    documentoID, unidadFuncionalID, saldoAnterior, pagosRecibidos, 
    saldo, InteresesPorMora, expensasOrdinarias, expensasExtraordinarias, totalPagar
)
SELECT 
    e.documentoID,
    uf.unidadFuncionalID,
    ISNULL(sa.saldoAnterior, 0) AS saldoAnterior,
    ISNULL(pagos_mes.totalPagos, 0) AS pagosRecibidos,
    (ISNULL(sa.saldoAnterior, 0) - ISNULL(pagos_mes.totalPagos, 0)) AS saldo,

    -- Intereses por mora
    (
CASE 
    WHEN pagos_mes.fechaUltimoPago IS NULL 
         OR pagos_mes.fechaUltimoPago > DATEFROMPARTS(csc.fn_AnioAnterior(@mes,@anio), csc.fn_MesAnterior(@mes), 10)
    THEN ISNULL(sa.saldoAnterior, 0) * 0.02
    ELSE 0
END
+
CASE 
    WHEN pagos_mes.fechaUltimoPago IS NULL 
         OR pagos_mes.fechaUltimoPago > DATEFROMPARTS(csc.fn_AnioAnterior(@mes,@anio), csc.fn_MesAnterior(@mes), 15)
    THEN ISNULL(sa.saldoAnterior, 0) * 0.05
    ELSE 0
        END
    ) AS InteresesPorMora,

    -- Expensas proporcionales por UF
    (exp_mes.expOrdinarias * (uf.coeficiente / 100)) AS expensasOrdinarias,
    (exp_mes.expExtraordinarias * (uf.coeficiente / 100)) AS expensasExtraordinarias,

    -- Total por UF usando las mismas columnas ya calculadas
CASE 
    WHEN (
        ISNULL((ISNULL(sa.saldoAnterior, 0) - ISNULL(pagos_mes.totalPagos, 0)), 0)
        + (
            CASE 
                WHEN pagos_mes.fechaUltimoPago IS NULL 
                     OR pagos_mes.fechaUltimoPago > DATEFROMPARTS(@anio, @mes, 10)
                THEN ISNULL(sa.saldoAnterior, 0) * 0.02
                ELSE 0
            END
          +
            CASE 
                WHEN pagos_mes.fechaUltimoPago IS NULL 
                     OR pagos_mes.fechaUltimoPago > DATEFROMPARTS(@anio, @mes, 15)
                THEN ISNULL(sa.saldo, 0) * 0.05
                ELSE 0
            END
        )
        + (exp_mes.expOrdinarias * (uf.coeficiente / 100))
        + (exp_mes.expExtraordinarias * (uf.coeficiente / 100))
    ) < 0 
    THEN 0
    ELSE (
        ISNULL((ISNULL(sa.saldoAnterior, 0) - ISNULL(pagos_mes.totalPagos, 0)), 0)
        + (
            CASE 
                WHEN pagos_mes.fechaUltimoPago IS NULL 
                     OR pagos_mes.fechaUltimoPago > DATEFROMPARTS(@anio, @mes, 10)
                THEN ISNULL(sa.saldoAnterior, 0) * 0.02
                ELSE 0
            END
          +
            CASE 
                WHEN pagos_mes.fechaUltimoPago IS NULL 
                     OR pagos_mes.fechaUltimoPago > DATEFROMPARTS(@anio, @mes, 15)
                THEN ISNULL(sa.saldo, 0) * 0.05
                ELSE 0
            END
        )
        + (exp_mes.expOrdinarias * (uf.coeficiente / 100))
        + (exp_mes.expExtraordinarias * (uf.coeficiente / 100))
    )
END AS totalPagar

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
LEFT JOIN #TotalesGastos exp_mes ON exp_mes.consorcioID = e.consorcioID
WHERE e.anio = @anio AND e.mes = @mes
  AND NOT EXISTS (SELECT 1 FROM csc.Estado_Cuentas WHERE e.documentoID = documentoID);


    DROP TABLE #SaldoAnterior;
    DROP TABLE #TotalesGastos;

END;

GO





