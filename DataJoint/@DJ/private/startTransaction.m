% function startTransaction  -- begin an atomic transaction.
% 
% All mySQL statements after this function will only take effect after
% executing commitTransaction

function startTransaction(obj)
query(obj,'START TRANSACTION WITH CONSISTENT SNAPSHOT' );