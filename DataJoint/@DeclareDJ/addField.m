function dj = addField( dj, name, type, comment, default )
% CreateDJ/addField - add a required non-key field to the table declaration.
% 
% Syntax:
%    dj = addField( dj, name, type, comment );   % for a required field
%    dj = addField( dj, name, type, comment, devaultValue );  % a required field with a default value 
%    dj = addField( dj, name, type, comment, [] );  % optional field
% 
% :: Dimitri Yatsenko :: Created 2010-12-28 :: Modified 2011-01-06 ::

assert( ischar(name) && length(name)>=1 ...
    && ismember(name(1),['a':'z']) && all(ismember(name,['a':'z','_','0':'9']))...
    , 'invalid field name ''%s''', name );
if nargin<=4
    default = nan;
end
dj.nonKeyFields(end+1) = struct('name',name,'type',type,'comment',comment,'default',default); 