USE AltosSaintJust
GO

DELETE FROM csc.Estado_Cuentas;
DBCC CHECKIDENT ('csc.Estado_Cuentas', RESEED, 0);
GO

DECLARE @i INT = 1;
DECLARE @max INT = 135;

WHILE @i <= @max
BEGIN
    INSERT INTO csc.Estado_Cuentas
        (documentoID, unidadFuncionalID, saldoAnterior, pagosRecibidos, deuda, InteresesPorMora, expensasOrdinarias, expensasExtraordinarias, totalPagar)
    VALUES
        (
            ((@i - 1) % 8) + 1, -- distribuye documentos 1–8
            @i, 
            ABS(CHECKSUM(NEWID()) % 12000) + 1000,  -- saldo anterior aleatorio
            ABS(CHECKSUM(NEWID()) % 8000),          -- pagos aleatorios
            ABS(CHECKSUM(NEWID()) % 10000),         -- deuda aleatoria
            ABS(CHECKSUM(NEWID()) % 600),           -- interés por mora
            ABS(CHECKSUM(NEWID()) % 5000),          -- expensas ordinarias
            ABS(CHECKSUM(NEWID()) % 3000),          -- extraordinarias
            0                                       -- se calcula luego
        );

    SET @i += 1;
END;

UPDATE csc.Estado_Cuentas
SET totalPagar = deuda + InteresesPorMora + expensasOrdinarias + expensasExtraordinarias;