function deleteNoninteractive(dj)
% deleteNoninteractive(dj) deletes tuples in relation dj without cancelling
% the ongoing transaction or prompting the user. For interactive use, use
% delete(dj) instead.

assert(~ismember(dj.tableType,'ci')||~isempty(dj.populateRelation)...
    , 'Cannot delete because this automatically populated relation does not have a populate relation. See DJ/setPopulateRelation');

query( dj, sprintf('DELETE FROM %s%s',dj.sqlSrc,dj.sqlRes) );