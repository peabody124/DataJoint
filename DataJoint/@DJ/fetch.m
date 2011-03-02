function ret = fetch( R, varargin )
% DJ/fetch - retrieve data from a relation into Matlab variables.
%
% Syntax
%    s = fetch(R) - retrieve all fields into a structure array
%    s = fetch(R,'attr1','attr2',...) - retrieve only specific attributes into a structure array
%
%  :: Dimitri Yatsenko :: Created 2010-11-01 :: Modified 2010-11-03 ::

% retrieve data
R = pro(R,varargin{:});
ret = query(R,sprintf('SELECT %s FROM %s%s',R.sqlPro,R.sqlSrc,R.sqlRes));
ret = structure2array(ret);
