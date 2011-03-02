function display( this )

fprintf( '\nTABLE %s  ::: CLASS @%s\n', this.tableName, this.className );
fprintf( '\nPARENT TABLES:\n  ' );
str = ''; c = '';
for iParent=1:length( this.parentTables )
    str = [str, c, class(this.parentTables(iParent))];
    c = ',';
end
if isempty(str)
    str = '<none>';
end
fprintf( '%s\n', str );

fprintf('\nADDITIONAL PRIMARY KEY FIELDS:\n');
if isempty(this.addKeyFields)
    fprintf('<none>');
else
    for f=this.addKeyFields
        fprintf( ' %s ::: %s ::: %s \n', f.name, f.type, f.comment );
    end
end

fprintf('\nREGULAR FIELDS:\n');
if isempty(this.nonKeyFields)
    fprintf('<none>');
else
    for f=this.nonKeyFields
        fprintf( ' %s ::: %s ::: %s \n', f.name, f.type, f.comment );
    end
end
fprintf('\n\n');