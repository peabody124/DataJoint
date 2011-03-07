function dj = restrict( dj, varargin )
% Apply the relation projection operator to relation dj
%
% INPUTS
% At least one of the following inputs must be provided in any order.
%    'key' - a structure specifying the attributes to match precisely
%    'sqlCondition' - a string specying a logical selfExpression for restriction
%
% The restriction operator restricts the relation dj to those tuples whose
% attribute values match all identically named fields in structure 'key'
% AND the conditions in the string 'sqlCondition'.
%
% Although most common use of the input 'key' is to specify the primary key
% value for restriction, non-key attributes are matched too. The argument
% 'key' is so named to encourage its most appropriate use.
%
% Any fields in 'key' that do not have a counterpart in dj are ignored. This
% may become a source of errors since a misspelled field name will quietly
% produce an underrestricted relation.
%
%    Example 1. Restrict the relation r0 to the subset of tuples in which
%    attribute `exp_date` has the value '2010-10-29' and attribute `lens'
%    has the value 60:
%    >> k = struct( 'exp_date', '2010-10-29', 'lens', 60 );
%    >> r1 = restrict( r0, k );
%
% The input argument 'sqlCondition' specifies additional restriction
% conditions in the form of an SQL boolean selfExpression.
%
%    Example 2. Restricts the relation r1 to the subset in which the
%    values for attribute `fps` are greater than 12:
%    >> r2 = restrict( r1, 'fps>12' );
%
% :: Dimitri Yatsenko :: Created 2010-10-30 :: Modified 2011-03-01 ::

% parse input arguments
assert( nargin==2 || nargin==3, 'invalid input arguments' );
key = struct([]);
sqlCondition = '';
for iArg=1:nargin-1
    if isstruct(varargin{iArg})
        assert(isempty(key),'Only one key may be used in restrict.');
        key = varargin{iArg};
    elseif ischar(varargin{iArg})
        assert(isempty(sqlCondition),'only one sql condition is allowed in restrict');
        sqlCondition = varargin{iArg};
        assert(~isempty(sqlCondition),'empty SQL condition');
    else
        error('invalid input argument');
    end
end

if ~isempty(key) || ~isempty(sqlCondition )
    % put the source in a subquery if it has any renames
    if ~isempty(regexpi(dj.sqlPro,' as '))
        dj.sqlSrc = sprintf('(SELECT %s FROM %s%s) as r', dj.sqlPro, dj.sqlSrc, dj.sqlRes );
        dj.sqlPro = '*';
        dj.sqlRes = '';
    end

    % append key condition to sqlCondition
    if isempty(sqlCondition)
        word = '';
    else
        word = ' AND';
        if ~isempty(key) || ~isempty(dj.sqlRes)
            % parenthesize to protect the order of operators in sqlCondition
            sqlCondition = sprintf('(%s)',sqlCondition);
        end
    end;
    if ~isempty( key )
        fields = fieldnames(key)';
        foundAttributes = ismember(fields,{dj.fields.name});
        for field = fields(foundAttributes)
            value = key.(field{1});
            if ~isempty(value)
                iField = find(strcmp(field{1},{dj.fields.name}));
                assert(~dj.fields(iField).isBlob,'The key must not include blob fields.');
                if dj.fields(iField).isString
                    assert( ischar(value), 'Value for key.%s must be a string', field{1})
                    value=sprintf('"%s"',value);
                else
                    assert(isnumeric(value), 'Value for key.%s must be numeric', field{1});
                    value=sprintf('%1.16g',value);
                end
                sqlCondition = sprintf('%s%s `%s`=%s', sqlCondition, word, dj.fields(iField).name, value);
                word = ' AND';
            end
        end
    end
    if ~isempty(sqlCondition)
        % update selfExpression
        if isBase(dj)
            selfStr = '%s(''%s'')';
        else
            selfStr = 'restrict(%s,''%s'')';
        end
        dj.selfExpression = sprintf(selfStr,dj.selfExpression,regexprep(strtrim(sqlCondition),'''',''''''));

        % append sqlCondition to the total condition
        if isempty(dj.sqlRes)
            dj.sqlRes = [' WHERE ' sqlCondition];
        else
            dj.sqlRes = [dj.sqlRes ' AND ' sqlCondition];
        end
    end
end