function uploadAll( dj )
% uploadAll(dj) loads saved tables from .mat files in the current directory
% into the database. The name of the file specifies the table class as
% CLASSNAME.YYYY-MM-DD.mat. Only the latest file is used.
% Duplicate tuples are ignored.  See also DJ/saveAll.
% :: Dimitri Yatsenko :: Created 2011-02-11 :: Modified 2011-02-11 ::

fprintf('Retrieving related tables...\n');
for c = getAllTables(dj)
    obj = eval(c{1});
    f=dir(['./' c{1} '.*.mat']);
    if isempty(f)
        disp(['Found no backup for ' c{1}]);
    else
        [ds,order] = sort( {f.date} );
        f = f(order(end));
        disp(['Loading from ', f.name]);
        f = load( f.name );
        fprintf('Inserting...');
        insert( obj, f.s );
        disp('done');
    end
end