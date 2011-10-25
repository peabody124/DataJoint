"""
Python 2.7 implementatin of datajoint 
See datajoint.googlecode.com
"""

import pymysql
import re

class DjException(Exception):
    def __init__(self, msg):
        self.msg = msg

    def __str__(self):
        return repr(self.msg)


# table tiers are encoded by naming convention as follows:
tableTiers = {
    '':'manual',      # manual tables have no prefix
    '#':'lookup',     # lookup tables start with a #
    '_':'imported',   # imported tables start with _
    '__':'computed'   # computed tables start with __
    }
tierRe = re.compile('^(|#|_|__)[a-z]\w+$')


def camelCase(s):
    def toUpper(matchobj):
        return matchobj.group(0)[-1].upper()
    return re.sub('(^|[_\W])+[a-zA-Z]', toUpper, s)
    


class Schema(object):
    """
    dj.Schema objects link a python module with a database schema
    """
    connInfo = []
    conn = []
    module = None
    tables = None
    fields = None


    def __init__(self, module, db, user, passwd, 
            host='127.0.0.01', port=3306):
        self.module = module
        self.connInfo = dict(host=host, db=db, user=user, passwd=passwd, port=port)
        print 'Connecting to ' + host
        self.conn = pymysql.connect(**self.connInfo)
        self.reload()


    def __del__(self):
        self.conn.close()


    def __repr__(self):
        if self.module is None:
            str = 'Empty schema'
        else:
            str = 'dj.Schema "%s" -> %s:%s\n(%d tables, %d columns)' \
                % (self.module, self.connInfo['host'],
                self.connInfo['db'], len(self.tables), len(self.fields))
        return str 


    def startTransaction(self):
        cur = self.conn.cursor()
        cur.execute('START TRANSACTION WITH CONSISTENT SNAPSHOT')

    
    def cancelTransaction(self):
        cur = self.conn.cursor()
        cur.execute('ROLLBACK')


    def commitTransaction(self):
        cur = self.conn.cursor()
        cur.execute('COMMIT')


    def reload(self):
        """
            load table definitions and dependencies   
        """
        # load table info
        print 'Loading table info...'
        cur = self.conn.cursor()
        cur.execute('''
            SELECT table_name, table_comment
            FROM information_schema.tables WHERE table_schema="%s" 
            ''' % self.connInfo['db'])

        self.tables = [{
            'name': s[0], 
            'comment': s[1].split('$')[0],
            'tier': tableTiers[tierRe.match(s[0]).group(1)],
            'class': self.module + '.' + camelCase(s[0])
            } for s in cur.fetchall() if tierRe.match(s[0])] 
        self.tableIdx = {k['name']:i for i,k in enumerate(self.tables)}
        self.classIdx = {k['class']:i for i,k in enumerate(self.tables)}

        # load field info
        print 'Loading column info...'
        cur.execute('''
            SELECT table_name, column_name, (column_key="PRI") AS `iskey`,
                column_type, (is_nullable="YES") AS isnullable, 
                column_comment, column_default 
            FROM information_schema.columns 
            WHERE table_schema="%s"
            ''' % self.connInfo['db'])

        self.fields = [{
            'table': s[0],
            'name': s[1],
            'isKey': s[2]!=0,
            'type': s[3],
            'isNullable': s[4]!=0,
            'comment': s[5],
            'default': s[6],
            'isNumeric': None != re.match('^((tiny|small|medium|big)?int|decimal|double|float)', s[3]),
            'isString': None != re.match('^((var)?char|enum|date|timestamp)', s[3]),
            'isBlob': None != re.match('^(tiny|medium|long)?blob', s[3])
        } for s in cur.fetchall() if tierRe.match(s[0])]

        # check for unsupported datatypes
        for s in self.fields:
            if not s['isNumeric'] and not s['isString'] and not s['isBlob']:
                raise DjException('unsupported datatype ' + s['type'])

        # load table dependencies
        print 'Loading table dependencies...'
        tableList = ','.join(['"'+k['name']+'"' for k in self.tables])
        cur.execute(''' 
            SELECT table_name, referenced_table_name, 
                min((table_schema, table_name, column_name) in (
                    SELECT table_schema, table_name, column_name 
                    FROM information_schema.columns WHERE column_key="PRI")) 
                AS parental
            FROM information_schema.key_column_usage 
            WHERE table_schema="%s" AND table_name in (%s) 
            AND referenced_table_schema="%s" AND referenced_table_name in (%s) 
            GROUP BY table_name, referenced_table_name
        ''' % (self.connInfo['db'], tableList, self.connInfo['db'], tableList))

        self.parents = [[] for i in self.tables]
        self.children = [[] for i in self.tables]
        for tuple in cur.fetchall():
            ix = [self.tableIdx[tuple[0]], self.tableIdx[tuple[1]]]
            self.parents[ix[0]].append(ix[1])
            self.children[ix[1]].append(ix[0])

        # determine the hierarchical level of each table
        self.levels = [0]*len(self.tables)
        nextGen = [i for i,par in enumerate(self.parents) if not par]
        depth = 0
        while nextGen:
            depth += 1
            nextGen = reduce((lambda x,y: x+y),
                [self.children[i] for i in nextGen])
            for i in nextGen:
                self.levels[i] = depth



class Table(object):
    """
    dj.Table implements data definition functions
    """
    header = None   # string "module.className(tier) # comment"
    schema = None   # the dj.Schema object to which self belongs
    info = None     # dict with "name", "tier" 
    fields = None   # array of dictionaries with field information
    iTable = None   # index into self.schema.tables

    def __init__(self, declaration=None):

        if declaration:
            # parse declaration
            lines = [s for s in 
                map(lambda x:x.strip(), declaration.split('\n')) 
                if s and s[0]!='#']
            hdr = re.match((
                '^\s*(?P<module>\w+)\.(?P<class>\w+)\s*' # module.ClassName
                '\(\s*(?P<tier>\w+)\s*\)\s*'             # (tier)
                '#\s*(?P<comment>\S.*\S)\s*$'            # comment
                ), lines[0])

            if not hdr:
                raise DjException('invalid table declaration header: '+lines[0])
            self.header = hdr.groupdict()

            exec('import '+self.header['module'])
            self.schema = eval(self.header['module']+'.schema')
            if self.header['tier'] not in tableTiers.values():
                raise DjException('invalid table tier')
            try:
                self.iTable = self.schema.classIdx[
                    self.header['module'] + '.' + self.header['class']]
                self.info = self.schema.tables[self.iTable]
            except KeyError, key:
                raise DjException('Table "%s" not found' % key)

            self.fields = []
            for field in self.schema.fields:
                if camelCase(field['table']) == self.header['class']:
                    self.fields.append(field)


    def __repr__(self):
        s = '\nTable %s.%s(%s) # %s\n\n' % (
            self.header['module'], self.header['class'], 
            self.header['tier'], self.header['comment'])
        inKey = True
        for field in self.fields:
            if inKey:
                inKey = field['isKey']
                if not inKey:
                    s += '---\n'
            if field['default'] == None:
                s += '%-22s:%-20s# %s\n' % \
                    (field['name'], field['type'], field['comment'])
            else:
                default = str(field['default'])
                if field['isString'] and default!="CURRENT_TIMESTAMP":
                    default = '"%s"' % default
                s += '%-22s:%-20s# %s\n' % \
                    (field['name']+'='+default, 
                      field['type'], field['comment'])
        return s

        

class Relvar(object):
    """
    dj.Relvar provides data manipulation functions
    """
    table  = None # corresponding table (in base relvars only)
    schema = None # a Schema object
    fields = None # array of structures defining field properties
    _sqlPro = '*'  # SQL projection clause 
    _sqlSrc = None # SQL source clause
    _sqlRes = []   # list of SQL conditions 


    def __init__(self, *sqlConds, **kwConds):
        # self.table must be defined by derived class
        if isinstance(self.table, Table):
            self.schema = self.table.schema
            self._sqlSrc = '`%s`.`%s`' % (
                self.schema.connInfo['db'], 
                self.table.info['name'])
            self.fields = self.table.fields
            self(*sqlConds, **kwConds)

    def __call__(self, *sqlConds, **kwConds):
        # restrict by multiple conditions
        self.restrict(dict(**kwConds))
        for cond in sqlConds:
            self.restrict(cond)
        return self


    def __repr__(self):
        if self.table is not None:
            s = "Base Relvar "
            s+= str(type(self))
        else:
            s = "Derived Relvar"
        return s+'\n'


    def restrict(self, condition=None):
        """
        in-place restriction by a condition.
        The condition can be an SQL string, a dict with field values, or 
        another relvar.
        """
        if condition is not None:
            try:
                if isinstance(condition, Relvar):
                    # perform semijoin
                    raise DjException('seminjoin not implemented yet')
                elif isinstance(condition, dict):
                    # convert dict to SQL conditions
                    for k, v in condition.iteritems():
                        self._sqlRes += ['%s="%s"' % (k, str(v))]
                else:
                    self._sqlRes += ['(%s)' % condition]
            except:
                print 'Error processing condition ' + str(condition)
                raise


    def fetch(self):
        cur = self.schema.conn.cursor()
        queryStr = 'SELECT %s FROM %s' % (self._sqlPro, self._sqlSrc) 
        if self._sqlRes:
            queryStr+= 'WHERE '+ ' AND '.join(self._sqlRes)
        print 'QUERY: ', queryStr
        cur.execute(queryStr)
        return cur.fetchall()
