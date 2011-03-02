function disp( dj )
% DJ/disp - displays the contents of a relation.  
% Only non-blob fields of the first several tuples are shown. The total
% number of tuples is printed at the end.
%
% :: Dimitri Yatsenko :: Created 2010-12-29 :: Modified 2011-01-06 :: 

fprintf('\n');
if isempty( dj.conn.table )
    disp('Empty relation');
else
    % print header
    colWidth = 12;
    ix = find( ~[dj.fields.isBlob] );  % fields to display
    for iField = ix;
        fname = dj.fields(iField).name;
        if dj.fields(iField).isKey
            fname = ['*' fname];
        end
        if length(fname)>colWidth
            fname = [fname(1:colWidth-2), '..'];
        end
        fprintf('  %12s',fname );
    end
    fprintf('\n');

    % print rows
    maxRows = 24;
    keys = fetch( dj )';
    nTuples = length(keys);
    for key = keys(1:min(end,maxRows))
        s = fetch( restrict(dj,key), dj.fields(ix).name );
        for iField = ix
            v = s.(dj.fields(iField).name);
            if isnumeric(v)
                fprintf('  %12g',v);
            else
                if length(v)>colWidth
                    v = [v(1:colWidth-2), '..'];
                end
                fprintf('  %12s',v);
            end
        end
        fprintf('\n');
    end
    if nTuples > maxRows
        for iField = ix
            fprintf('  %12s','.....');
        end
        fprintf('\n');
    end

    % print the total number of tuples
    fprintf('%d tuples\n\n', nTuples );
end