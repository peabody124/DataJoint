function insert( dj, tuples, duplicates )
% insert(dj,tuples) - insert tuples into table dj.
% insert(dj,tuples,'ignore') - insert tuples into table dj, skipping duplicates.
% 
% tuples can be a scalar structure or a columnwise structure array and 
% must have all the required fields that the table has.
% 
% Tuples may be inserted into imported and computed tables only from inside the makeTuples callback.
% Tuples may be inserted into manual and lookup tables only from outside of makeTuples.
%
%  :: Dimitri Yatsenko :: Created 2009-10-09 :: Modified 2011-02-23 ::

assert( isstruct(tuples) && ~isempty(tuples) && size(tuples,2)==1 ...
    , 'Tuples must be a non-empty structure array (column)' );

ignore = '';
if nargin>=3 
    assert( ischar(duplicates) && strcmpi(duplicates,'ignore'), 'invalid input argument' );
    ignore = ' IGNORE';
end

% validate fields
fnames = fieldnames( tuples );
found = ismember(fnames,{dj.fields.name});
assert(all(found),'Field %s is not found in the table %s',fnames{find(~found,1,'first')},class(dj));
ix = ismember({dj.fields.name},fnames);
assert( all(ix([dj.fields.isKey])), 'Incomplete primary key' )

% form query
for tuple=tuples'
    queryStr = '';
    blobs = {};
    for i = find(ix)
        v = tuple.(dj.fields(i).name);
        if dj.fields(i).isString
            assert( ischar(v), 'The field %s must be a character string', dj.fields(i).name );
            if isempty(v)
                queryStr = sprintf( '%s`%s`="",', queryStr,dj.fields(i).name );
            else
                queryStr = sprintf( '%s`%s`="{S}",', queryStr,dj.fields(i).name );
                blobs{end+1} = v;                                       %#ok<AGROW>
            end
        elseif dj.fields(i).isBlob
            queryStr = sprintf( '%s`%s`="{M}",', queryStr,dj.fields(i).name );
            blobs{end+1} = v;                                       %#ok<AGROW>
        else
            if islogical(v)  % mym doesn't support logicals
                v = uint8(v);
            end
            assert( isscalar(v) && isnumeric(v), 'The field %s must be a numeric scalar value', dj.fields(i).name );
            if ~isnan(v)  % nans are not passed: assumed missing.
                queryStr = sprintf( '%s`%s`=%1.16g,',queryStr,dj.fields(i).name,v);
            end
        end
    end

    % issue query. Insert ignores duplicates.
    query(dj,sprintf('INSERT%s %s SET %s', ignore, dj.sqlSrc, queryStr(1:end-1)), blobs{:});
end