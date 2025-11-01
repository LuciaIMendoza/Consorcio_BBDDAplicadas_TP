USE AltosSaintJust;
GO


CREATE OR ALTER FUNCTION csc.SoloDigitos(@str NVARCHAR(100))
RETURNS NVARCHAR(100)
AS
BEGIN
    DECLARE @Result NVARCHAR(100) = '';
    DECLARE @i INT = 1;
    WHILE @i <= LEN(@str)
    BEGIN
        IF SUBSTRING(@str, @i, 1) LIKE '[0-9]'
            SET @Result += SUBSTRING(@str, @i, 1);
        SET @i += 1;
    END
    RETURN @Result;
END;
GO


CREATE OR ALTER PROCEDURE csc.p_ImportarPersonas
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF OBJECT_ID('tempdb..#TempPersonas') IS NOT NULL
            DROP TABLE #TempPersonas;

        CREATE TABLE #TempPersonas (
            Nombre NVARCHAR(100),
            Apellido NVARCHAR(100),
            DNI NVARCHAR(100),
            Email NVARCHAR(200),
            Telefono NVARCHAR(20),
            CBU_CVU CHAR(22),
            EsInquilino BIT
        );

        DECLARE @SQL NVARCHAR(MAX);

        SET @SQL = N'
            BULK INSERT #TempPersonas
            FROM ''' + @RutaArchivo + N'''
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = '';'',
                ROWTERMINATOR = ''\n'',
                CODEPAGE = ''65001'',
                TABLOCK
            );
        ';
        EXEC sp_executesql @SQL;

        -- Limpiar DNI: solo números
        UPDATE #TempPersonas
        SET DNI = csc.SoloDigitos(DNI);

        -- Eliminar DNIs vacíos o demasiado cortos/largos
        DELETE FROM #TempPersonas WHERE LEN(DNI) < 7 OR LEN(DNI) > 8 OR DNI IS NULL;

        -- Rellenar con ceros a la izquierda (para que todos sean CHAR(8))
        UPDATE #TempPersonas
        SET DNI = RIGHT('00000000' + DNI, 8);

        --------------------------------------------------------------
        -- Insertar Propietarios (solo si no existen)
        --------------------------------------------------------------
        INSERT INTO csc.Propietario (DNI, unidadFuncionalID, nombre, apellido, mail, telefono, modoEntrega)
        SELECT 
            CAST(T.DNI AS CHAR(8)),
            UF.unidadFuncionalID,
            LTRIM(RTRIM(T.Nombre)),
            LTRIM(RTRIM(T.Apellido)),
            LTRIM(RTRIM(T.Email)),
            LTRIM(RTRIM(T.Telefono)),
            'Mail' AS modoEntrega
        FROM #TempPersonas T
        INNER JOIN csc.Unidad_Funcional UF
            ON T.CBU_CVU = UF.CBU_CVU
        WHERE T.EsInquilino = 0
          AND NOT EXISTS (SELECT 1 FROM csc.Propietario P WHERE P.DNI = T.DNI);

        --------------------------------------------------------------
        -- Insertar Inquilinos (solo si no existen)
        --------------------------------------------------------------
        INSERT INTO csc.Inquilino (DNI, unidadFuncionalID, nombre, apellido, mail, telefono)
        SELECT 
            CAST(T.DNI AS CHAR(8)),
            UF.unidadFuncionalID,
            LTRIM(RTRIM(T.Nombre)),
            LTRIM(RTRIM(T.Apellido)),
            LTRIM(RTRIM(T.Email)),
            LTRIM(RTRIM(T.Telefono))
        FROM #TempPersonas T
        INNER JOIN csc.Unidad_Funcional UF
            ON T.CBU_CVU = UF.CBU_CVU
        WHERE T.EsInquilino = 1
          AND NOT EXISTS (SELECT 1 FROM csc.Inquilino I WHERE I.DNI = T.DNI);

        DROP TABLE #TempPersonas;
    END TRY

    BEGIN CATCH
        DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
        PRINT 'Error durante la importación: ' + @Msg;

        IF OBJECT_ID('tempdb..#TempPersonas') IS NOT NULL
            DROP TABLE #TempPersonas;

        RAISERROR(@Msg, 16, 1);
    END CATCH
END;
GO

--exec csc.p_ImportarPersonas @RutaArchivo = 'C:\consorcios\Inquilino-propietarios-datos.csv';
--select * from csc.Inquilino;
--select * from csc.Propietario;
