function download( dj, filepath )
% download(dj[,filepath]) - saves the contents of a table into a file. 
% The data are stored as a MATLAB structure array.
%
% :: Dimitri Yatsenko :: Created 2011-01-25 :: Modified 2011-02-11 ::

if nargin<=1
    filepath = sprintf('./%s.%s.mat',class(dj),datestr(now,29));
end
fprintf('Retrieving data from %s...\n', class(dj));
s = fetch(dj,'*');
fprintf('saving %d records in %s...', length(s), filepath);
save(filepath,'s');
fprintf('done.\n');