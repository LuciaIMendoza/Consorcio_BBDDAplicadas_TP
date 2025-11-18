
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

CREATE LOGIN userAdminGral  
   WITH PASSWORD = 'PassGral*'
	,CHECK_POLICY = on

CREATE LOGIN userAdminBanc   
   WITH PASSWORD = 'PassBanc*'
	,CHECK_POLICY = on

CREATE LOGIN userAdminOpr   
   WITH PASSWORD = 'PassOpr*'
	,CHECK_POLICY = on

CREATE LOGIN userSys   
   WITH PASSWORD = 'PassSys*'
	,CHECK_POLICY = on

	SELECT SRM.role_principal_id, SP.name AS Role_Name,   
SRM.member_principal_id, SP2.name  AS Member_Name  
FROM sys.server_role_members AS SRM  
JOIN sys.server_principals AS SP  
    ON SRM.Role_principal_id = SP.principal_id  
JOIN sys.server_principals AS SP2   
    ON SRM.member_principal_id = SP2.principal_id  
ORDER BY  SP.name,  SP2.name

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
1058435.64
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


--	insert into csc.gasto_extraordinario(importetotal, formapago, fecha, razonSocial )
--		values( 600000, 'CUOTAS', '2025-04-06', 'razonsocial1')
--		,( 150000, 'TOTAL', '2025-04-06','razonsocial2')
--		,( 14652.52, 'TOTAL', '2025-04-10','razon social 3')
--		,( 14444.4, 'TOTAL', '2025-04-01', 'razpn spcial 4')
--		,( 100000, 'CUOTAS', '2025-05-20', 'razon social 1')
--		,( 968500, 'TOTAL', '2025-05-14','razon social 3')
--select * from csc.gasto_extraordinario

--select * from csc.gasto_extraordinario
--		insert into csc.cuota_gasto (gastoextraordinarioid, nrocuota, totalcuota, importecuota)
--		values(28, 12, 600000, 50000), (24, 6, 100000, 33333.33)
		select * from csc.cuota_gasto
		select * from csc.gasto_extraordinario
		select * from csc.Cuota_Gasto


EXEC csc.p_CalcularExpensas @mes = 5, @anio = 2025;

select * from csc.Estado_Cuentas
select * from csc.Expensas
SELECT * FROM csc.Pago p
join csc.CSV_Importado c on c.
where unidadfuncionalid = 1
--delete from csc.Servicio_Publico
--delete from csc.Servicio_Limpieza 
--delete from csc.Gasto_General
--delete from csc.Gasto_Ordinario 
--delete from csc.csc.Cuota_Gasto
--delete from csc.Gasto_extraOrdinario 
--DELETE FROM CSC.INQUILINO
--DELETE FROM CSC.PROPIETARIO
--DELETE FROM CSC.UNIDAD_FUNCIONAL 
--DELETE FROM CSC.CONSORCIO
--DELETE FROM CSC.Estado_Cuentas
--DELETE FROM CSC.expensas


--resetear expensas

update csc.Gasto_Extraordinario set documentoid = null 
update csc.Gasto_ordinario set documentoid = null 
update csc.Estado_Cuentas set documentoid = null 
delete from csc.Estado_Cuentas
delete from csc.Expensas