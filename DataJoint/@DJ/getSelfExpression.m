function str=getSelfExpression( dj, parenthesize )
% getSelfExpression( dj ) - returns the MATLAB expressions that
% generates relation dj.
% getSelfExpression( dj, true ) - encloses the expression in parentheses 
% only if it contains binary relational expressions (join,semijoin, or
% antijoin).
% :: Dimitri Yatsenko :: Created 2011-03-01 :: Modified 2011-03-01 ::

parenthesize = nargin>=2 && parenthesize && ~isempty(regexp(dj.selfExpression,'\*|\./'));

str = dj.selfExpression;
if parenthesize
    str = ['(' str ')'];
end