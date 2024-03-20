<cfcomponent extends="dbrow.test.units.abstract_testcase">
<cfscript>

public void function setUp() {
	Super.setUp();
	arthropod = arthropod_factory.create();
}


/* The following tests are very brittle because they hardcode the expected
rendered output, including exact whitespace. Furthermore these tests do not
come anywhere near to complete coverage of drawStandardFormField().
-Jared 2012-05-06 */

public void function test_drawStandardFormField_bit() {
	var expected = HTMLEditFormat('<input type="checkbox" name="venemous_checkbox" id="venemous_checkbox" value="1" tabindex="16383" desc="Venemous"  onclick="document.getElementById(''venemous'').value=this.checked;" />
							<input type="hidden" name="venemous" id="venemous" value="0" />
						<span id="venemous_error" class="error hidden"></span>');
	var actual = HTMLEditFormat(Trim(arthropod.drawStandardFormField('venemous')));
	expected = normalizeWhitespace(expected);
	actual = normalizeWhitespace(actual);
	assertEquals(expected, actual);
}


public void function test_drawStandardFormField_foreignKey() {
	var beginning = '<select name="subphylumid" id="subphylumid" tabindex="16383" desc="Subphylumid"><option value=""></option>';
	var end = '</select><span id="subphylumid_error" class="error hidden"></span>';
	var actual = arthropod.drawStandardFormField('subphylumID');
	assert(actual contains beginning);
	assert(actual contains end);
}


public void function test_drawStandardFormField_primaryKey() {
	var expected = '<input type="hidden" name="arthropodid" id="arthropodid" value="' & arthropod.arthropodID & '" /><span id="arthropodid_error" class="error hidden"></span>';
	var actual = arthropod.drawStandardFormField('arthropodID');
	assertEquals(expected, actual);
}


public void function test_drawStandardFormField_varchar() {
	var expected = '<input type="text" size="40" name="arthropod_name" id="arthropod_name" tabindex="16383" value="Honey Bee"  desc="Creepy crawly" maxlength="50" /><span id="arthropod_name_error" class="error hidden"></span>';
	var actual = arthropod.drawStandardFormField('arthropod_name');
	assertEquals(expected, actual);
}

</cfscript>
</cfcomponent>
