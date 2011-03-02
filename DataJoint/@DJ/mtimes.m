function R1=mtimes(R1,R2)
%  DJ/mtimes - relational natural join.  
%  See DataJoint.pdf for a review of relational concepts. 
%  
%  Syntax: r3=r1*r2
%
%  :: Dimitri Yatsenko :: Created 2010-08-21 :: Modified 2010-11-07 ::

common = intersect( ...
    {R1.fields([R1.fields.isNullable] | [R1.fields.isBlob]).name},...
    {R2.fields([R2.fields.isNullable] | [R2.fields.isBlob]).name});

if ~isempty(common) 
    error( 'Attribute ''%s'' is optional or a blob. Exclude it from one of the relations before joining.', common{1} );
end

% merge field lists
[f,ix] = setdiff({R2.fields.name},{R1.fields.name});
R1.fields = [R1.fields;R2.fields(sort(ix))];
R1.primaryKey = {R1.fields([R1.fields.isKey]).name}';

% form the join query
if strcmp(R1.sqlPro,'*') && isempty(R1.sqlRes)
    R1.sqlSrc = sprintf( '%s NATURAL JOIN ',R1.sqlSrc );
else
    R1.sqlSrc = sprintf( '(SELECT %s FROM %s%s) as r1 NATURAL JOIN '...
        ,R1.sqlPro,R1.sqlSrc,R1.sqlRes);
end
R1.sqlPro='*';
R1.sqlRes='';

if strcmp(R2.sqlPro,'*') && isempty(R2.sqlRes)
    R1.sqlSrc = sprintf( '%s%s', R1.sqlSrc, R2.sqlSrc);
else
    alias = char(97+floor(rand(1,6)*26)); % to avoid duplicates
    R1.sqlSrc = sprintf( '%s (SELECT %s FROM %s%s) as `r2%s`',R1.sqlSrc,R2.sqlPro,R2.sqlSrc,R2.sqlRes,alias); 
end

R1.selfExpression = [R1.selfExpression '*' getSelfExpression(R2,true)];