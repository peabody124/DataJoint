function obj = ToySchema( tableName, varargin )
% ToySchema - root relation class for the Vis2p schema. 
% Pass this object to DeclareDJ to declare tables that belong to the
% schema.
%
% Define the connection information in the global variable GLOBAL_TOY_CONNECTION as follows:
%
%       global GLOBAL_TOY_CONNECTION
%       GLOBAL_TOY_CONNECTION = struct(...
%           'host'  , '<server address>',...
%           'schema', '<your schema name>',...
%           'user'  , '<your user name>',...
%           'pass'  , '<your password>');
%
% :: Dimitri Yatsenko :: Created 2011-02-16 :: Modified 2011-02-16 ::

global GLOBAL_TOY_CONNECTION   % define this variable in your startup.m
assert( ~isempty(GLOBAL_TOY_CONNECTION), 'specify connection info in GLOBAL_TOY_CONNECTION');
    
conn = GLOBAL_TOY_CONNECTION;  % must include fields 'host','user','pass','schema'
conn.table  = '';
conn.schemaClass = mfilename;
if nargin>0
    assert( nargin>=1 && ischar(tableName), 'Invalid table or view name' );
    conn.table = tableName;
end

obj = class( struct, 'ToySchema', DJ(conn,varargin{:}) ); 