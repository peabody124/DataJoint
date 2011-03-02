function display( dj, opt1 )
% display(dj) - displays information about the relation dj.
% This call is equivallent to omitting the semicolon trailing dj:
% >> dj
%
% display(dj,'full') - include additional information e.g. related tables
%
% :: Dimitri Yatsenko :: Created 2009-10-09 :: Modified 2011-03-01 ::

full = nargin>=2 && (strcmpi(opt1,'full') || strcmp(opt1,'-full'));

if isempty( dj.conn.table )
    if  isempty(dj.conn.schema)
        disp('Empty DJ object');
    else
        fprintf('Schema %s\n', dj.conn.schema );
    end
else
    if ~isBase(dj)
        fprintf('\nDerived relation: %s', dj.selfExpression ); 
    else
        % load table comment
        tableComment = query(dj ...
            , sprintf('select table_comment from information_schema.tables where table_schema="%s" and table_name="%s"'...
            , dj.conn.schema, dj.conn.table));
        tableComment = tableComment.table_comment{1};

        % class name and comment
        tableComment = tableComment(1:find(tableComment=='$',1,'last')-1);
        t = struct('m', 'manual', 'l', 'lookup', 'i', 'imported', 'c', 'computed' );
        fprintf( '\n@%s - a %s table   "%s"', class(dj), t.(dj.tableType), tableComment );

        if full
            % list related tables
            parentTables = getParentTables( dj );
            if ~isempty( parentTables )
                s = sprintf( ', @%s', parentTables{:} );
                fprintf('\n     PARENT TABLES: %s', s(3:end));
            end

            referencedTables = setdiff( getReferencedTables( dj ), parentTables );
            if ~isempty( referencedTables )
                s = sprintf( ', @%s', referencedTables{:} );
                fprintf('\n REFERENCED TABLES: %s', s(3:end));
            end

            childTables = getChildTables( dj );
            if ~isempty( childTables )
                s = sprintf(', @%s', childTables{:} );
                fprintf('\n      CHILD TABLES: %s', s(3:end));
            end

            referencingTables = setdiff( getReferencingTables( dj ), childTables );
            if ~isempty( referencingTables )
                s = sprintf(', @%s', referencingTables{:} );
                fprintf('\nREFERENCING TABLES: %s', s(3:end));
            end
        end

        if ~isempty(dj.populateRelation)
            fprintf('\n    POPULATED FROM: %s', dj.populateRelation );
        end
    end
    fprintf( '\n             - ATTRIBUTES -\n' );
    for i=1:length(dj.fields)
        aster = '';
        comment = dj.fields(i).comment;
        if dj.fields(i).isKey;
            aster = '*';
        end
        fprintf( '%20s :: %18s :: %s\n', [aster dj.fields(i).name], dj.fields(i).type(1:min(end,18)),  dj.fields(i).comment );
    end

    % print the total number of tuples
    fprintf('\n%d tuples\n\n', length(dj) );
end