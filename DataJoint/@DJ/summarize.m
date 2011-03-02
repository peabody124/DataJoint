function R = summarize( R, Q, varargin )
% DJ/summarize  adds summary fields to relation R
%
% SYNTAX:
% P = summarize( R, Q, 'aggregate(field)->new_field1' )
%
% The resulting relation P will be the semijoin R.*Q  (see DJ/times).
% P will also have new fields containing aggregate statistics on matching tuples of Q .
%
% The aggregate operator can include any of the following SQL aggregate operators:
% count(*), sum(field), avg(field), max(field), min(field), variance(field), and std(field).
% Here field is a field from Q.
%
% The SQL equivalent of summarize is implemented using JOIN and GROUP BY
%
% EXAMPLE 1:
%   >> S = summarize( Scans, Cells, 'count(*)->ncells', 'avg(cell_radius)->avg_radius' );
%
% Here S will contain all the fields of Scans plus the new
% field ncells, which contains the number of fields in Cells matching each
% row in Scans, i.e. the number of cells in each scan. Scans that do not
% have any cells will not be included.
%
% EXAMPLE 2
%   >> tunedCells = CellOriTuning('trace_opt=20');
%   >> S = summarize( Scans.*tunedCells,tunedCells,'avg(ori_p<0.05)*100->pcent_tuned');
%
% Here S will contain all Scans that have tuned cells (as processed with
% trace option 20) with a new field pcent_tuned containing the
% percentages of cells that are tuned in each scan.
%
% :: Dimitri Yatsenko :: Created 2010-12-16 :: Modified 2011-02-09 ::

assert( isa(Q,'DJ') && iscellstr( varargin ), 'Invalid inputs.' );

if strcmp(R.sqlPro,'*')
    R.sqlPro = sprintf(',%s',R.fields.name);
    R.sqlPro = R.sqlPro(2:end);
end

% update the field list
R.selfExpression = sprintf('summarize(%s,%s',getSelfExpression(R),getSelfExpression(Q));
for attr = varargin
    toks = regexp( attr{1}, '\s*(.+)\s*->\s*(\w+)', 'tokens' );
    assert( length(toks)==1, 'Invalid summary argument ''%s''', attr{1} );
    R.fields(end+1) ...
        = struct('name',toks{1}{2},'type','','isKey',false,'isNumeric',false,...
        'isString',false,'isBlob',false,'isNullable',false,'comment','SQL computation','default',[]);
    R.selfExpression = sprintf('%s,''%s->%s''',R.selfExpression,toks{1}{1},toks{1}{2});
    R.sqlPro = sprintf('%s,%s as %s', R.sqlPro, toks{1}{1}, toks{1}{2} );
end
R.selfExpression = [R.selfExpression,')'];

% form query
keyStr = sprintf(',%s',R.primaryKey{:});
if isempty(Q.sqlRes) && strcmp(Q.sqlPro,'*')
    R.sqlSrc = sprintf('(SELECT %s FROM %s NATURAL JOIN %s%s GROUP BY %s) as qq'...
        , R.sqlPro, R.sqlSrc, Q.sqlSrc, R.sqlRes, keyStr(2:end) );
else
    R.sqlSrc = sprintf('(SELECT %s FROM %s NATURAL JOIN (SELECT %s FROM %s%s) as q%s GROUP BY %s) as qq'...
        , R.sqlPro, R.sqlSrc, Q.sqlPro, Q.sqlSrc, Q.sqlRes, R.sqlRes, keyStr(2:end) );
end
R.sqlPro = '*';
R.sqlRes = '';