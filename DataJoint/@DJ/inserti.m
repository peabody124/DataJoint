function inserti(dj,varargin)
% insert(dj,...) - insert one or multiple tuples into base relation dj. 
% If the tuple already exists, the insert is quietly ignored. 
%
% Syntax:
% inserti(dj,tuple);
% inserti(dj,'attr1',value1,'attr2',value2,...);
%
% :: Dimitri Yatsenko :: Created 2011-02-03 :: Modified 2011-03-09 ::

assert(nargin>1,'missing arguments in DJ/inserti');
if isstruct(varargin{1})
    assert(nargin==2);
    tuples = varargin{1};
else
    assert(mod(nargin,2)==1 && iscellstr(varargin(1:2:end)),'arguments must be attribute-value pairs in DJ/inserti');
    for i=1:2:length(varargin)
        tuples.(varargin{i})=varargin{i+1};
    end
end

insert(dj,tuples,'ignore')