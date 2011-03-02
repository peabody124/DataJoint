function dj=setPopulateRelation(dj,R)
% dj = setPopulateRelation( dj, R ) - set the relation R to be used as the
% source of primary keys to populate the relation dj. The choice of R
% dictates the granularity of calls to makeTuples( dj, key ). 
% R may specified as a string containing the expression that returns the
% populate relation or the populate relation itself.
%
% setPopulate is only called by the constructor as the last step.
% dj = setPopulateRelation( dj, Stims.*CellOriTuning )
%
% See also DeclareDJ/setPopulateRelation. 
% :: Dimitri Yatsenko :: Created 2011-02-11 :: Modified 2011-03-01 ::

assert( ismember( dj.tableType, 'ci' ), ...
    'Only automatically populated tables should have a populate relation' );
assert(ischar(R) || isa(R,'DJ'));
dj.populateRelation = R;