--Crea la Base de Datos
IF NOT EXISTS (
    SELECT name FROM sys.databases WHERE name = 'AltosSaintJust'
)
BEGIN
    CREATE DATABASE AltosSaintJust;
END
GO

USE AltosSaintJust

--En el menu Query tildar la opcion SQLCMDMODE para poder correr los script de creacion de sp

--Ejecuta la creacion del sp de estructura de tablas
:r C:\consorcios\StoreProcedureCreacion.sql

--Llama al sp que crea la estructura de tablas
exec p_Crear_Estructura_CSC;

--Ejecuta la creacion de los SP de importacion
--Importacion de consorcios
:r C:\consorcios\StoreProcedureConsorcios.sql
--Importacion UF
:r C:\consorcios\StoreProcedureImportarUF.sql
--Imprtacion CBU
:r C:\consorcios\StoreProcedureImportarCBUCVU.sql
--Importar Inquilinos y propietarios
:r C:\consorcios\StoreProcedureImportarInqPro.sql
--Importar Gastos
:r C:\consorcios\StoreProcedureImportarGastos.sql
----------Importacion de datos --------
--Ejecuta el sp de Importacion de datos de consorcios
exec csc.p_ImportarConsorcios @RutaArchivo = 'C:\consorcios\datos varios.xlsx', @Hoja = 'Consorcios'

--select * from csc.Consorcio

--Ejecuta el SP de Importacion de datos de Unidades Funcionales
EXEC csc.p_ImportarUnidadFuncional 
     @RutaArchivo = 'C:\consorcios\UF por consorcio.txt';

--select * from csc.Unidad_Funcional

--Ejecuta el SP de Importacion de relaciones entre Unidades Funcionales e Inquilinos/Propietarios
EXEC csc.p_ImportarCBU @RutaArchivo = N'C:\consorcios\Inquilino-propietarios-UF.csv';

--select * from csc.Unidad_Funcional


--Ejecuta el SP de Importacion de datos de Inquilinos y propietarios
exec csc.p_ImportarPersonas @RutaArchivo = 'C:\consorcios\Inquilino-propietarios-datos.csv';
--select * from csc.Inquilino;
--select * from csc.Propietario;  

--Ejecuta el SP de Importacion de datos de los Gastos de los consorcios
EXEC  csc.p_ImportarGastos @RutaArchivo = 'C:\consorcios\Servicios.Servicios.json';
--SELECT * from csc.Gasto_Ordinario 
--SELECT * from csc.Servicio_Publico
--SELECT * from csc.Servicio_Limpieza 
--SELECT * from csc.Gasto_General




--DELETE FROM CSC.CONSORCIO
--DELETE FROM CSC.UNIDAD_FUNCIONAL 
--DELETE FROM CSC.INQUILINO
--DELETE FROM CSC.PROPIETARIO
--delete from csc.Gasto_Ordinario 
--delete from csc.Servicio_Publico
--delete from csc.Servicio_Limpieza 
--delete from csc.Gasto_General

