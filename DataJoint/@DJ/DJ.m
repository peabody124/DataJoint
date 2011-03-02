function dj = DJ( conn, varargin )
% Constructor dj = DJ( conn, varargin )
% Create the base relation dj. Read DataJoint.pdf for a more complete review.
%
% INPUTS:
%   'conn' must be a structure providing connection information in the
%   fields 'host','schema','user','pass', and 'table'
%   The remaining parameters specify relational restriction and are passed
%   to DJ/restrict.
%
%  :: Dimitri Yatsenko :: Created 2009-09-28 :: Modified 2011-02-13 ::

dj.conn = struct('host','','schema','','user','','pass','','table','','schemaClass','');
dj.tableType = 'u';  % initial for: unknown, lookup, manual, imported, computed, or group.
dj.fields = struct('name',{},'type',{},'isKey',{},'isNumeric',{},'isString',{},'isBlob',{},'isNullable',{},'comment',{},'default',{});  % a structure array describing fields
dj.primaryKey = {};      % a column cell array containing primary key names
dj.sqlRes   = '';   % the restriction portion of the sql statement, i.e. "WHERE ..."
dj.sqlPro ='*';     % the projection portion of the sql statement, including renames
dj.sqlSrc  = '';    % the source expression
dj.inPopulate = false;  % true when the current object is within a populate call
dj.populateRelation = '';  % the expression from which populate keys are enumerated
dj.selfExpression = '';  % the MATLAB expression to obtain this relation
dj = class( dj, 'DJ' );

% If connection information is specified, connect to the database and fill
% values
if nargin>0
    assert( ~isempty(conn.host) && ~isempty(conn.schema) && ~isempty(conn.user) && ~isempty(conn.pass) && ~isempty(conn.schemaClass) )
    dj.conn = conn;
    if ~isempty(conn.table)
        
        % determine table type
        switch conn.table(1)
            case '#'
                dj.tableType = 'l'; % lookup
            case '_'
                if conn.table(1)=='_'
                    if conn.table(2)=='_'
                        dj.tableType = 'c';  % computed
                    else
                        dj.tableType = 'i';  % imported
                    end
                end
            otherwise
                dj.tableType = 'm';  % manual
        end

        % load field information
        tableFields = query(dj ...
            , sprintf('select column_name,column_key,column_type,is_nullable,column_comment,column_default from information_schema.columns where table_schema="%s" and table_name="%s"'...
            , dj.conn.schema, dj.conn.table));
        assert(~isempty(tableFields.column_name),'Missing table %s', dj.conn.table );
        dj.fields(1).name = tableFields.column_name;
        dj.fields.type = tableFields.column_type;
        dj.fields.isKey   = strcmpi( tableFields.column_key, 'PRI' );
        dj.primaryKey = tableFields.column_name(find(dj.fields.isKey));
        dj.fields.comment  = tableFields.column_comment;
        dj.fields.default  = tableFields.column_default;
        dj.fields.isNumeric = false(size(dj.fields.name));
        dj.fields.isString = false(size(dj.fields.name));
        dj.fields.isBlob   = false(size(dj.fields.name));
        dj.fields.isNullable = strcmpi( tableFields.is_nullable, 'YES' );
        dj.fields = structure2array( dj.fields );

        % classify attribute types
        for i=1:length(dj.fields)
            dj.fields(i).type = regexprep(char(dj.fields(i).type'),'((tiny|long|small|)int)\(\d+\)','$1'); %strip the field length off integer types
            category = regexp( dj.fields(i).type,...
                {'^((tiny|small|medium|big)?int|decimal|double|float)'...  1=numeric
                ,'^((var)?char|enum|date|timestamp)'...                    2=string
                ,'^(tiny|medium|long)?blob'});  %                          3=blob
            category = find(~cellfun(@isempty, category));
            assert( ~isempty(category), 'Datatype "%s" in field `%s` is not supported by DataJoint', dj.fields(i).type,dj.fields(i).name );
            switch category
                case 1
                    dj.fields(i).isNumeric=true;
                    dj.fields(i).default = str2num(char(dj.fields(i).default')); % undo quirks of mym/MySQL
                case 2
                    dj.fields(i).isString=true;
                    dj.fields(i).default = char(dj.fields(i).default');   % undo quirks of mym/MySQL
                case 3
                    dj.fields(i).isBlob=true;
            end
        end

        % form the base relation query and restrict by the inputs
        dj.sqlSrc = sprintf('`%s`.`%s`',dj.conn.schema,dj.conn.table);
        dj.selfExpression = regexprep(dj.conn.table,'(^|\W|_)+([a-zA-Z]?)','${upper($2)}');
        if nargin >= 2;
            dj = restrict( dj, varargin{:} );
        end
    end
end