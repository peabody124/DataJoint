function str = getDeclaration( dj )
% str = getDeclaration( dj ) - reverse engineer table dj to produce a script that
% created the table and its class.
%
% See also DJ/exportSchema
%
% :: Dimitri Yatsenko :: Created 2011-02-08 :: Modified 2011-03-14 ::

assert( isBase(dj), 'only base relations have DeclareDJ declarations' );

% instantiate DeclareDJ
t = struct('m', 'manual', 'l', 'lookup', 'i', 'imported', 'c', 'computed' );
str = sprintf('%%%% %s\nddj=DeclareDJ(%s,''%s'',''%s'');\n',...
    class(dj), dj.conn.schemaClass, class(dj), t.(dj.tableType) );

% add parent declarations
addKeys = dj.primaryKey';
parentTables = getParentTables(dj);
if ~isempty(parentTables)
    str = sprintf('%sddj=addParent(ddj,', str);
    for parent = parentTables'
        assert( ~isempty( which(parent{1}) ), 'class definition for %s not found', parent{1} );
        obj = eval( parent{1} );
        str = sprintf('%s%s,',str,class(obj));
        addKeys = setdiff( addKeys, obj.primaryKey );
    end
    str = sprintf('%s);\n',str(1:end-1));
end

% add primary key fields
if ~isempty( addKeys )
    for key = addKeys
        iField = find( strcmp( key{1}, {dj.fields.name} ) );
        % add default value if any
        default = dj.fields(iField).default;
        defaultStr = '';
        if ischar(default) && dj.fields(iField).isString
            defaultStr = sprintf( ',''%s''',default);
        elseif dj.fields(iField).isNumeric && ~isempty(default)
            defaultStr = sprintf(',%g',default);
        end
        str = sprintf('%sddj=addKeyField(ddj,''%s'',''%s'',''%s''%s);\n', str,...
            dj.fields(iField).name,...
            regexprep(dj.fields(iField).type,'''','"'),...
            regexprep(dj.fields(iField).comment,'''',''''''),defaultStr);
    end
end

% set populate relation
if ischar(dj.populateRelation) && ~isempty(dj.populateRelation)
    str = sprintf('%sddj=setPopulateRelation(ddj,%s);\n', str, dj.populateRelation );
elseif isa(dj.populateRelation,'DJ')
    str = sprintf('%sddj=setPopulateRelation(ddj,%s);\n', str, char(dj.populateRelation));
end
str = sprintf('%s\n',str);

% add references
addFields = {dj.fields(~[dj.fields.isKey]).name};
for ref = getReferencedTables( dj )'
    assert( ~isempty( which(ref{1}) ), 'class definition for %s not found', ref{1} );
    obj = eval( ref{1} );
    str = sprintf('%sddj=addReference(ddj,%s);\n', str, ref{1} );
    addFields = addFields(~ismember(addFields,obj.primaryKey));
end

% add the remaining fields that are not automatic timestamps
omitTimestamp = true;
for field = addFields
    iField = find( strcmp( field{1}, {dj.fields.name} ) );
    name = dj.fields(iField).name;
    default = dj.fields(iField).default;
    if strncmp(dj.fields(iField).type,'timestamp',9) && strcmp(default,'CURRENT_TIMESTAMP')
        omitTimestamp = false;
    else
        % add default value if any
        defaultStr = '';
        if dj.fields(iField).isNullable
            defaultStr = ',[]';
        else
            if ischar(default) && dj.fields(iField).isString
                defaultStr = sprintf( ',''%s''',default);
            elseif dj.fields(iField).isNumeric && ~isempty(default)
                defaultStr = sprintf(',%g',default);
            end
        end
        str = sprintf('%sddj=addField(ddj,''%s'',''%s'',''%s''%s);\n', str, name, ...
            regexprep(dj.fields(iField).type, '''', '"'), ...
            regexprep(dj.fields(iField).comment, '''', ''''''), defaultStr );
    end
end

% omit timestamp
if omitTimestamp
    str = sprintf('%sddj=omitTimestamp(ddj);\n', str );
end

% execute declaration
str = sprintf( '%s\nexecute(ddj);\n', str );

% add comment
tableComment = query(dj ...
    , sprintf('select table_comment from information_schema.tables where table_schema="%s" and table_name="%s"'...
    , dj.conn.schema, dj.conn.table));
tableComment = tableComment.table_comment{1};
str = sprintf( '%ssetTableComment(%s,''%s'');\n\n', str, class(dj), ...
    regexprep(tableComment(1:find(tableComment=='$',1,'last')-1),'''',''''''));

% add insert statements for lookups
if dj.tableType=='l'
    str = sprintf('%s%s\n',str,getInserts(dj));
end