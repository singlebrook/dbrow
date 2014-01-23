<cfcomponent extends="dbrow.test.units.abstract_testcase">
<cfscript>

public void function setUp() {
	Super.setUp();
	arthropod = arthropod_factory.create();
}


public void function afterTests() {
	qryService = new Query(datasource = application.datasource);
	qryService.setSQL("truncate tblArthropod;");
	qryService.execute();
	qryService.setSQL("delete from tblSubphylum;");
	qryService.execute();
}


public void function drawPropertyValue_bit() {
	arthropod.venemous = '';
	// Railo and ACF behave differently when YesNoFormat()ing an empty value.
	// ACF returns "No". Railo return "false". Both are falsey, so assert that.
	assert(!arthropod.drawPropertyValue('venemous'));
	arthropod.venemous = true;
	assertEquals('Yes', arthropod.drawPropertyValue('venemous'));
	arthropod.venemous = false;
	assertEquals('No', arthropod.drawPropertyValue('venemous'));
}


public void function drawPropertyValue_foreignkey() {
	var subphylum_factory = CreateObject('support.factories.subphylum_factory');
	var subphylum = subphylum_factory.create();
	arthropod.subphylumID = subphylum.subphylumID;
	var expected = subphylum.subphylum_name;
	var actual = arthropod.drawPropertyValue('subphylumid');
	assertEquals(expected, actual);
}

public void function drawPropertyValue_varchar() {
	var nasty_string = '<script type="text/javascript">alert("gotcha");</script>';
	arthropod.arthropod_name = nasty_string;
	var expected = HTMLEditFormat(nasty_string);
	var actual = arthropod.drawPropertyValue('arthropod_name');
	assertEquals(expected, actual);
}

</cfscript>
</cfcomponent>
