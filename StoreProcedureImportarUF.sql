use AltosSaintJust
go
CREATE OR ALTER PROCEDURE csc.p_ImportarUnidadFuncional
    @RutaArchivo NVARCHAR(4000)   -- Ruta completa del archivo a importar
AS
BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------
    -- 1. Validar existencia del archivo
    DECLARE @FileExists INT;
    EXEC master.dbo.xp_fileexist @RutaArchivo, @FileExists OUTPUT;

    IF @FileExists = 0
    BEGIN
        RAISERROR('El archivo especificado no existe o no se puede acceder: %s', 16, 1, @RutaArchivo);
        RETURN;
    END;

    -------------------------------------------------
    -- 2. Eliminar tabla temporal si existe
    IF OBJECT_ID('tempdb..#TempUF') IS NOT NULL
        DROP TABLE #TempUF;

    -------------------------------------------------
    -- 3. Crear tabla temporal
    CREATE TABLE #TempUF (
        NombreConsorcio NVARCHAR(100),
        nroUnidadFuncional INT,
        Piso CHAR(2),
        Departamento CHAR(1),
        Coeficiente NVARCHAR(10),
        m2_unidad_funcional NVARCHAR(10),
        Bauleras NVARCHAR(2),
        Cochera NVARCHAR(2),
        m2_baulera NVARCHAR(10),
        m2_cochera NVARCHAR(10)
    );

    -------------------------------------------------
    -- 4. Cargar datos desde el archivo recibido por parámetro
    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = N'
        BULK INSERT #TempUF
        FROM ''' + REPLACE(@RutaArchivo, '''', '''''') + N'''
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ''\t'',
            ROWTERMINATOR = ''\n'',
            CODEPAGE = ''65001'',
            DATAFILETYPE = ''char''
        );
    ';
    EXEC sp_executesql @SQL;

    -------------------------------------------------
    -- 5. Insertar unidades funcionales que falten
    INSERT INTO csc.Unidad_Funcional
        (consorcioID, piso, departamento, superficieM2, cochera, baulera, coeficiente)
    SELECT
        c.consorcioID,
        t.Piso,
        t.Departamento,
        TRY_CAST(REPLACE(t.m2_unidad_funcional, ',', '.') AS DECIMAL(6,2)),
        CASE WHEN t.Cochera = 'SI' THEN 1 ELSE 0 END,
        CASE WHEN t.Bauleras = 'SI' THEN 1 ELSE 0 END,
        TRY_CAST(REPLACE(t.Coeficiente, ',', '.') AS DECIMAL(4,2))
    FROM #TempUF t
    JOIN csc.Consorcio c
        ON LTRIM(RTRIM(c.nombre)) = LTRIM(RTRIM(t.NombreConsorcio))
    WHERE NOT EXISTS (
        SELECT 1
        FROM csc.Unidad_Funcional uf
        WHERE uf.consorcioID = c.consorcioID
          AND uf.piso = t.Piso
          AND uf.departamento = t.Departamento
    );

    -------------------------------------------------
    -- 6. Limpiar tabla temporal
    DROP TABLE #TempUF;

    PRINT 'Importación de unidades funcionales finalizada correctamente.';
END;
GO

--EXEC csc.p_ImportarUnidadFuncional 
--     @RutaArchivo = 'C:\consorcios\UF por consorcio.txt';

--select * from csc.Unidad_Funcional
