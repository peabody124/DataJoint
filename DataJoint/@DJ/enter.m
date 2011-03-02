function enter( dj, prefilled )
% enter(dj[,prefilled]) - enter data into the database manually recursively
% through dependent tables.
% 
% :: Dimitri Yatsenko :: Created 2011-02-15 :: Modified 2011-02-15 ::

assert( ismember(dj.tableType,'lm'), 'can only enter into manual tables' ); 
if nargin<=1
    prefilled=struct;
end

fields = {dj.fields.name}';
prompt = {dj.fields.name};
answers = cellfun(@num2str,{dj.fields.default},'UniformOutput',false);
include = true(size(prompt));

for i = 1:length( fields )
    if dj.fields(i).isKey
        prompt{i} = ['*' prompt{i}];
    end
    if dj.fields(i).isNullable
        prompt{i} = [prompt{i} ' (opt)'];
    end
    prompt{i} = sprintf('%s  --  %s  ::  %s',prompt{i},dj.fields(i).comment,dj.fields(i).type);
    include(i) = ~dj.fields(i).isString || ~strcmpi(answers{i}, 'CURRENT_TIMESTAMP' );
    if isfield(prefilled,fields{i})
        answers{i} = num2str(prefilled.(fields{i}));
    end
end

include = find(include);
fields = fields(include);
answers = answers(include);
prompt = prompt(include);
isKey = [dj.fields(include).isKey];
dlgOpt.WindowStyle='normal';
dlgOpt.Resize='on';

while true
    answers = inputdlg(prompt, class(dj), 1, answers,dlgOpt);
    if isempty( answers )
        break;
    end
    values = answers;
    for i=1:length(include)
        if dj.fields(include(i)).isNumeric
            values{i} = str2num(values{i});
        end
    end

    if any(cellfun(@isempty,values(isKey)))
        uiwait( errordlg( 'Missing key fields', class(dj) ) );
        continue;
    end

    key = cell2struct( values(isKey), fields(isKey) );
    tuple = cell2struct(  values, fields );

    toInsert = true;
    if ~isempty( restrict(dj,key) )
        cancel = 'cancel';
        button = questdlg( 'Duplicate entry', class(dj), 'replace the existing tuple and remove dependent tuples!', cancel, cancel);
        if strcmp(button,cancel)
            toInsert = false;
        else
            deleteNoninteractive( restrict(dj,key) );
            fprintf('Deleted from %s:\n', class(dj) );
            disp(key);
        end
    end
    if toInsert
        try
            insert(dj,tuple);
        catch
            errordlg( lasterr );
            continue;
        end
        fprintf('inserted into %s:\n', class(dj));
        disp(fetch(restrict(dj,key),'*'));
        for child = getChildTables(dj)'
            childObj = eval(child{1});
            if childObj.tableType=='m'
                enter( childObj, key );
                disp( restrict( childObj, key ) ); 
            end
        end
    end
end