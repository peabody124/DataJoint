function exportSchema( dj, mfile, classDirectory )
% exportSchema( dj, mfile ) - generate the code for table declarations of
% all tables linked to dj and write it to the mfile. 
% 
% exportSchema( dj, mfile, classDirectory ) - only include tables whose
% classes are defined in the classDirectory. 
% 
% Examples:
% exportSchema( Mice,'declarations.m');
% exportSchema( Mice,'declarations.m','/vis2p/core');
%
% :: Dimitri Yatsenko :: Created 2011-02-10 :: Modified 2010-02-23 ::

fid  = fopen( mfile, 'w' );
s = '';
if nargin>=3
    s = classDirectory;
end
fprintf( fid, '%%%%%%%%%%%% SCHEMA %s %s %%%%%%%%%%%%', dj.conn.schemaClass, s ); 
disp('Retrieving the table list...');

tables = getAllTables( dj ); 
if nargin>=3
    % restrict to tables whose classes are defined in 'classDirectory'
    lst = dir(fullfile(classDirectory,'@*'));
    lst = cellfun( @(x) x(2:end), {lst.name}, 'UniformOutput', false );
    tables = tables(ismember(tables,lst));
end

% write the file
for t = tables
    fprintf('Reverse engineering %s ...\n', t{1} );
    fprintf(fid,'\n\n%s', getDeclaration(eval(t{1})));
end
fclose(fid);