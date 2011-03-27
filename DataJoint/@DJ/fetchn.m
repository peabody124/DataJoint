function varargout = fetchn( R, varargin )
% DJ/fetch1 - retrieve attribute values from multiple tuples in relation R.
% Nonnumeric results are returned as cell arrays.
%
% Syntax:
%    [v1,v2,..,vk] = fetch1( R, 'attr1','attr2',...,'attrk' )
%    [v1,v2,..,vk] = fetch1( R, Q, 'attr1', 'attr2',...,'attrk' );
%
%  :: Dimitri Yatsenko :: Created 2010-11-01 :: Modified 2010-03-23 ::


% validate input
if nargin>=2 && isa(varargin{1},'DJ')
    attrs = varargin(2:end);
else
    attrs = varargin;
end
assert(nargout==length(attrs) || (nargout==0 && length(attrs)==1),'The number of outputs must match the number of requested attributes');
assert( ~any(strcmp(attrs,'*')), '''*'' is not allwed in fetch1()');

% submit query
R = pro(R,varargin{:});
ret=query(R,...
    sprintf('SELECT %s FROM %s%s',R.sqlPro,R.sqlSrc,R.sqlRes));

% copy into output arguments
for iArg=1:length(attrs)
    name = regexp(attrs{iArg}, '(^|->)\s*(\w+)', 'tokens');  % if renamed, use the renamed attribute
    name = name{end}{2};
    assert(isfield(ret,name),'Field %s not found', name );
    varargout{iArg} = ret.(name);
end