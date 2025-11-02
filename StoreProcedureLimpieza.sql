USE AltosSaintJust
GO

CREATE OR ALTER PROCEDURE p_Limpiar_Estructura_CSC
    @SchemaName NVARCHAR(128) = 'csc'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX) = N'';

    -------------------------------------------------------------------
    -- 1️⃣ Eliminar todas las FOREIGN KEYS del schema
    -------------------------------------------------------------------
    SELECT @sql = @sql + 'ALTER TABLE [' + s.name + '].[' + t.name + '] DROP CONSTRAINT [' + fk.name + '];' + CHAR(13)
    FROM sys.foreign_keys fk
    INNER JOIN sys.tables t ON fk.parent_object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = @SchemaName;

    EXEC sp_executesql @sql;
    SET @sql = N'';

    -------------------------------------------------------------------
    -- 2️⃣ Eliminar CHECK y DEFAULT constraints
    -------------------------------------------------------------------
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

    -------------------------------------------------------------------
    -- 3️⃣ Eliminar todos los triggers de tablas del schema
    -------------------------------------------------------------------
    SELECT @sql = @sql + 'DROP TRIGGER [' + s.name + '].[' + tr.name + '];' + CHAR(13)
    FROM sys.triggers tr
    INNER JOIN sys.tables t ON tr.parent_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = @SchemaName
      AND tr.is_ms_shipped = 0;

    EXEC sp_executesql @sql;
    SET @sql = N'';

    -------------------------------------------------------------------
    -- 4️⃣ Eliminar todas las vistas
    -------------------------------------------------------------------
    SELECT @sql = @sql + 'DROP VIEW [' + s.name + '].[' + v.name + '];' + CHAR(13)
    FROM sys.views v
    INNER JOIN sys.schemas s ON v.schema_id = s.schema_id
    WHERE s.name = @SchemaName;

    EXEC sp_executesql @sql;
    SET @sql = N'';

    -------------------------------------------------------------------
    -- 5️⃣ Eliminar todos los procedimientos almacenados
    -------------------------------------------------------------------
    SELECT @sql = @sql + 'DROP PROCEDURE [' + s.name + '].[' + p.name + '];' + CHAR(13)
    FROM sys.procedures p
    INNER JOIN sys.schemas s ON p.schema_id = s.schema_id
    WHERE s.name = @SchemaName;

    EXEC sp_executesql @sql;
    SET @sql = N'';

    -------------------------------------------------------------------
    -- 6️⃣ Eliminar todas las funciones (scalar, table-valued, aggregate)
    -------------------------------------------------------------------
    SELECT @sql = @sql + 'DROP FUNCTION [' + s.name + '].[' + f.name + '];' + CHAR(13)
    FROM sys.objects f
    INNER JOIN sys.schemas s ON f.schema_id = s.schema_id
    WHERE s.name = @SchemaName
      AND f.type IN ('FN','IF','TF','AF'); -- scalar, inline TVF, table-valued, aggregate

    EXEC sp_executesql @sql;
    SET @sql = N'';

    -------------------------------------------------------------------
    -- 7️⃣ Eliminar todas las tablas del schema
    -------------------------------------------------------------------
    SELECT @sql = @sql + 'DROP TABLE [' + s.name + '].[' + t.name + '];' + CHAR(13)
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = @SchemaName;

    EXEC sp_executesql @sql;
    SET @sql = N'';

    -------------------------------------------------------------------
    -- 8️⃣ Eliminar el schema
    -------------------------------------------------------------------
    SET @sql = 'DROP SCHEMA [' + @SchemaName + '];';
    EXEC sp_executesql @sql;

    PRINT 'Limpieza completa del schema finalizada correctamente.';
END;
GO



--exec p_Limpiar_Estructura_CSC;
