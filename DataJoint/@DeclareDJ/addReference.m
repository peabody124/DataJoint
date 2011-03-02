function ddj = addReference( ddj, referencedClass, default )
% DeclareDJ/addReference - see help DeclareDJ
% :: Dimitri Yatsenko :: Created 2011-01-28 :: Modified 2011-01-06 ::

if nargin <=2 
    default = struct([]);
end
assert( isa( referencedClass, 'DJ' ), 'referencedClass must be a DJ table' );
ddj.references{end+1} = referencedClass;
ddj.refDefaults{end+1} = default;