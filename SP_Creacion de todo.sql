USE AltosSaintJust

exec p_Crear_Estructura_CSC;

INSERT INTO csc.Consorcio (nombre, direccion, superficieM2Total) VALUES ('Azcuenaga', 'Belgrano 3344', 1281.00), 
('Alzaga', 'Callao 1122', 914.00), ('Alberdi', 'Santa Fe 910', 784.00), 
('Unzue', 'Corrientes 5678', 1316.00), 
('Pereyra Iraola', 'Rivadavia 1234', 1691.00);

select * from csc.Consorcio


EXEC csc.p_ImportarUnidadFuncional 
     @RutaArchivo = 'C:\consorcios\UF por consorcio.txt';

select * from csc.Unidad_Funcional

EXEC csc.p_ImportarCBU @RutaArchivo = N'C:\consorcios\Inquilino-propietarios-UF.csv';

select * from csc.Unidad_Funcional


exec csc.p_ImportarPersonas @RutaArchivo = 'C:\consorcios\Inquilino-propietarios-datos.csv';
select * from csc.Inquilino;
select * from csc.Propietario;  

exec  csc.p_ImportarGastos @RutaArchivo = 'C:\consorcios\Servicios.Servicios.json';





DELETE FROM CSC.CONSORCIO
DELETE FROM CSC.UNIDAD_FUNCIONAL 
DELETE FROM CSC.INQUILINO
DELETE FROM CSC.PROPIETARIO


