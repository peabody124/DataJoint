function ret = isBase(dj)
% isBase(dj) returns true if dj is a base relation.
%
% :: Dimitri Yatsenko :: Created 2011-03-01 :: Modified 2011-03-01 ::

ret = ~isempty(dj.selfExpression) && all(ismember(lower(dj.selfExpression),['a':'z','0':'9']));