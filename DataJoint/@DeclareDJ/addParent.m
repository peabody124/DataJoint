function ddj = addParent( ddj, varargin )
% DeclareDJ/addParent - adds a parent dependency to the the table
% declaration.
%
% Syntax
%    ddj = addParent( ddj, Parent1, Parent2, ...);
% 
% Here Parentn are objects of class DJ.  Making Parent1 a parent of this
% table will add all the primary key fields of Parent1 to the declaration
% and will set up a foreign key from this table to Parent1. 
% 
% See DataJoint.pdf for a more detailed introduction. 
%
% :: Dimitri Yatsenko :: Created 2010-12-28 :: Modified 2011-02-23 ::

assert( nargin>=2, 'missing input argument');
for i=1:length(varargin)
    assert( isa(varargin{i},'DJ'), 'parent classes must be DataJoint objects');
    ddj.parentTables{end+1} = varargin{i};
end