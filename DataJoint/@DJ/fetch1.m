function varargout = fetch1( R, varargin )
% DJ/fetch1 - retrieve data from a relation into Matlab variables.
% Use fetch1 when you know that R contains at most one tuple
%
% Syntax:
%    [f1,f2,..,fk] = fetch1( R, 'attr1','attr2',...,'attrk' )
%
%  :: Dimitri Yatsenko :: Created 2010-11-01 :: Modified 2010-11-01 ::

% validate input
assert( nargin>1, 'missing attributes' );
assert( ~any(strcmp(varargin,'*')), '''*'' is not allwed in fetch1()');
assert(nargout==length(varargin) || (nargout==0 && nargin==2),'The number of outputs must match the number of requested attributes');

s = fetch(R,varargin{:});
assert(isscalar(s),'fetch1 can only retrieve a single existing tuple.');

% copy into output arguments
for iArg=1:length(varargin)
    name = regexp(varargin{iArg}, '(^|->)\s*(\w+)', 'tokens');  % if aliased, use the alias
    if length(name)==2
        name = name{2}{2};
    else
        name = name{1}{2};
    end
    varargout{iArg}=s.(name);
end