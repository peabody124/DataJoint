function jobDJ = runJob( dj, jobNum )
% jobDj = runJob( dj, jobNum=1 ) - executes a distributed job.
%
% SYNTAX:
%
% runJob( dj ) -- execute job0( dj, key ) for every key of dj as a separate job.
% runJob( dj, 1 ); -- execute job1( dj, key );
% etc.
%
% OUTPUT:
%
% The return value is the DJ object for the job reservation table.
% In its first invocation, runJob creates a DJ class named "Jobs<TableName>"
% where <TableName> is the class name of dj.
% For example, runJob(Scans) will create a new class named JobsScans and
% its table in the database. It will then start executing the jobs in sequence.
% Subsequenty invocations of runJob( Scans ) will use the table
% to reserve and execute the next available job. At any time, you may query
% the relation JobsScans to see the results of processing, error messages,
% etc. A job is considered available if it has no entry in the job
% reservation table. Thus is you need to re-process some jobs, erase their
% entries from the job reservation table.
%
% For example, to reprocess all the jobs that ended in error during the
% previous execution of runJob( Scans, 2), run:
% >> delete(JobsScans('jobnum=2 and status="error"'));
% >> runJob(Scans,2);
%
% :: Dimitri Yatsenko :: Created 2011-01-21 :: Modified 2011-01-25

% generate job reservation table name
if nargin<=1
    jobNum=0;
end
assert(isnumeric(jobNum) && mod(jobNum,1)==0 && jobNum>=0 && jobNum<=255, ...
    'jobNum must be an integer between 0 and 255');
jobTableName = sprintf('Jobs%s',class(dj));

% connect to the job reservation table
try
    assert( ~isempty(which(jobTableName)) );
    jobDJ = eval( jobTableName );
catch
    % if not done already, create the job reservation table and its class
    ddj = DeclareDJ( eval(dj.conn.schemaClass), jobTableName, 'computed' );
    ddj = addParent( ddj, dj );
    ddj = setPopulateRelation( ddj, class(dj) );
    ddj = addKeyField( ddj, 'jobnum', 'tinyint unsigned', 'job number' );
    ddj = addField( ddj, 'job_status', 'enum("reserved","completed","error","ignore")',...
        'reserved/completed/error/ignore. If tuple is missing, the job is available');
    ddj = addField( ddj, 'error_message', 'varchar(1023)',...
        'error message returned by the failed job', []);
    ddj = addField( ddj, 'error_stack', 'blob',...
        'error stack containing filenames and line numbers', []);
    jobDJ = execute( ddj );
    setTableComment( jobDJ, 'Job reservation table' );
end


% reserve and execute the jobs
for key = fetch(dj)'
    key.jobnum = jobNum;
    if isempty(restrict(jobDJ,key))  % empty = the job is available

        % reserve the job
        inserti( jobDJ, setfield(key,'job_status','reserved') );

        try
            % do the job
             eval(sprintf('job%d(dj,key)',jobNum));

            % report job completed
            deleteNoninteractive( restrict(jobDJ,key) );
            inserti( jobDJ, setfield(key,'job_status','completed') );

        catch e
            % report error
            warning( e.message );
            jobKey = key;
            jobKey.job_status = 'error';
            jobKey.error_message = e.message;
            jobKey.error_stack   = e.stack;
            deleteNoninteractive( restrict(jobDJ,key) );
            inserti( jobDJ, jobKey);
        end
    end
end