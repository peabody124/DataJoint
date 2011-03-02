function delete( dj, prompt )
% delete(dj)  - remove all tuples in relation dj from its base relation.
%
% SYNTAX:
%   delete(dj) or delete(dj,true);  -- delete with interactive confirmation
%   delete(dj,false);    -- delete without a warning
%
% EXAMPLES:
%   delete( ScansAligned );                  % deletes all tuples from ScansAligned
%   delete( ScansAligned('mouse_id=10'));    % deletes tuples in ScansAligned with mouse_id=10
%   delete( ScansAligned.*Scans('lens=16')); % deletes all tuples in ScansAligned for which lens=16
%
% :: Dimitri Yatsenko :: Created 2010-05-18 :: Modified 2010-11-10 ::

prompt = nargin<2 || prompt;

cancelTransaction(dj);  % roll back any uncommitted transaction left open from the an interrupted populate call.
% confirm with user and delete
n = length(dj);
if n==0
    disp('Nothing to delete');
else
    if ismember( dj.tableType, 'ml' )
        warning('About to delete from a table containing manual data. Proceed at your own risk.' );
        prompt = true; 
    end
    if prompt && ~strcmpi('yes',input(sprintf('Delete %d records from %s? yes/no >>',n,class(dj)),'s'))
        warning('Cancelled delete.');
    else
        deleteNoninteractive(dj);
    end
end