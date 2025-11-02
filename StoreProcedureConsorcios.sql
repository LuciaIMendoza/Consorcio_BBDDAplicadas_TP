USE AltosSaintJust;
GO

------------ se Ejecuta esto para habilitar los comandos OPENROWSET --------
--EXEC sp_configure 'show advanced options', 1;
--RECONFIGURE;
--EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;
--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1;
--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1;

CREATE OR ALTER PROCEDURE csc.p_ImportarConsorcios
    @RutaArchivo NVARCHAR(500),
    @Hoja NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Consulta NVARCHAR(MAX);
    DECLARE @Sql NVARCHAR(MAX);

    BEGIN TRY
        IF OBJECT_ID('tempdb..##TempConsorcio') IS NOT NULL
            DROP TABLE ##TempConsorcio;

        CREATE TABLE ##TempConsorcio (
            Consorcio NVARCHAR(50),
            [Nombre del consorcio] NVARCHAR(100),
            Domicilio NVARCHAR(100),
            [Cant unidades funcionales] INT,
            [m2 totales] DECIMAL(10,2)
        );

		---------- se Ejecuta esto para habilitar los comandos OPENROWSET --------
		EXEC sp_configure 'show advanced options', 1;
		RECONFIGURE;
		EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
		RECONFIGURE;
		EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1;
		EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1;


        SET @Consulta = 'SELECT * FROM [' + @Hoja + '$]';

        SET @Sql = N'
            INSERT INTO ##TempConsorcio
            SELECT *
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0;HDR=YES;Database=' + REPLACE(@RutaArchivo,'''','''''') + ''',
                ''' + @Consulta + '''
            );';

        EXEC sp_executesql @Sql;

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