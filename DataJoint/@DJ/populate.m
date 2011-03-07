function populate( dj, key )
% populate( dj [, key] ) -- populate a  base relation based on the contents
% if its parent relations optionally restricted to key. The function works
% by calling makeTuples( dj, k ) for every primary key 'k' of
% restrict(parentRelation( dj ),key) that have no matching tuples in dj.
%
%  :: Dimitri Yatsenko :: Created 2009-10-07 :: Modified 2011-03-01 ::

assert( isBase(dj), 'Cannot populate a derived relation' );
if ~ismember(dj.tableType,'ci')
    warning( 'DJ:populateManual','%s is a manual table. Cannot populate.', class(dj) );
elseif ischar(dj.populateRelation) && isempty(dj.populateRelation)
    warning('DJ:noPopulateRelation','%s cannot be populate directly because it does not have a populate relation', class(dj));
else
    assert( nargin==1 || isstruct(key) && isscalar(key)...
        , 'The parameter ''key'' must be a scalar structure.' );

    % rollback any ongoing transaction
    cancelTransaction(dj);

    % evaluate the populate relation
    if ischar(dj.populateRelation)
        dj.populateRelation = eval(dj.populateRelation);
    end
    
    % get the keys to populate
    if nargin==1
        % if the key is not specified, find unpopulated keys
        keys = fetch(dj.populateRelation./dj);
    else
        % if the key is specified, assume that it's likely unpopulated
        keys = fetch(restrict(dj.populateRelation,key));
    end

    % call makeTuples(dj,key) for each key in keys as an atomic transaction.
    dj.inPopulate = true;
    for key = keys'
        startTransaction(dj);  % atomic transaction
        try
            if ~isempty(restrict(dj,key))
                cancelTransaction(dj);
            else
                fprintf('\nPopulating %s for ',class(dj));
                disp( key );
                makeTuples(dj,key);
                commitTransaction(dj);
            end
        catch e
            cancelTransaction(dj);
            rethrow(e);
        end
    end
    dj.inPopulate = false;  % this is unnecessary in MATLAB's current implementation
end