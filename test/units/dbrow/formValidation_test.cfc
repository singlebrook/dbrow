<cfcomponent extends="dbrow.test.units.abstract_testcase">
<cfscript>

public void function setUp() {
	arthropod = arthropod_factory.create();
}


public void function drawFormErrorSummary() {
	arthropod.legs = "banana suitcase";
	arthropod.venemous = "cucumber bicycle";
	expected = HTMLEditFormat(normalizeWhitespace(Trim(expectedErrorSummary())));
	actual_raw = arthropod.drawFormErrorSummary(arthropod.getErrorArray());
	actual = HTMLEditFormat(normalizeWhitespace(Trim(actual_raw)));
	assertEquals(expected, actual);
}


public void function drawErrorField() {
	arthropod.legs = "giraffe sundress";
	expected = HTMLEditFormat(normalizeWhitespace(Trim('<span id="legs_error" class="error hidden"></span>')));
	actual = HTMLEditFormat(normalizeWhitespace(Trim(arthropod.drawErrorField('legs'))));
	assertEquals(expected, actual);
}


/* The following five tests depend on application.dbrow3modernValAttrs = true.
There are two other legacy options for validation attributes,
but here we only test the most modern. - Jared 2012-07-06 */
public void function getValidationAttribs_legs() {
	expected = HTMLEditFormat(normalizeWhitespace(Trim('desc="legs" onchange="if (this.value != ' & "''" & ') this.value=math.round(math.pow(10,0) * this.value) / math.pow(10,0);" data-pattern="integer"')));
	actual = HTMLEditFormat(normalizeWhitespace(Trim(arthropod.getValidationAttribs('legs'))));
	assertEquals(expected, actual);
}


public void function getValidationAttribs_arthropodID() {
	expected = HTMLEditFormat(normalizeWhitespace(Trim('desc="arthropodid" data-required="1" onchange="if (this.value != ' & "''" & ') this.value=math.round(math.pow(10,0) * this.value) / math.pow(10,0);" data-pattern="integer"')));
	actual = HTMLEditFormat(normalizeWhitespace(Trim(arthropod.getValidationAttribs('arthropodID'))));
	assertEquals(expected, actual);
}


public void function getValidationAttribs_arthropod_name() {
	expected = HTMLEditFormat(normalizeWhitespace(Trim('desc="creepy crawly" maxlength="50"')));
	actual = HTMLEditFormat(normalizeWhitespace(Trim(arthropod.getValidationAttribs('arthropod_name'))));
	assertEquals(expected, actual);
}


public void function getValidationAttribs_venemous() {
	expected = HTMLEditFormat(normalizeWhitespace(Trim('desc="venemous"')));
	actual = HTMLEditFormat(normalizeWhitespace(Trim(arthropod.getValidationAttribs('venemous'))));
	assertEquals(expected, actual);
}


public void function getValidationAttribs_subphylumID() {
	expected = HTMLEditFormat(normalizeWhitespace(Trim('desc="subphylumid"')));
	actual = HTMLEditFormat(normalizeWhitespace(Trim(arthropod.getValidationAttribs('subphylumID'))));
	assertEquals(expected, actual);
}

</cfscript>

<cffunction name="expectedErrorSummary" access="private" output="no" returntype="string">
	<cfsavecontent variable="local.expected">
		<div class="dbrow-error-summary error"> <span class="dbrow-error-summary-title"> sorry, there is a problem with your form: </span> <ul> <li>legs must be an integer</li> </ul> please fix this problem and resubmit the form. </div>
	</cfsavecontent>
	<cfreturn expected>
</cffunction>

</cfcomponent>
