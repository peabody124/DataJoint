import pymysql
import re


class Connection:
    """
    dj.Connection objects link a python package with a database schema
    """

    def __init__(self, host, user, passwd, initFun):
        try:
            host, port = host.split(':')
            port = int(port)
        except ValueError:
            port = 3306
        self.connInfo = dict(host=host, port=port, user=user, passwd=passwd)
        self._conn = pymysql.connect(init_command=initFun, **self.connInfo)
        if self._conn.ping():
            print "Connected", user+'@'+host+':'+str(port)
        self._conn.autocommit(True)
        self.packages = {}

        
    def makeClassName(self, dbname, tableName):
        """
        make a class name from the table name.
        """
        try:
            ret = self.packages[dbname] + '.' + camelCase(tableName)
        except KeyError:
            ret = '$' + dbname + '.' + camelCase(tableName)
        return ret

        
    def __repr__(self):
        connected = "connected" if self._conn.ping() else "disconnected"
        return "DataJoint connection ({connected}) {user}@{host}:{port}".format(
            connected=connected, **self.connInfo)
        

    def __del__(self):
        print 'Disconnecting {user}@{host}:{port}'.format(**self.connInfo)
        self._conn.close()


    def query(self, query, args=()):
        """execute the specified query and return its cursor"""
        cur = self._conn.cursor()
        cur.execute(query, args)
        return cur


    def startTransaction(self):
        self.query('START TRANSACTION WITH CONSISTENT SNAPSHOT')

    
    def cancelTransaction(self):
        self.query('ROLLBACK')


    def commitTransaction(self):
        self.query('COMMIT')



def camelCase(s):
    def toUpper(matchobj):
        return matchobj.group(0)[-1].upper()
    return re.sub('(^|[_\W])+[a-zA-Z]', toUpper, s)

