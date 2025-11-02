USE AltosSaintJust
go

CREATE OR ALTER PROCEDURE csc.p_ImportarPagos
    @RutaArchivo NVARCHAR(500),      -- 'C:\consorcios\pagos_consorcios.csv'
    @NombreArchivo NVARCHAR(400),    -- 'pagos_consorcios.csv'
    @FechaCSV DATE = NULL            -- Si no se pasa, se usará GETDATE()
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -----------------------------------------------------
        -- Si no se especifica fecha, usar la actual
        -----------------------------------------------------
        IF @FechaCSV IS NULL
            SET @FechaCSV = CAST(GETDATE() AS DATE);

        -----------------------------------------------------
        -- Registra la importación
        -----------------------------------------------------
        DECLARE @ImportacionID INT;

        INSERT INTO csc.CSV_Importado (fechaImportacion, nombreArchivo, fechaCSV)
        VALUES (GETDATE(), @NombreArchivo, @FechaCSV);

        SET @ImportacionID = SCOPE_IDENTITY();

        IF OBJECT_ID('tempdb..##TempPagos') IS NOT NULL
            DROP TABLE ##TempPagos;

        CREATE TABLE ##TempPagos (
            IdPago INT,
            Fecha NVARCHAR(50),
            CVU_CBU CHAR(22),
            Valor NVARCHAR(50)
        );

        DECLARE @SQL NVARCHAR(MAX);

        SET @SQL = N'
            BULK INSERT ##TempPagos
            FROM ''' + @RutaArchivo + N'''
            WITH (
                FIELDTERMINATOR='','',
                ROWTERMINATOR=''\n'',
                FIRSTROW = 2,
                CODEPAGE = ''65001'',
                TABLOCK
            );
        ';

        EXEC (@SQL);

        -----------------------------------------------------
        -- Normalizamos los datos importados
        -----------------------------------------------------
        IF OBJECT_ID('tempdb..##PagosLimpios') IS NOT NULL
            DROP TABLE ##PagosLimpios;

        CREATE TABLE ##PagosLimpios (
            IdPago INT,
            Fecha DATE,
            CVU_CBU CHAR(22),
            Valor DECIMAL(10,2)
        );

 INSERT INTO ##PagosLimpios (IdPago, Fecha, CVU_CBU, Valor)
        SELECT
            IdPago,
            TRY_CONVERT(DATE, LTRIM(RTRIM(Fecha)), 103), -- formato dd/mm/yyyy
            LTRIM(RTRIM(CVU_CBU)),
            TRY_CONVERT(DECIMAL(12,2),
                REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(Valor)), '$', ''), '.', ''), ',', '.')
            )
        FROM ##TempPagos
        WHERE LTRIM(RTRIM(Valor)) <> '';


        INSERT INTO csc.Pago (unidadFuncionalID, cuentaOrigen, monto, asociado)
        SELECT
            uf.unidadFuncionalID,
            p.CVU_CBU,
            p.Valor,
            CASE WHEN uf.unidadFuncionalID IS NULL THEN 0 ELSE 1 END
        FROM ##PagosLimpios p
        LEFT JOIN csc.Unidad_Funcional uf
            ON uf.CBU_CVU = p.CVU_CBU;


        INSERT INTO csc.Detalle_CSV (pagoID, importacionID, fechaPago, cuentaOrigen, importe)
        SELECT
            pg.pagoID,
            @ImportacionID,
            p.Fecha,
            p.CVU_CBU,
            p.Valor
        FROM ##PagosLimpios p
        INNER JOIN csc.Pago pg
            ON pg.cuentaOrigen = p.CVU_CBU
            AND pg.monto = p.Valor;

    END TRY
    BEGIN CATCH
        PRINT '❌ Error durante la importación: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

--EXEC csc.p_ImportarPagos
    --@RutaArchivo = 'C:\consorcios\pagos_consorcios.csv',
    --@NombreArchivo = 'pagos_consorcios.csv',
    --@FechaCSV = '2025-11-2';

    --select * From csc.CSV_Importado
    --select * from csc.Detalle_CSV
    --select * from csc.pago