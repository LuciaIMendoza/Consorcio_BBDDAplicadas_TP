USE AltosSaintJust;
GO

------------ se Ejecuta esto para habilitar los comandos OPENROWSET --------
--EXEC sp_configure 'show advanced options', 1;
--RECONFIGURE;
--EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;
--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1;
--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1;

CREATE OR ALTER PROCEDURE csc.p_ImportarProveedores
    @RutaArchivo NVARCHAR(500),
    @Hoja NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;


	DECLARE @RutaArchivo NVARCHAR(500)  = 'C:\consorcios\datos varios.xlsx';
DECLARE @Hoja  NVARCHAR(50) = 'Proveedores';
DECLARE @Consulta NVARCHAR(MAX);
DECLARE @Sql NVARCHAR(MAX);

--BEGIN TRY
    IF OBJECT_ID('tempdb..##TempConsorcio') IS NOT NULL
        DROP TABLE ##TempConsorcio;

    CREATE TABLE ##TempConsorcio (
        tipo NVARCHAR(100),
        empresa NVARCHAR(100),
        detalle NVARCHAR(100),
        consorcio NVARCHAR(100)
    );

	-- habilitar OPENROWSET si tu SQL lo requiere
	EXEC sp_configure 'show advanced options', 1;  
	RECONFIGURE;  
	EXEC sp_configure 'Ad Hoc Distributed Queries', 1;  
	RECONFIGURE;  
	EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1;
	EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1;

    SET @Consulta = 'SELECT CAST(B AS NVARCHAR(100)), CAST(C AS NVARCHAR(100)), CAST(D AS NVARCHAR(100)), CAST(E AS NVARCHAR(100)) FROM [' + @Hoja + '$B2:E1048576]';

    SET @Sql = N'
        INSERT INTO ##TempConsorcio
        SELECT *
        FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0;HDR=YES;Database=' + REPLACE(@RutaArchivo,'''','''''') + ''',
            ''' + @Consulta + '''
        )
    ';

    EXEC sp_executesql @Sql;

    SELECT * FROM ##TempConsorcio;


        INSERT INTO csc.Consorcio (nombre, direccion, superficieM2Total)
        SELECT [Nombre del consorcio], Domicilio, [m2 totales]
        FROM ##TempConsorcio;

        PRINT 'Importación completada correctamente.';
    END TRY
    BEGIN CATCH
        PRINT 'Error durante la importación.';
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO

--exec csc.p_ImportarConsorcios @RutaArchivo = 'C:\consorcios\datos varios.xlsx',
--@Hoja = 'Consorcios'

--select * from csc.Consorcio