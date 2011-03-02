% function commitTransaction
% see startTransction()

function commitTransaction(obj)
query(obj,'COMMIT');  % commit transaction
