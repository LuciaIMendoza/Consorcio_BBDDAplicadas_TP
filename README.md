este es el orden de uso de SPs

1- csc.p_CrearEstructura_CSC (ya se puede usar despues csc.p_LimpiarEstructura_CSC)
2- csc.p_ImportarUnidadFuncional (debe tener datos la tabla de consorcios, de ejemplo usen el siguiente codigo
INSERT INTO csc.Consorcio (nombre, direccion, superficieM2Total)
VALUES 
('Azcuenaga', 'Calle Azcuenaga 123', 1200.50),
('Alzaga', 'Calle Alzaga 456', 900.00),
('Alberdi', 'Calle Alberdi 789', 1500.75),
('Unzue', 'Calle Unzue 321', 1100.00),
('Pereyra Iraola', 'Calle Pereyra 654', 1300.25);
