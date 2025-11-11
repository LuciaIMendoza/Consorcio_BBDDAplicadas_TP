
PRINT '---------- Configuracion para habilitar los comandos OPENROWSET --------';
--EXEC sp_configure 'show advanced options', 1;
--RECONFIGURE;
--EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;
--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1;
--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1;
--EXEC sp_configure 'xp_cmdshell', 1;
--RECONFIGURE;
--Crea la Base de Datos
IF NOT EXISTS (
    SELECT name FROM sys.databases WHERE name = 'AltosSaintJust'
)
BEGIN
    CREATE DATABASE AltosSaintJust;
	IF EXISTS (
    SELECT name FROM sys.databases WHERE name = 'AltosSaintJust'
	)
		BEGIN
		PRINT 'Database AltosSaintJust creada con exito';
		END
END
GO

--USE bancos;

USE AltosSaintJust;

---CREA ROLES
CREATE ROLE AdministrativoGeneral;
CREATE ROLE AdministrativoBancario;
CREATE ROLE AdministrativoOperativo;
CREATE ROLE Sistemas;

--En el menu Query tildar la opcion SQLCMDMODE para poder correr los script de creacion de sp

PRINT 'Ejecuta la creacion del sp de estructura de tablas';
:r C:\consorcios\StoreProcedureCreacion.sql
PRINT 'Llama al sp que crea la estructura de tablas';
exec p_Crear_Estructura_CSC;

PRINT 'Ejecuta funciones';
:r C:\consorcios\FunctionObtenerFechaPorMes.sql

PRINT '------Ejecuta la creacion de los SP de importacion-------';
PRINT 'Importacion de consorcios';
:r C:\consorcios\StoreProcedureConsorcios.sql
PRINT 'Importacion UF';
:r C:\consorcios\StoreProcedureImportarUF.sql
PRINT 'Imprtacion CBU';
:r C:\consorcios\StoreProcedureImportarCBUCVU.sql
PRINT 'Importar Inquilinos y propietarios';
:r C:\consorcios\StoreProcedureImportarInqPro.sql
PRINT 'Importar Gastos';
:r C:\consorcios\StoreProcedureImportarGastos.sql
PRINT 'Importar Pagos';
:r C:\consorcios\StoreProcedurePagos.sql

PRINT 'Importar reportes';
:r C:\consorcios\Reporte1.sql
:r C:\consorcios\Reporte2.sql
:r C:\consorcios\Reporte3.sql
:r C:\consorcios\Reporte4.sql
:r C:\consorcios\Reporte5.sql
:r C:\consorcios\Reporte6.sql

GRANT EXECUTE ON csc.p_ReporteGastosSemanales 
TO AdministrativoGeneral, AdministrativoBancario, AdministrativoOperativo, Sistemas;

GRANT EXECUTE ON csc.p_ReporteRecaudacionPorMesYDepto 
TO AdministrativoGeneral, AdministrativoBancario, AdministrativoOperativo, Sistemas;

GRANT EXECUTE ON csc.p_ReporteRecaudacionPorProcedencia_XML 
TO AdministrativoGeneral, AdministrativoBancario, AdministrativoOperativo, Sistemas;

GRANT EXECUTE ON csc.p_ReporteTopMesesGastosIngresos 
TO AdministrativoGeneral, AdministrativoBancario, AdministrativoOperativo, Sistemas;

GRANT EXECUTE ON csc.p_ReportePropietariosMorosos 
TO AdministrativoGeneral, AdministrativoBancario, AdministrativoOperativo, Sistemas;

GRANT EXECUTE ON csc.p_ReportePagosExpensasOrdinarias 
TO AdministrativoGeneral, AdministrativoBancario, AdministrativoOperativo, Sistemas;

PRINT '----------Inicio de Importacion de datos --------';
--Ejecuta el sp de Importacion de datos de consorcios
exec csc.p_ImportarConsorcios @RutaArchivo = 'C:\consorcios\datos varios.xlsx', @Hoja = 'Consorcios'

--select * from csc.Consorcio

PRINT 'Ejecuta el SP de Importacion de datos de Unidades Funcionales';
EXEC csc.p_ImportarUnidadFuncional 
     @RutaArchivo = 'C:\consorcios\UF por consorcio.txt';

--select * from csc.Unidad_Funcional

PRINT 'Ejecuta el SP de Importacion de relaciones entre Unidades Funcionales e Inquilinos/Propietarios';
EXEC csc.p_ImportarCBU @RutaArchivo = N'C:\consorcios\Inquilino-propietarios-UF.csv';

--select * from csc.Unidad_Funcional


PRINT 'Ejecuta el SP de Importacion de datos de Inquilinos y propietarios';
exec csc.p_ImportarPersonas @RutaArchivo = 'C:\consorcios\Inquilino-propietarios-datos.csv';
--select * from csc.Inquilino;
--select * from csc.Propietario;  

PRINT 'Ejecuta el SP de Importacion de datos de los Gastos de los consorcios';
EXEC  csc.p_ImportarGastos @RutaArchivo = 'C:\consorcios\Servicios.Servicios.json', @FechaCarga = '2025-11-2';

GRANT EXECUTE ON csc.p_ImportarGastos TO AdministrativoBancario;

--SELECT * from csc.Gasto_Ordinario 
--SELECT * from csc.Servicio_Publico
--SELECT * from csc.Servicio_Limpieza 
--SELECT * from csc.Gasto_General

PRINT 'Ejecuta el SP de Importacion de datos de los Pagos al consorcio';
EXEC csc.p_ImportarPagos
    @RutaArchivo = 'C:\consorcios\pagos_consorcios.csv',
    @NombreArchivo = 'pagos_consorcios.csv',
    @FechaCSV = '2025-11-2';
GRANT EXECUTE ON csc.p_ImportarPagos TO AdministrativoBancario;

--select * From csc.CSV_Importado
--select * from csc.Detalle_CSV
--select * from csc.pago


--delete from csc.Servicio_Publico
--delete from csc.Servicio_Limpieza 
--delete from csc.Gasto_General
--delete from csc.Gasto_Ordinario 
--DELETE FROM CSC.INQUILINO
--DELETE FROM CSC.PROPIETARIO
--DELETE FROM CSC.UNIDAD_FUNCIONAL 
--DELETE FROM CSC.CONSORCIO

