%% ToyMice
ddj=DeclareDJ(ToySchema,'ToyMice','manual');
ddj=addKeyField(ddj,'mouse_id','smallint unsigned','Unique id (0-65535)');

ddj=addField(ddj,'mouse_strain','enum("C57BL6/J","agouti")','strain of mouse','C57BL6/J');
ddj=addField(ddj,'mouse_dob','date','mouse date of birth');
ddj=addField(ddj,'mouse_sex','enum("F","M","unknown")','');
ddj=addField(ddj,'mouse_notes','varchar(1023)','free-text info about the mouse','');

dj=execute(ddj);
setTableComment(ToyMice,'Mouse information');


%% ToyMouseMeasurements
ddj = DeclareDJ(ToySchema,'ToyMouseMeasurements','manual');
ddj = addParent(ddj,ToyMice);
ddj = addField(ddj,'weigh_date','date','date on which mouse was weighed');
ddj = addField(ddj,'mass','float','(g) mass in grams');

dj = execute(ddj);
setTableComment( ToyMouseMeasurements, 'mouse weights by date' );


%% ToyMouseCraniotomies
ddj = DeclareDJ(ToySchema,'ToyMouseCraniotomies','manual');
ddj = addParent(ddj,ToyMouseMeasurements);
ddj = addField(ddj,'craniotomy_side','enum("left","right")','' );

dj = execute(ddj);
setTableComment( ToyMouseCraniotomies, 'Craniotomies performed on mice (one per mouse per date)' );


%% ToyMouseAges
ddj = DeclareDJ(ToySchema,'ToyMouseAges','computed');
ddj = addParent(ddj,ToyMouseMeasurements);
ddj = addField(ddj,'pdays','smallint','postnatal day');

dj = execute(ddj);
setTableComment( ToyMouseAges, 'the ages of the mice in days on days of measurements' );