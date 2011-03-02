function setTableComment( this, comment )
% DJ/setTableComment - changes the comment of the specified table.
%
% :: Dimitri Yatsenko :: Created 2010-12-29 :: Modified 2010-12-29 :: 

query( this, sprintf('ALTER TABLE `%s`.`%s` COMMENT "%s$"',this.conn.schema,this.conn.table,comment) );