function s = renameField( s, fieldName, newName )

[s.(newName)] = deal( s.(fieldName) );
s = rmfield( s, fieldName );
