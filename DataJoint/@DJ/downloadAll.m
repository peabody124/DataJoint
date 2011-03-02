function downloadAll( dj, varargin )
% saveall(dj) - backs up all data linked to dj in the current directory.
% Set parameter 'skipManual' to true to skip saving manual tables (default false).
% Set parameter 'skipLookup' to true to skip saving lookup tables (default false).
% Set parameter 'skipImported' to true to skip imported tables (default false).
% Set parameter 'skipComputed' to false to include computed table (default true).
% Set parameter 'skipJobs' to false to include jobs tables (default true).
%
% :: Dimitri Yatsenko :: Created 2011-01-25 :: Modified 2011-02-11 ::

ip=inputParser;
ip.addParamValue('skipLookup',false);
ip.addParamValue('skipManual',false);
ip.addParamValue('skipImported',false);
ip.addParamValue('skipComputed',true);
ip.addParamValue('skipJobs',true);
ip.parse(varargin{:});

fprintf('Retrieving related tables...\n');
for c = getAllTables(dj)
    obj = eval(c{1});
    toSave = true;
    toSave = toSave && (obj.tableType~='m' || ~ip.Results.skipManual);
    toSave = toSave && (obj.tableType~='l' || ~ip.Results.skipLookup);
    toSave = toSave && (obj.tableType~='c' || ~ip.Results.skipComputed); 
    toSave = toSave && (obj.tableType~='i' || ~ip.Results.skipImported);
    toSave = toSave && (~strncmp(c{1},'Jobs',4) || ~ip.Results.skipJobs);
    if toSave
        download( obj );
    end
end