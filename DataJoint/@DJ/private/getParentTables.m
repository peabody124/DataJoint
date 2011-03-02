function tableNames = getParentTables( dj )
% getParentTables( dj ) - get the class names of parent tables. 
% A parent table is one referred to by a foreign key of dj and all of its
% primary key fields are in dj's primary key.
% :: Dimitri Yatsenko :: Created 2010-08-21 :: Modified 2011-02-15 ::

% retrieve tables that are referred to by primary key fields of dj.
sql = [ ...
    'SELECT DISTINCT referenced_table_name ' ...
    'FROM information_schema.key_column_usage ' ...
    'WHERE constraint_name not like "ref%%" and table_schema="%s" and referenced_table_schema="%s" and table_name="%s"'];

sql = sprintf( sql, dj.conn.schema, dj.conn.schema, dj.conn.table );
ret = query( dj, sql );

% convert table names to class names, e.g. '$ephys_pinouts'-->EphysPinouts
tableNames=regexprep(ret.referenced_table_name,'(^|\W|_)+([a-zA-Z]?)','${upper($2)}');