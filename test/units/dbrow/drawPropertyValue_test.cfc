<cfcomponent extends="dbrow.test.units.abstract_testcase">
<cfscript>

	public void function beforeTests() {
		arthropod_factory = CreateObject('support.factories.arthropod_factory');
	}


	public void function setUp() {
		arthropod = arthropod_factory.create();
	}


	public void function drawPropertyValue_bit() {
		arthropod.venemous = '';
		assertEquals('No', arthropod.drawPropertyValue('venemous'));
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