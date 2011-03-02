function sql = getSQL( this )
% CreateDJ/getSQL - returns the string containing the SQL statement for the
% creation of the declared table.
% :: Dimitri Yatsenko :: Created 2010-12-28 :: Modified 2011-02-15 ::


% Process the primary key of the parent tables
if isempty( this.parentTables )
    keyFields = this.addKeyFields';
else
    for iParent = 1:numel(this.parentTables)
        assert( strcmp( getSchema(this.parentTables{iParent}), getSchema(this.schemaObj)) ...
            , 'Parent tables must be in the same schema' );
        qStr = sprintf('select column_name,column_type,column_comment from information_schema.columns where column_key="PRI" and table_schema="%s" and table_name="%s"'...
            , getSchema(this.parentTables{iParent}), getTable(this.parentTables{iParent}));
        k = query(this.schemaObj,qStr);
        k = structure2array(k);
        assert(numel(k)>0,'empty primary key for table %s',class(this.parentTables{iParent}));
        if iParent==1
            keyFields = k;
        else
            keyFields = [keyFields;k];
        end
    end
    [trash,ix] = unique({keyFields.column_name});
    keyFields = keyFields(sort(ix));
    keyFields = renameField( keyFields, 'column_name',    'name' );
    keyFields = renameField( keyFields, 'column_type',    'type' );
    keyFields = renameField( keyFields, 'column_comment', 'comment' );
    [keyFields.default] = deal(nan);
    keyFields = [keyFields; this.addKeyFields'];
end
assert( ~isempty(keyFields), 'Primary key is not specified' );
fields = [keyFields;this.nonKeyFields'];


% process referenced fields
for iRef=1:numel(this.references)
    assert( strcmp( getSchema(this.references{iRef}), getSchema(this.schemaObj)) ...
        , 'Parent tables must be in the same schema' );
    qStr = sprintf('select column_name,column_type,column_comment from information_schema.columns where column_key="PRI" and table_schema="%s" and table_name="%s"'...
        , getSchema(this.schemaObj), getTable(this.references{iRef}));
    k = query(this.schemaObj,qStr);
    k = structure2array(k);
    assert(numel(k)>0,'empty primary key for table %s',class(this.references{iRef}));

    for iField=1:numel(k)
        if ~ismember( k(iField).column_name, {fields.name} )
            default = nan;
            if isfield( this.refDefaults{iRef}, k(iField).column_name )
                default = this.refDefaults{iRef}.(k(iField).column_name);
            end
            fields(end+1) = struct(...
                'name', k(iField).column_name, ...
                'type', k(iField).column_type, ...
                'comment', k(iField).column_comment, ...
                'default', default );
        end
    end
end


% make CREATE TABLE SQL statement
sql = sprintf('CREATE TABLE `%s`.`%s` (', getSchema( this.schemaObj ), this.tableName );

% add required field declarations
for i=1:numel(fields)
    v = fields(i).default;

    % specify default value
    switch true
        case isnumeric(v) && ~isempty(v) && isnan(v)
            defaultValue = 'NOT NULL';
        case (isnumeric(v) || iscell(v)) && isempty(v)
            defaultValue = 'DEFAULT NULL';
        case ischar(v)
            defaultValue = sprintf('NOT NULL DEFAULT "%s" ',v);
        case isnumeric(v) && numel(v)==1
            defaultValue = sprintf('NOT NULL DEFAULT "%1.16g"',v);
        otherwise
            error('invalid default value for field ''%s''', fields(i).name);
    end

    sql = sprintf('%s\n   `%s` %s %s COMMENT "%s",', sql, fields(i).name, char(fields(i).type), defaultValue, fields(i).comment);
end

% add an automatic timestamp
if this.addTimestamp
    sql = sprintf('%s\n    `%s_ts` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP COMMENT "automatic timestamp. Do not edit",',sql,lower(this.className));
end

% add PRIMARY KEY declaration
pkeyStr = sprintf(',`%s`',keyFields.name);
sql = sprintf( '%s\n    PRIMARY KEY(%s),',sql,pkeyStr(2:end));

% add FOREIGN KEY declarations
indices{1} = {keyFields.name}';
name = this.tableName;
name = name( ismember(name, ['a':'z' '0':'9' '_']) );
if strcmp(this.tableType,'computed') || (strcmp(this.tableType,'imported') && isempty(this.populateRelation))
    propagate = 'ON UPDATE CASCADE ON DELETE CASCADE';  % only computed tables and imported grouped tables may be deleted in cascade
else
    propagate = 'ON UPDATE CASCADE ON DELETE RESTRICT';
end
[sql, indices] = addForeignKeyDeclarations( sql, this.parentTables, indices, ['par_' name], propagate );
[sql, indices] = addForeignKeyDeclarations( sql, this.references  , indices, ['ref_' name], 'ON UPDATE CASCADE ON DELETE RESTRICT' );

% close the CREATE TABLE statement
sql = sql(1:end-1);  % take off the trailing comma
sql = sprintf( '%s\n) ENGINE=InnoDB', sql);

end





function [sql, indices] = addForeignKeyDeclarations( sql, referencedTables, indices, prefix, propagate )
% add declarations of foreign keys referring to the referenced tables.
% Also add any necessary indices as required by InnoDB.

for iRef = 1:numel(referencedTables)
    referencedFields = getPrimaryKey(referencedTables{iRef});
    pkeyStr = sprintf(',`%s`',referencedFields{:});
    pkeyStr = pkeyStr(2:end);

    % add index if necessary. From MySQL manual:
    % "In the referencing table, there must be an index where the foreign
    % key columns are listed as the first columns in the same order."
    needIndex = true;
    for iIndex = 1:numel(indices)
        if isequal(referencedFields,indices{iIndex}(1:min(end,numel(referencedFields))))
            needIndex = false;
            break;
        end
    end
    if needIndex
        sql = sprintf('%s\n    INDEX (%s),', sql, pkeyStr);
        indices{end+1} = {referencedFields};
    end
 
    sql = sprintf( '%s\n    CONSTRAINT %s_djfk_%d FOREIGN KEY (%s) REFERENCES `%s`.`%s` (%s) %s,'...
        ,sql,prefix,iRef,pkeyStr,getSchema(referencedTables{iRef}),getTable(referencedTables{iRef}),pkeyStr,propagate);
end
end