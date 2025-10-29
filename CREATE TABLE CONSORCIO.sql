use AltosSaintJust

CREATE TABLE csc.Consorcio(
	consorcioID int identity(1,1),
	nombre char(100) NOT NULL,
	DIRECCION CHAR(300) NOT NULL,
	superficieM2Total int NOT NULL,
	CONSTRAINT PK_ConsorcioID PRIMARY KEY (consorcioID),
);


CREATE TABLE csc.Unidad_Funcional(
	unidadFuncionalID int identity(1,1),
	consorcioID int NOT NULL,
	piso char(2) NOT NULL,
	departamento char(1) NOT NULL,
	superficieM2 int NOT NULL,
	cochera tinyint NULL,
	baulera tinyint NULL,
	CBU char(22) NULL,
	CVU char(22) NULL, 
	coeficiente decimal(1,1) NOT NULL,
	CONSTRAINT PK_UnidadFuncionalID PRIMARY KEY (unidadFuncionalID),
	CONSTRAINT FK_UF_Consorcio FOREIGN KEY (consorcioID)
		REFERENCES csc.Consorcio(consorcioID)
);

CREATE TABLE csc.Propietario(
	DNI char(10),
	unidadFuncionalID int NULL,
	nombre char(100) NOT NULL, 
	apellido char(100) NOT NULL,
	mail char(200) NULL,
	telefono char(20) NULL,
	modoEntrega bit NOT NULL
	CONSTRAINT PK_PropietarioID PRIMARY KEY (DNI),
	CONSTRAINT FK_Propietario_UF FOREIGN KEY (unidadFuncionalID)
		REFERENCES csc.Unidad_Funcional(unidadFuncionalID)
);

CREATE TABLE csc.Inquilino(
	DNI char(10),
	unidadFuncionalID int NULL,
	nombre char(100) NOT NULL, 
	apellido char(100) NOT NULL,
	mail char(200) NULL,
	telefono char(20) NULL
	CONSTRAINT PK_InquilinoID PRIMARY KEY (DNI),
	CONSTRAINT FK_Inquilino_UF FOREIGN KEY (unidadFuncionalID)
		REFERENCES csc.Unidad_Funcional(unidadFuncionalID)
);


CREATE TABLE csc.Expensas(
	documentoID int IDENTITY(1,1),
	consorcioID int NOT NULL,
	mes bit NOT NULL,
	anio int NOT NULL,
	fechaGenerado date NOT NULL,
	fechaEnvio date NOT NULL,
	medioEnvio int NOT NULL,
	aPropietario bit NOT NULL,
	aInquilino bit NOT NULL,
	CONSTRAINT PK_Expensas PRIMARY KEY (documentoID),
	CONSTRAINT FK_Expensas_Consorcio FOREIGN KEY (consorcioID)
		REFERENCES csc.consorcio(consorcioID)
);

CREATE TABLE csc.Estado_Financiero(
	estadoFinancieroID int IDENTITY(1,1),
	documentoID int NOT NULL, 
	saldoAnterior decimal(8,2) NULL,
	ingresosEnTermino decimal(8,2) NULL,
	ingresosAdeudados decimal(8,2) NULL,
	egresosTotales decimal(8,2) NULL,
	saldoFinal decimal(8,2) NULL,
	CONSTRAINT PK_EstadoFinanciero PRIMARY KEY (estadoFinancieroID),
	CONSTRAINT FK_EstadoFin_Expensas FOREIGN KEY (documentoID)
		REFERENCES csc.expensas(documentoID)
);

CREATE TABLE csc.Estado_Cuentas(
	estadoCuentasID int IDENTITY(1,1),
	documentoID int NOT NULL, 
	unidadFuncionalID int NOT NULL,
	saldoAnterior decimal(8,2) NULL,
	pagosRecibidos decimal(8,2) NULL,
	deuda decimal(8,2) NULL,
	InteresesPorMora decimal(8,2) NULL,
	expensasOrdinarias decimal(8,2) NULL,
	expensasExtraordinarias decimal(8,2) NULL,
	totalPagar decimal(8,2) NULL,
	CONSTRAINT PK_EstadoCuentas PRIMARY KEY (estadoCuentasID),
	CONSTRAINT FK_EstadoCuentas_Expensas FOREIGN KEY (documentoID)
		REFERENCES csc.expensas(documentoID),
	CONSTRAINT FK_EstadoCuentas_UF FOREIGN KEY (unidadFuncionalID)
		REFERENCES csc.Unidad_Funcional(unidadFuncionalID)
);

CREATE TABLE csc.Gasto_Extraordinario(
	gastoExtraordinarioID int identity(1,1) NOT NULL, 
	documentoID int NOT NULL, 
	tipoGasto char(200) NOT NULL,
	importeTotal decimal(8,2) NOT NULL,
	formaPago char(6) NOT NULL, 
	detalle char (300) NOT NULL,
	CONSTRAINT PK_GastoExtraordinario PRIMARY KEY (gastoExtraordinarioID),
	CONSTRAINT FK_GastoExtrao_Expensas FOREIGN KEY (documentoID)
		REFERENCES csc.expensas(documentoID),
	CONSTRAINT CHK_FormaPago 
		CHECK ( formaPago in ('TOTAL' ,'CUOTAS'))
	);

CREATE TABLE csc.Cuota_Gasto(
	cuotaID int identity(1,1),
	gastoExtraordinarioID int NOT NULL,
	nroCuota char(4) NOT NULL, 
	totalCuota decimal(8,2) NOT NULL,
	importeCuota decimal(8,2) NOT NULL,
	CONSTRAINT PK_CuotaGasto PRIMARY KEY (cuotaID),
	CONSTRAINT FK_cuotaGasto_GastoExtra FOREIGN KEY (gastoExtraordinarioID)
		REFERENCES csc.Gasto_Extraordinario(gastoExtraordinarioID)
);

CREATE TABLE csc.Gasto_Ordinario(
	gastoOrdinarioID int IDENTITY(1,1),
	documentoID int NOT NULL,
	tipoGasto char(27) NOT NULL,
	importeTotal decimal(8,2) NOT NULL,
	detalle char(300),
	CONSTRAINT PK_GastoOrdinario PRIMARY KEY (gastoOrdinarioID),
	CONSTRAINT FK_GastoOrdinario_Expensas FOREIGN KEY (documentoID)
		REFERENCES csc.Expensas( documentoID),
	CONSTRAINT CHK_TipoGasto -- csc.tabTipoGasto Para estos? 
		CHECK(tipoGasto in('BANCARIOS', 'LIMPIEZA', 'ADMINISTRACION', 'SEGUROS',
			'GASTOS GENERALES', 'SERVICIOS PUBLICOS-Agua', 'SERVICIOS PUBLICOS-Luz', 'SERVICIOS PUBLICOS-Internet'))
);

CREATE TABLE csc.Gasto_General(
	gastoGeneralID int IDENTITY(1,1),
	gastoOrdinarioID int NOT NULL, 
	tipo char(27) NOT NULL, 
	empresaoPersona bit NOT NULL, 
	nroFactura char(13) NOT NULL, 
	importe decimal(8,2) NOT NULL,
	CONSTRAINT PK_GastoGeneral PRIMARY KEY (gastoGeneralID),
	CONSTRAINT FK_GastoGral_GastoOrd FOREIGN KEY (gastoOrdinarioID)
		REFERENCES csc.Gasto_Ordinario(gastoOrdinarioID),
	CONSTRAINT CHK_TipoGasto 
		CHECK(tipo in('BANCARIOS', 'ADMINISTRACION', 'SEGUROS',
		'GASTOS GENERALES'))

);

CREATE TABLE csc.Servicio_Publico(
	servicioPublicoID int IDENTITY(1,1),
	gastoOrdinarioID int NOT NULL,
	tipo char(27) NOT NULL, 
	Empresa char(100) NOT NULL, 
	nroFactura char(13) NOT NULL, 
	importe decimal(8,2) NOT NULL,
	CONSTRAINT PK_ServicioPublico PRIMARY KEY (servicioPublicoID),
	CONSTRAINT FK_ServicioPubl_GastoOrd FOREIGN KEY (gastoOrdinarioID)
		REFERENCES csc.Gasto_Ordinario (gastoOrdinarioID)
);

CREATE TABLE csc.Servicio_Limpieza(
	servicioLimpiezaID int IDENTITY(1,1),
	gastoOrdinarioID int NOT NULL,
	--modalidad  
	nombre char(100)  NULL,
	nroFactura char(13) NOT NULL, 
	importe decimal(8,2) NOT NULL,
	CONSTRAINT PK_ServicioLimpieza PRIMARY KEY (servicioLimpiezaID),
	CONSTRAINT FK_ServicioLimp_GastoOrd FOREIGN KEY (gastoOrdinarioID)
		REFERENCES csc.Gasto_Ordinario (gastoOrdinarioID)
);

CREATE TABLE csc.pago(
	pagoID int IDENTITY(1,1),
	unidadFuncionalID int NOT NULL,
	cuentaOrigen char(22) NULL,
	monto decimal (8,2) NOT NULL,
	asociado bit NULL,
	CONSTRAINT PK_Pago PRIMARY KEY (pagoID),
	CONSTRAINT FK_Pago_UF FOREIGN KEY (unidadFuncionalID)
		REFERENCES csc.Unidad_Funcional(unidadFuncionalID)
);

CREATE TABLE csc.CSV_Importado(
	importacionID int IDENTITY(1,1),
	fechaImportacion DATE NOT NULL, 
	nombreArchivo char(400) NOT NULL,
	fechaCSV date NOT NULL,
	CONSTRAINT PK_CSVImportado PRIMARY KEY (importacionID)
	);

CREATE TABLE csc.Detalle_CSV(
	detallesID int IDENTITY(1,1),
	pagoID int NOT NULL, 
	importacionID int NOT NULL,
	fechaPago date NOT NULL,
	cuentaOrigen char(22) NULL, 
	importe decimal(8,2) NOT NULL,
	CONSTRAINT PK_DetalleCSV PRIMARY KEY (detallesID),
	CONSTRAINT FK_DetalleCSV_Pago FOREIGN KEY (pagoID)
		REFERENCES csc.Pago (pagoID),
	CONSTRAINT FK_DetalleCSV_Importacion FOREIGN KEY (importacionID)
		REFERENCES csc.CSV_Importado (importacionID)
);