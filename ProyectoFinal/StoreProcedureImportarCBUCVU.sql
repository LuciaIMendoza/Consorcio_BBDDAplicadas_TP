USE AltosSaintJust;
GO

CREATE OR ALTER PROCEDURE csc.p_ImportarCBU
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        IF OBJECT_ID('tempdb..#TempCBUImport') IS NOT NULL
            DROP TABLE #TempCBUImport;

        CREATE TABLE #TempCBUImport (
            CBU_CVU CHAR(22),
            NombreConsorcio NVARCHAR(100),
            nroUnidadFuncional INT,
            piso CHAR(2),
            departamento CHAR(1)
        );

        DECLARE @SQL NVARCHAR(MAX);

        SET @SQL = N'
            BULK INSERT #TempCBUImport
            FROM ''' + @RutaArchivo + N'''
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ''|'',
                ROWTERMINATOR = ''\n'',
                CODEPAGE = ''65001'',
                TABLOCK
            );
        ';

        EXEC sp_executesql @SQL;

        UPDATE UF
        SET UF.CBU_CVU = T.CBU_CVU
        FROM csc.Unidad_Funcional UF
        INNER JOIN #TempCBUImport T
            ON UF.piso = T.piso
            AND UF.departamento = T.departamento
            AND UF.consorcioID = (
                SELECT consorcioID
                FROM csc.Consorcio C
                WHERE C.nombre = T.NombreConsorcio
            );

        DROP TABLE #TempCBUImport;

    END TRY

    BEGIN CATCH
        DECLARE @Msg NVARCHAR(4000);
        SET @Msg = ERROR_MESSAGE();

        PRINT 'Error al importar o actualizar CBU/CVU: ' + @Msg;

        IF OBJECT_ID('tempdb..#TempCBUImport') IS NOT NULL
            DROP TABLE #TempCBUImport;

        RAISERROR(@Msg, 16, 1);
    END CATCH
END;
GO

--EXEC csc.p_ImportarCBU @RutaArchivo = N'C:\consorcios\Inquilino-propietarios-UF.csv';
--select * from csc.Unidad_Funcional