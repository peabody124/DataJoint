function this = addKeyField( this, name, type, comment )
% CreateDJ/addKeyField - adds a primary key field to the table declaration.
% Every table must have at least one field in its primary key.
% Tables inherit the primary key fields from their parent tables. With no
% additional fields, the present table can have at most one tuple for every
% combination of tuples in the parent tables (parent relation). Adding
% another field to the primary key enables multiple tuples per parent
% tuple, differentiated from each other by the additional key field.
%
% :: Dimitri Yatsenko :: Created 2010-12-28 :: Modified 2011-01-06 ::

assert( strcmp(name,lower(name)), 'capitalization is not allowed in attribute names: %s', name );
assert( isempty(regexpi(type,'blob|varchar')), 'Type %s is not allowed in the primary key', type );
this.addKeyFields(end+1) = struct('name',name,'type',type,'comment',comment,'default',nan); 