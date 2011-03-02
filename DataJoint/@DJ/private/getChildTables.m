function tableNames = getChildTables( R )
% getParentTables( R ) - get the class names for the tables referred to by
% foreign keys of R
% :: Dimitri Yatsenko :: Created 2010-08-21 :: Modified 2010-11-11 ::

% retrieve tables that reference to R by a subset of their primary key fields.
% This query is slow.

sql = [...
    'SELECT DISTINCT table_name ' ...
    'FROM information_schema.key_column_usage ' ...
    'WHERE constraint_name not like "ref%%" and referenced_table_schema="%s" and referenced_table_name="%s"'];
sql = sprintf( sql, R.conn.schema, R.conn.table );
ret = query( R, sql );

% convert table names to class names, e.g. '$ephys_pinouts'-->EphysPinouts
tableNames=regexprep(ret.table_name,'(^|\W|_)+([a-zA-Z]?)','${upper($2)}');