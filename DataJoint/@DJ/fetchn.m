function varargout = fetchn( R, varargin )
% DJ/fetch1 - retrieve attribute values from multiple tuples in relation R.
% Nonnumeric results are returned as cell arrays.
% 
% Syntax:
%    [v1,v2,..,vk] = fetch1( R, 'attr1','attr2',...,'attrk' )  
%
%  :: Dimitri Yatsenko :: Created 2010-11-01 :: Modified 2010-11-13 ::

% validate input arguments
assert(  nargin>1 && ~isempty(varargin{1}), 'missing attributes');
assert( ~any(strcmp(varargin,'*')), '''*'' is not allwed in fetchn()');
assert(nargout==length(varargin) || (nargout==0 && nargin==2),'The number of outputs must match the number of requested attributes');
R = pro(R,varargin{:});
ret=query(R,sprintf('SELECT %s FROM %s%s',R.sqlPro,R.sqlSrc,R.sqlRes));

% copy into output arguments
for iArg=1:length(varargin)
    name = regexp(varargin{iArg}, '(^|->)\s*(\w+)', 'tokens');  % if renamed, use the renamed attribute
    if length(name)==2
        name = name{2}{2};
    else
        name = name{1}{2};
    end
    assert(isfield(ret,name),'Field %s not found', name );
    varargout{iArg} = ret.(name);
end