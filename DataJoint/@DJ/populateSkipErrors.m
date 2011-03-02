function [failedKeys,errors] = populateSkipErrors( dj, key )
% [failedKeys,errors] = populateSkipErrors( dj [, key] ) -- populate a base
% relation based on the contents if its parent relations optionally
% restricted by a key. Calls makeTuples( dj, k ) for   the primary key of
% every tuple in parentRelation( dj ). If  makeTuples(dj,k) throws an error,
% the error is printed and ignored  ignored and the transaction is rolled
% back. All primary keys that could  not be populed are returned in the
% structure array failedKeys.
%
%  :: Dimitri Yatsenko :: Created 2009-10-07 :: Modified 2011-03-01 ::

assert( isBase(dj), 'Cannot populate a derived relation' );

if ~ismember(dj.tableType,'ci')
    warning( 'DJ:populateManual','%s is a manual table. Cannot populate.', class(dj) );
elseif ischar(dj.populateRelation) && isempty(dj.populateRelation)
    warning('DJ:noPopulateRelation','%s cannot be populate directly because it does not have a populate relation', class(dj));
else
    if nargin==1
        key = struct([]);
    else
        assert(  isstruct(key) && isscalar(key)...
            , 'The parameter ''key'' must be a scalar structure.' );
    end

    % rollback any ongoing transaction
    cancelTransaction(dj);

    % find matching tuples in the parent relation
    if ischar(dj.populateRelation)
        P = eval(dj.populateRelation);
    else
        P = dj.populateRelation;
    end
    keys = fetch(restrict(P,key)./restrict(dj,key));     % the keys of the parent relation that dont have matching tuples in dj

    % call makeTuples(dj,key) for each key in keys as an atomic transaction.
    dj.inPopulate = true;
    failedKeys = keys([]);
    errors = {};
    for key = flipud(keys)'
        fprintf('Populating %s for ',class(dj));
        disp( key );
        startTransaction(dj);  % atomic transaction
        try
            if isempty(restrict(dj,key))  % check again in case some other process has populated it
                makeTuples(dj,key);
                commitTransaction(dj);
            end
        catch e
            cancelTransaction(dj);
            failedKeys(end+1) = key;                  %#ok<AGROW>
            if nargout>1
                errors{end+1} = e;                    %#ok<AGROW>
            end
        end
    end
    dj.inPopulate = false;  % this is unnecessary in MATLAB's current implementation
end
