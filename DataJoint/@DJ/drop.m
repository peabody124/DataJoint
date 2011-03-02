function drop( dj )
% DJ/drop - removes the table from the database but does not erase
% its class. The table must be empty and not referenced by other tables.
%
% :: Dimitri Yatsenko :: Created 2011-01-06 :: Modified 2011-01-06 ::

assert( isempty(dj), 'The table must be empty before it can be dropped' );
ref = getReferencingTables(dj);
if ~isempty(ref)
	error( 'The table cannot be dropped because it''s referenced by %s', ref{1} );
end
children = getChildTables(dj);
if ~isempty(children)
    error('The table cannot be dropped because it''s referenced by %s',children{1});
end
query( dj, sprintf( 'DROP TABLE `%s`.`%s`', dj.conn.schema, dj.conn.table) );
fprintf('Dropped table `%s`.`%s`\n', dj.conn.schema, dj.conn.table );