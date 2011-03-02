function ddj = setPopulateRelation( ddj, R )
% ddj = setPopulateRelation( ddj, R ) - set the relation R to be used as the
% source of primary keys to populate the relation declared by ddj. 
% R may be specified as relation or a character string that defines the
% relation. 
%
% Example: 
%   ddj = setPopulateRelation( ddj, Scans('lens>10') );  
% the table declared for ddj will be populated for each tuple in Scans
% whose field lens is greater than 10.
% 
% :: Dimitri Yatsenko :: Created 2011-02-11 :: Modified 2011-03-01 ::

assert( ismember(ddj.tableType,{'computed','imported'})...
    , 'A manual table cannot have a populate relation' );
if ischar(R)
    R = eval(R);
end
assert(isa(R,'DJ'),'The populate relation be a DJ object');
ddj.populateRelation = getSelfExpression(R);  % always a string