function dj = execute(ddj)
% CreateDJ/execute - executes the declaration of the table and its MATLAB
% class specified by ddj. IF the table or the class already exist,
% their creation is skipped thereby making repeated executions safe.
% Therefore, one must deliberately remove the existing table and class
% before changes can take effect.
%
% :: Dimitri Yatsenko :: Created 2010-12-28 :: Modified 2011-01-02 ::

assert(~isempty(ddj.parentTables) || ~ismember(ddj.tableType,{'imported','computed'}),...
    'Automatically populated tables must have a parent table');

% create the new class if necessary
if ~isempty(which(ddj.className))
    fprintf('Found class constructor %s\n', which(ddj.className));
    fprintf('Did not generate a new class\n');
elseif strcmpi('yes',input(sprintf('\nCreate class @%s in %s? yes/no >>',ddj.className,pwd),'s'))
    dirName = (['@' ddj.className]);
    mkdir(dirName);
    cd(dirName);

    % create the constructor
    fw = fopen( [ddj.className,'.m'], 'w' );
    fprintf( fw, 'function dj = %s(varargin)\n',ddj.className);
    fprintf( fw, 'dj=class(struct,''%s'',%s(''%s'',varargin{:}));'...
        ,ddj.className,class(ddj.schemaObj),ddj.tableName);
    assert( ischar(ddj.populateRelation) );
    if ~isempty(ddj.populateRelation)
        assert( isa( eval([ddj.populateRelation ';']), 'DJ' ),...
            'The populate relation must evaluate to a DJ object' );
        fprintf(fw, '\ndj=setPopulateRelation(dj,''%s'');',...
            regexprep(ddj.populateRelation,'''',''''''));
    end
    fclose(fw);

    % add methods makeTuples
    if ismember(ddj.tableType,{'imported','computed'})
        % make the makeTuples.m template
        fw = fopen( 'makeTuples.m', 'w' );
        fprintf( fw, 'function makeTuples( this, key )\n' );
        fprintf( fw, 'tuple = key;\n' );
        fprintf( fw, '% fill out remaining attributes' );

        for f=ddj.addKeyFields
            fprintf( fw, 'for <TBD>\n');
            fprintf( fw, 'tuple.%s = <TBD>; %% %s\n', f.name, f.comment );
        end
        for f=ddj.nonKeyFields
            fprintf( fw, 'tuple.%s = <TBD>; %% %s\n', f.name, f.comment );
        end
        fprintf( fw, '\ninsert(this,tuple);\n' );
        fprintf( fw, '% if this table case subtables, invoke their makeTuples(SubTable,tuple) here\n');
        for f=ddj.addKeyFields
            fprintf( fw, 'end\n');
        end
        fclose(fw);
    end

    cd ..
    fprintf('Created class "%s"\n', ddj.className );
end

% check if table already exists
sql = sprintf('SELECT COUNT(*) as n FROM information_schema.tables WHERE table_schema="%s" and table_name="%s"'...
    ,getSchema(ddj.schemaObj),ddj.tableName);
n = query( ddj.schemaObj, sql );
if n.n>0
    fprintf('Table %s already exists, skipping\n',ddj.tableName);
else
    % CREATE TABLE
    sql = getSQL(ddj);
    query(ddj.schemaObj,sql);
    fprintf('Created table "%s"\n', ddj.tableName );
end

% convert ddj into the new DataJoint class
dj = eval( [ddj.className ';']);
end