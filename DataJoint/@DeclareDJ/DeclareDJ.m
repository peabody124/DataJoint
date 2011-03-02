function this = DeclareDJ( schemaObj, className, tableType )
% ddj = DeclareDJ( schemaObj, className, tableType )  - creates the
% declaration object for a DataJoint table and its accompanying matlab class.
%
% Once a DeclareDJ object ddj is created, you may add attributes to the
% object using DeclareDJ methods.  Once the declaration is complete, it is
% executed by calling dj = execute( ddj ).  See DeclareDJ/execute.
% 
% TEMPLATE (for most common use case):
% ddj = DeclareDJ(<SchemaClass>,'<table_name>','lookup|manual|imported|computed' );
% ddj = addParent( ddj, <ParentTable> );
% ddj = addKeyField( ddj, '<key_field>', '<datatype>', '<field comment>' );
% ddj = addField( ddj,'<field>','<datatype>','<field comment>');
% ddj = addField( ddj,'<field>','<datatype>','<field comment>',defaultValue);
% ddj = addField( ddj,'<field>','<datatype>','<field comment>',{});  %optional field
%
% dj = execute( ddj );
% setTableComment( dj, '<table comment>');
%
% :: Dimitri Yatsenko :: Created 2010-12-29 :: Modified 2011-02-28 ::

% default constructor
this.schemaObj = DJ;
this.parentTables = {};
this.tableName = '';
this.className = '';
this.addKeyFields   = struct('name',{},'type',{},'comment',{},'default',{});
this.nonKeyFields   = struct('name',{},'type',{},'comment',{},'default',{});
this.references = {};
this.refDefaults = {};
this.addTimestamp = true;
this.populateRelation = '';  % the string expressing the populate relation
this.tableType = '';
this = class( this, 'DeclareDJ' );

if nargin>=1
    assert( ismember( className(1), 'A':'Z' ), 'class name must begin with a capital letter' );
    assert( all(ismember( className, ['A':'Z' 'a':'z' '0':'9'] )), 'class name must consist of letters and digits' );
    assert( isa(schemaObj,'DJ'), 'the schema object must be a DJ object' );
    this.className = className;
    this.schemaObj = schemaObj;
    this.tableType = tableType;

    % modify the table name according to the table type
    tableName = regexprep(className,'([A-Z])','_${lower($1)}');  % convert CamelCase to underscore-delimited 
    tableName = tableName(2:end);
    
    % alter the table name to reflect the table type according to DataJoint conventions
    switch lower(tableType)
        case 'manual'
            % do nothing
        case 'imported'
            tableName = ['_' tableName]; % imported tables are prefixed with a single underscore
        case 'computed'
            tableName = ['__' tableName];  % computed tables are prefixed with a double udnerscore
        case 'lookup'
            tableName = ['#' tableName]; % lookup tables are prefixed with a #
        otherwise
            error('invalid data type. Must be lookup, manual, imported, or computed');
    end
        
    this.tableName = tableName;
end