<cfcomponent extends="dbrow.dbrow3_pgsql">
<cfscript>

	theObject = "arthropod";
	theFieldsToSkip = "arthropodID";
	setLabel('arthropod_name', 'Creepy crawly');
	setField('legs', 'Hexapods rule!  Everyone must have 6 legs.');

</cfscript>
</cfcomponent>
