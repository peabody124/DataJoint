function tableNames = getReferencedTables( R )
% getParentTables( R ) - get the class names for the tables referred to by
% foreign keys of R
% :: Dimitri Yatsenko :: Created 2010-08-21 :: Modified 2010-11-11 ::


sql = ['select distinct referenced_table_name ' ...
       'from information_schema.key_column_usage ' ...
       'where constraint_name like "ref%%" and referenced_table_schema="%s" and table_name="%s"'];
ret = query( R, sprintf(sql,R.conn.schema,R.conn.table) );

% convert table names to class names, e.g. '$ephys_pinouts'-->EphysPinouts
tableNames=regexprep(ret.referenced_table_name,'(^|\W|_)+([a-zA-Z]?)','${upper($2)}');