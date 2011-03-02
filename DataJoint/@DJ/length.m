function n = length( R )
% return the cardinality of relation R
% :: Dimitri Yatsenko :: Created 2009-10-09 :: Modified 2010-10-30 ::

if strcmp(R.sqlPro,'*')
    sql = sprintf('SELECT count(*) as n FROM %s%s',R.sqlSrc,R.sqlRes);
else
    sql = sprintf('SELECT count(*) as n FROM (SELECT DISTINCT %s FROM %s%s) as r',R.sqlPro,R.sqlSrc,R.sqlRes);
end
n = query(R,sql);
n=n.n;