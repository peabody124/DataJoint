function R1= times(R1,R2)
% DJ/times - relational natural semijoin. The semijoin R1.*R2 contains
% all the tuples of R1 that have matching tuples in R2.
% See DataJoint.pdf for a review of relational concepts.
%
%  Syntax: r3=r1.*r2
%
% For technical details, see
%   http://dev.mysql.md/doc/refman/5.4/en/semi-joins.html
%
%  :: Dimitri Yatsenko :: Created 2010-08-21 :: Modified 2011-02-09 ::

% Semijoin is performed on common non-nullable nonblob attributes
commonAttrs = intersect(...
    {R1.fields(~[R1.fields.isNullable] & ~[R1.fields.isBlob]).name},...
    {R2.fields(~[R2.fields.isNullable] & ~[R2.fields.isBlob]).name});   

% commonAttrs is empty, R1 is unchanged
if ~isempty(commonAttrs)
    commonAttrs = sprintf( ',%s', commonAttrs{:} );
    commonAttrs = commonAttrs(2:end);
    if ~strcmp(R1.sqlPro,'*')
        R1.sqlSrc = sprintf('(SELECT %s FROM %s%s) as r1',R1.sqlPro,R1.sqlSrc,R1.sqlRes);
        R1.sqlPro = '*';
        R1.sqlRes = '';
    end
    if isempty(R1.sqlRes)
        word = 'WHERE';
    else
        word = 'AND';
    end
    if strcmp(R2.sqlPro,'*')
        R1.sqlRes = sprintf( '%s %s (%s) IN (SELECT %s FROM %s%s)'...
            ,R1.sqlRes,word,commonAttrs,commonAttrs,R2.sqlSrc,R2.sqlRes );
    else
        R1.sqlRes = sprintf( '%s %s (%s) IN (SELECT %s from (SELECT %s FROM %s%s) as r2)'...
            ,R1.sqlRes,word,commonAttrs,commonAttrs,R2.sqlPro,R2.sqlSrc,R2.sqlRes);
    end
end

% update selfExpression
R1.selfExpression = [R1.selfExpression '.*' getSelfExpression(R2,true)];