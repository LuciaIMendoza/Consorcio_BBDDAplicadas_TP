use AltosSaintJust
go
CREATE OR ALTER PROCEDURE csc.p_ImportarUnidadFuncional
AS
BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------
    -- 1. Eliminar tabla temporal si existe
    IF OBJECT_ID('tempdb..#TempUF') IS NOT NULL
        DROP TABLE #TempUF;

    -------------------------------------------------
    -- 2. Crear tabla temporal
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
    -- 3. Cargar datos desde archivo .txt
    BULK INSERT #TempUF
    FROM 'C:\Users\marco\OneDrive\Escritorio\Unlam\consorcios\UF por consorcio.txt'
    WITH (
        FIRSTROW = 2,  -- Saltar fila de encabezado
        FIELDTERMINATOR = '\t',
        ROWTERMINATOR = '\n',
        CODEPAGE = '65001',
        DATAFILETYPE = 'char'
    );

    -------------------------------------------------
    -- 4. Insertar unidades funcionales que falten
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
    -- 5. Limpiar tabla temporal
    DROP TABLE #TempUF;

    PRINT 'Importación de unidades funcionales finalizada correctamente.';
END;