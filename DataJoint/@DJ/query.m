function ret=query( dj, queryStr, varargin )
% ret = query( dj, queryStr, varargin ) -- issue an SQL query to the database and
% return the result.
%
% :: Dimitri Yatsenko :: Created 2009-10-07 :: Updated 2010-11-02 ::

global GLOBAL_DJ_CONNECTION_HANDLE
if isempty(GLOBAL_DJ_CONNECTION_HANDLE) || 0<mym(GLOBAL_DJ_CONNECTION_HANDLE,'status')
    GLOBAL_DJ_CONNECTION_HANDLE=mym('open',dj.conn.host,dj.conn.user,dj.conn.pass);
end
if nargout>0
    ret=mym(GLOBAL_DJ_CONNECTION_HANDLE,queryStr,varargin{:});
else
    mym(GLOBAL_DJ_CONNECTION_HANDLE,queryStr,varargin{:});
end