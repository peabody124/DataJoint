function tableNames = getReferencingTables( dj )
% getReferencingTables( dj ) - get the class names for the tables referred to by
% foreign keys of dj
% :: Dimitri Yatsenko :: Created 2010-08-21 :: Modified 2011-01-09 ::

sql = [...
    'SELECT DISTINCT table_name ' ...
    'FROM information_schema.key_column_usage ' ...
    'WHERE constraint_name like "ref%%" and referenced_table_schema="%s" AND referenced_table_name="%s"'];

ret = query( dj, sprintf(sql,dj.conn.schema,dj.conn.table));

% convert table names to class names, e.g. '$ephys_pinouts'-->EphysPinouts
tableNames=regexprep(ret.table_name,'(^|\W|_)+([a-zA-Z]?)','${upper($2)}');