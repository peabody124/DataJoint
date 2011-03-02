function R1= rdivide(R1,R2)
% DJ/redivide - relational natural semidifference.
% r1./r2 contains all tuples in r1 that do not have matching tuples in r2.
%
%  Syntax: r3=r1./r2
%
%  :: Dimitri Yatsenko :: Created 2010-11-01 :: Modified 2011-02-28 ::

% Semidifference is performed on common non-nullable nonblob attributes
commonAttrs = intersect(...
    {R1.fields(~[R1.fields.isNullable] & ~[R1.fields.isBlob]).name},...
    {R2.fields(~[R2.fields.isNullable] & ~[R2.fields.isBlob]).name});   

commonAttrs = intersect({R1.fields.name},{R2.fields.name});
if isempty(commonAttrs)
    % commonAttrs is empty, R1 is the empty relation
    R1.sqlRes = [R1.sqlRes ' WHERE FALSE'];
else
    % update R1's query to the semidifference of R1 and R2
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
        R1.sqlRes = sprintf( '%s %s (%s) NOT IN (SELECT %s FROM %s%s)'...
            ,R1.sqlRes,word,commonAttrs,commonAttrs,R2.sqlSrc,R2.sqlRes );
    else
        R1.sqlRes = sprintf( '%s %s (%s) NOT IN (SELECT %s from (SELECT %s FROM %s%s) as r2)'...
            ,R1.sqlRes,word,commonAttrs,commonAttrs,R2.sqlPro,R2.sqlSrc,R2.sqlRes);
    end
end

% update selfExpression
R1.selfExpression = [R1.selfExpression './' getSelfExpression(R2,true)];