USE AltosSaintJust
go
CREATE or ALTER PROCEDURE p_Crear_Estructura_CSC
AS
BEGIN
    SET NOCOUNT ON;
    -- Creamos el schema si no existe
    IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'csc')
    BEGIN
        EXEC('CREATE SCHEMA csc AUTHORIZATION dbo;');
        PRINT 'Schema [csc] creado correctamente.';
    END
    ELSE
        PRINT 'El schema [csc] ya existe.';
    ------------------------------------------------------------
    -- Tabla: Consorcio
    ------------------------------------------------------------
    EXEC('
    CREATE TABLE csc.Consorcio(
        consorcioID INT IDENTITY(1,1),
        nombre VARCHAR(100) NOT NULL,
        direccion VARCHAR(100) NOT NULL,
        superficieM2Total DECIMAL(6,2) NOT NULL,
        CONSTRAINT PK_ConsorcioID PRIMARY KEY (consorcioID)
    );');

    ------------------------------------------------------------
    -- Tabla: Unidad_Funcional
    ------------------------------------------------------------
    EXEC('
    CREATE TABLE csc.Unidad_Funcional(
        unidadFuncionalID INT IDENTITY(1,1),
        consorcioID INT NOT NULL,
        piso CHAR(2) NOT NULL,
        departamento CHAR(1) NOT NULL,
        superficieM2 DECIMAL(6,2) NOT NULL,
        cochera TINYINT NULL,
        baulera TINYINT NULL,
        CBU_CVU CHAR(22) NULL, 
        coeficiente DECIMAL(4,2) NOT NULL,
        CONSTRAINT PK_UnidadFuncionalID PRIMARY KEY (unidadFuncionalID),
        CONSTRAINT FK_UF_Consorcio FOREIGN KEY (consorcioID)
            REFERENCES csc.Consorcio(consorcioID)
    );');

    ------------------------------------------------------------
    -- Tabla: Propietario
    ------------------------------------------------------------
    EXEC('
    CREATE TABLE csc.Propietario(
        IDPropietario INT IDENTITY(1,1) PRIMARY KEY,
        DNI CHAR(8) NOT NULL,
        unidadFuncionalID INT NULL,
        nombre VARCHAR(100) NOT NULL, 
        apellido VARCHAR(100) NOT NULL,
        mail VARCHAR(200) NULL,
        telefono VARCHAR(20) NULL,
        modoEntrega VARCHAR(8) NOT NULL,
        CBU_CVU CHAR(22) NULL, 
        CONSTRAINT FK_Propietario_UF FOREIGN KEY (unidadFuncionalID)
            REFERENCES csc.Unidad_Funcional(unidadFuncionalID),
        CONSTRAINT Propietario_ModoEntrega CHECK (ModoEntrega IN (''Mail'', ''Whatsapp'', ''Fisico'')),
        CONSTRAINT Propietario_DNINumerico CHECK (DNI NOT LIKE ''%[^0-9]%'')
    );');

    ------------------------------------------------------------
    -- Tabla: Inquilino
    ------------------------------------------------------------
    EXEC('
    CREATE TABLE csc.Inquilino(
        DNI CHAR(8) NOT NULL,
        unidadFuncionalID INT NOT NULL,
        nombre VARCHAR(100) NOT NULL, 
        apellido VARCHAR(100) NOT NULL,
        mail VARCHAR(100) NULL,
        telefono VARCHAR(20) NULL,
        CBU_CVU CHAR(22) NULL, 
        CONSTRAINT PK_InquilinoID PRIMARY KEY (DNI, unidadFuncionalID),
        CONSTRAINT FK_Inquilino_UF FOREIGN KEY (unidadFuncionalID)
            REFERENCES csc.Unidad_Funcional(unidadFuncionalID),
        CONSTRAINT Inquilino_DNINumerico CHECK (DNI NOT LIKE ''%[^0-9]%'')
    );');

    ------------------------------------------------------------
    -- Tabla: Expensas
    ------------------------------------------------------------
    EXEC('
    CREATE TABLE csc.Expensas(
        documentoID INT IDENTITY(1,1),
        consorcioID INT NOT NULL,
        mes TINYINT NOT NULL CHECK (mes BETWEEN 1 AND 12),
        anio INT NOT NULL,
        fechaGenerado DATE NOT NULL,
        fechaEnvio DATE NOT NULL,
        medioEnvio CHAR(10) NOT NULL,
        aPropietario BIT NOT NULL,
        aInquilino BIT NOT NULL,
        CONSTRAINT PK_Expensas PRIMARY KEY (documentoID),
        CONSTRAINT FK_Expensas_Consorcio FOREIGN KEY (consorcioID)
            REFERENCES csc.Consorcio(consorcioID),
        CONSTRAINT Expensas_ModoEnvio CHECK (medioEnvio IN (''Mail'', ''Whatsapp'', ''Fisico''))
    );');

    ------------------------------------------------------------
    -- Tabla: Estado_Financiero
    ------------------------------------------------------------
    EXEC('
    CREATE TABLE csc.Estado_Financiero(
        estadoFinancieroID INT IDENTITY(1,1),
        documentoID INT NOT NULL, 
        saldoAnterior DECIMAL(14,2) NULL,
        ingresosEnTermino DECIMAL(14,2) NULL,
        ingresosAdeudados DECIMAL(14,2) NULL,
        egresosTotales DECIMAL(14,2) NULL,
        saldoFinal DECIMAL(14,2) NULL,
        CONSTRAINT PK_EstadoFinanciero PRIMARY KEY (estadoFinancieroID),
        CONSTRAINT FK_EstadoFin_Expensas FOREIGN KEY (documentoID)
            REFERENCES csc.Expensas(documentoID)
    );');

    ------------------------------------------------------------
    -- Tabla: Estado_Cuentas
    ------------------------------------------------------------
    EXEC('
    CREATE TABLE csc.Estado_Cuentas(
        estadoCuentasID INT IDENTITY(1,1),
        documentoID INT NOT NULL, 
        unidadFuncionalID INT NOT NULL,
        saldoAnterior DECIMAL(14,2) NULL,
        pagosRecibidos DECIMAL(14,2) NULL,
        deuda DECIMAL(14,2) NULL,
        InteresesPorMora DECIMAL(14,2) NULL,
        expensasOrdinarias DECIMAL(14,2) NULL,
        expensasExtraordinarias DECIMAL(14,2) NULL,
        totalPagar DECIMAL(14,2) NULL,
        CONSTRAINT PK_EstadoCuentas PRIMARY KEY (estadoCuentasID),
        CONSTRAINT FK_EstadoCuentas_Expensas FOREIGN KEY (documentoID)
            REFERENCES csc.Expensas(documentoID),
        CONSTRAINT FK_EstadoCuentas_UF FOREIGN KEY (unidadFuncionalID)
            REFERENCES csc.Unidad_Funcional(unidadFuncionalID)
    );');

    ------------------------------------------------------------
    -- Tabla: Gasto_Extraordinario
    ------------------------------------------------------------
    EXEC('
    CREATE TABLE csc.Gasto_Extraordinario(
        gastoExtraordinarioID INT IDENTITY(1,1) NOT NULL, 
        documentoID INT NULL, 
        consorcioID INT NULL,
        razonSocial VARCHAR(200) NOT NULL,
        fecha DATE NOT NULL,
        importeTotal DECIMAL(14,2) NOT NULL,
        formaPago VARCHAR(6) NOT NULL, 
        CONSTRAINT FK_GastoExtrao_Consorcio FOREIGN KEY (consorcioID) REFERENCES csc.Consorcio(consorcioID),
        CONSTRAINT PK_GastoExtraordinario PRIMARY KEY (gastoExtraordinarioID),
        CONSTRAINT FK_GastoExtrao_Expensas FOREIGN KEY (documentoID)
            REFERENCES csc.Expensas(documentoID),
        CONSTRAINT CHK_FormaPago CHECK (formaPago IN (''TOTAL'',''CUOTAS''))
    );');

    ------------------------------------------------------------
    -- Tabla: Cuota_Gasto
    ------------------------------------------------------------
    EXEC('
    CREATE TABLE csc.Cuota_Gasto(
        cuotaID INT IDENTITY(1,1),
        gastoExtraordinarioID INT NOT NULL,
        nroCuota CHAR(4) NOT NULL, 
        totalCuota DECIMAL(14,2) NOT NULL,
        importeCuota DECIMAL(8,2) NOT NULL,
        CONSTRAINT PK_CuotaGasto PRIMARY KEY (cuotaID),
        CONSTRAINT FK_cuotaGasto_GastoExtra FOREIGN KEY (gastoExtraordinarioID)
            REFERENCES csc.Gasto_Extraordinario(gastoExtraordinarioID)
    );');

    ------------------------------------------------------------
    -- Tabla: Gasto_Ordinario
    ------------------------------------------------------------
    EXEC('
    CREATE TABLE csc.Gasto_Ordinario(
        gastoOrdinarioID INT IDENTITY(1,1),
        documentoID INT NULL,
        consorcioID INT NOT NULL,
		fecha date NOT NULL,
        importeTotal DECIMAL(14,2) NOT NULL,
        CONSTRAINT PK_GastoOrdinario PRIMARY KEY (gastoOrdinarioID),
        CONSTRAINT FK_GastoOrdinario_Expensas FOREIGN KEY (documentoID)
            REFERENCES csc.Expensas(documentoID),
		CONSTRAINT FK_GastoOrd_Consorcio FOREIGN KEY (consorcioID)
        REFERENCES csc.Consorcio(consorcioID)
    );');

    ------------------------------------------------------------
    -- Tabla: Gasto_General
    ------------------------------------------------------------
    EXEC('
    CREATE TABLE csc.Gasto_General(
        gastoGeneralID INT IDENTITY(1,1),
        gastoOrdinarioID INT NOT NULL, 
        tipo VARCHAR(27) NOT NULL, 
        empresaoPersona BIT NULL, 
        nroFactura VARCHAR(20) NULL, 
        importe DECIMAL(8,2) NOT NULL,
        CONSTRAINT PK_GastoGeneral PRIMARY KEY (gastoGeneralID),
        CONSTRAINT FK_GastoGral_GastoOrd FOREIGN KEY (gastoOrdinarioID)
            REFERENCES csc.Gasto_Ordinario(gastoOrdinarioID),
        CONSTRAINT CHK_TipoGastoG CHECK (tipo IN (
            ''BANCARIOS'', ''ADMINISTRACION'', ''SEGUROS'', ''GASTOS GENERALES''))
    );');

    ------------------------------------------------------------
    -- Tabla: Servicio_Publico
    ------------------------------------------------------------
    EXEC('
    CREATE TABLE csc.Servicio_Publico(
        servicioPublicoID INT IDENTITY(1,1),
        gastoOrdinarioID INT NOT NULL,
        tipo VARCHAR(27) NOT NULL, 
        Empresa VARCHAR(100) NULL, 
        nroFactura CHAR(13) NULL, 
        importe DECIMAL(8,2) NOT NULL,
        CONSTRAINT PK_ServicioPublico PRIMARY KEY (servicioPublicoID),
        CONSTRAINT Servicio_P_Tipo CHECK (tipo IN (
            ''SERVICIOS PUBLICOS-Agua'', ''SERVICIOS PUBLICOS-Luz'', ''SERVICIOS PUBLICOS-Internet'')),
        CONSTRAINT FK_ServicioPubl_GastoOrd FOREIGN KEY (gastoOrdinarioID)
            REFERENCES csc.Gasto_Ordinario(gastoOrdinarioID)
    );');

    ------------------------------------------------------------
    -- Tabla: Servicio_Limpieza
    ------------------------------------------------------------
    EXEC('
    CREATE TABLE csc.Servicio_Limpieza(
        servicioLimpiezaID INT IDENTITY(1,1),
        gastoOrdinarioID INT NOT NULL,
        modalidad VARCHAR(7), 
        nombre VARCHAR(100) NULL,
        importe DECIMAL(8,2) NOT NULL,
        nroFactura VARCHAR(20) NULL, 
        CONSTRAINT Servicio_L_Modalidad CHECK (modalidad IN (''PERSONA'', ''EMPRESA'')),
        CONSTRAINT PK_ServicioLimpieza PRIMARY KEY (servicioLimpiezaID),
        CONSTRAINT FK_ServicioLimp_GastoOrd FOREIGN KEY (gastoOrdinarioID)
            REFERENCES csc.Gasto_Ordinario(gastoOrdinarioID)
    );');

    ------------------------------------------------------------
    -- Tabla: Pago
    ------------------------------------------------------------
    EXEC('
    CREATE TABLE csc.Pago(
        pagoID INT IDENTITY(1,1),
        unidadFuncionalID INT NULL,
        cuentaOrigen CHAR(22) NULL,
        monto DECIMAL(8,2) NOT NULL,
        asociado BIT NOT NULL DEFAULT 0,
        CONSTRAINT PK_Pago PRIMARY KEY (pagoID),
        CONSTRAINT FK_Pago_UF FOREIGN KEY (unidadFuncionalID)
            REFERENCES csc.Unidad_Funcional(unidadFuncionalID)
    );');

    ------------------------------------------------------------
    -- Tabla: CSV_Importado
    ------------------------------------------------------------
    EXEC('
    CREATE TABLE csc.CSV_Importado(
        importacionID INT IDENTITY(1,1),
        fechaImportacion DATE NOT NULL, 
        nombreArchivo VARCHAR(400) NOT NULL,
        fechaCSV DATE NOT NULL,
        CONSTRAINT PK_CSVImportado PRIMARY KEY (importacionID)
    );');

    ------------------------------------------------------------
    -- Tabla: Detalle_CSV
    ------------------------------------------------------------
    EXEC('
    CREATE TABLE csc.Detalle_CSV(
        detallesID INT IDENTITY(1,1),
        pagoID INT NOT NULL, 
        importacionID INT NOT NULL,
        fechaPago DATE NOT NULL,
        cuentaOrigen CHAR(22) NULL, 
        importe DECIMAL(8,2) NOT NULL,
        CONSTRAINT PK_DetalleCSV PRIMARY KEY (detallesID),
        CONSTRAINT FK_DetalleCSV_Pago FOREIGN KEY (pagoID)
            REFERENCES csc.Pago(pagoID),
        CONSTRAINT FK_DetalleCSV_Importacion FOREIGN KEY (importacionID)
            REFERENCES csc.CSV_Importado(importacionID)
    );');

    PRINT 'Estructura del esquema CSC creada correctamente.'
END;
GO

--exec p_Crear_Estructura_CSC


