function ret = fetch( R, varargin )
% DJ/fetch - retrieve data from a relation into Matlab variables.
%
% Syntax
%    s = fetch(R) - retrieve key attributes as a structure array
%    s = fetch(R,'*') - retrieve all attributes as a structure array
%    s = fetch(R,'attr1','attr2',...) - retrieve key attributes and
%    specified attributes as a structure array.
%
%  :: Dimitri Yatsenko :: Created 2010-11-01 :: Modified 2010-11-03 ::

% retrieve data
R = pro(R,varargin{:});
ret = query(R,sprintf('SELECT %s FROM %s%s',R.sqlPro,R.sqlSrc,R.sqlRes));
ret = structure2array(ret);