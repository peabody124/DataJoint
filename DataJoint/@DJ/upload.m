function upload( dj, filepath )
% upload(dj[, path]); - uploads the table from the latest .mat file in 
% the directory path matching the filepath. If the filepath is not
% provided, will look for ./CLASSNAME.*.mat
% Duplicate tuples are ignored.
%
% :: Dimitri Yatsenko :: created 2011-02-13 :: modified 2011-02-13 ::

if nargin<=1
    filepath = sprintf('./%s.*.mat',class(dj));
end

f=dir(filepath);
if isempty(f)
    fprintf('%s not found\n',filepath);
else
    [ds,order] = sort( {f.date} );
    f = f(order(end));
    disp(['reading from ',f.name]);
    f = load(f.name);
    fprintf('insering...');
    inserti(dj,f.s);
    disp('complete');
end
