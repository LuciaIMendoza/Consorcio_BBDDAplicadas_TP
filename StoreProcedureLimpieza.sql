CREATE OR ALTER PROCEDURE p_Limpiar_Estructura_CSC
    @SchemaName NVARCHAR(128) = 'csc'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX) = N'';

    -- Eliminar todas las FOREIGN KEYS del schema
    SELECT @sql = @sql + 'ALTER TABLE [' + s.name + '].[' + t.name + '] DROP CONSTRAINT [' + fk.name + '];' + CHAR(13)
    FROM sys.foreign_keys fk
    INNER JOIN sys.tables t ON fk.parent_object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = @SchemaName;

    EXEC sp_executesql @sql;
    SET @sql = N'';

    --Eliminar CHECK y DEFAULT constraints
    SELECT @sql = @sql + 'ALTER TABLE [' + s.name + '].[' + t.name + '] DROP CONSTRAINT [' + c.name + '];' + CHAR(13)
    FROM sys.check_constraints c
    INNER JOIN sys.tables t ON c.parent_object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = @SchemaName;

    SELECT @sql = @sql + 'ALTER TABLE [' + s.name + '].[' + t.name + '] DROP CONSTRAINT [' + d.name + '];' + CHAR(13)
    FROM sys.default_constraints d
    INNER JOIN sys.tables t ON d.parent_object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = @SchemaName;

    EXEC sp_executesql @sql;
    SET @sql = N'';

    --Eliminar todas las tablas del schema
    SELECT @sql = @sql + 'DROP TABLE [' + s.name + '].[' + t.name + '];' + CHAR(13)
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = @SchemaName;

    EXEC sp_executesql @sql;
    SET @sql = N'';

    -- Eliminar el schema
    SET @sql = 'DROP SCHEMA [' + @SchemaName + '];';
    EXEC sp_executesql @sql;

    PRINT 'Limpieza completada correctamente.';
END;
GO