<cfcomponent extends="dbrow.test.units.abstract_testcase">
<cfscript>

public void function setUp() {
	Super.setUp();
	arthropod = arthropod_factory.create();
}


public void function test_drawFormField_customField() {
	var expected = 'Hexapods rule!  Everyone must have 6 legs.';
	var actual = arthropod.drawFormField('legs');
	assertEquals(expected, actual);
}


public void function test_drawFormField_standardField() {
	var expected = arthropod.drawStandardFormField('venemous');
	var actual = arthropod.drawFormField('venemous');
	assertEquals(expected, actual);
}

</cfscript>
</cfcomponent>
