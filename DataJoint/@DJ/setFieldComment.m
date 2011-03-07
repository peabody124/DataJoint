function setFieldComment( dj, field, comment )
assert( isBase(dj), 'Cannot change field comment of a non-base relation' );

ix = find( strcmp(field,{dj.fields.name}) );
assert( ~isempty(ix), 'field %s not found', field );
comment = regexprep( comment, '"','''' );  % replace double quotes with single quotes
nullStr='';
if ~dj.fields(ix).isNullable
     nullStr = ' NOT NULL';
end
sqlQuery = sprintf('ALTER TABLE `%s`.`%s` MODIFY COLUMN `%s` %s%s COMMENT "%s"',...
    dj.conn.schema, dj.conn.table, field, dj.fields(ix).type, nullStr, comment );
query( dj, sqlQuery );