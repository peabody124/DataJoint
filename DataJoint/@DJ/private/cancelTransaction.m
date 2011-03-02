% function cancelTransaction
% see DJ/startTransaction

function cancelTransaction(obj)
query(obj,'ROLLBACK');  % discard changes