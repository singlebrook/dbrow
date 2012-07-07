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

</cfscript>

<cffunction name="expectedErrorSummary" access="private" output="no" returntype="string">
	<cfsavecontent variable="local.expected">
		<div class="dbrow-error-summary error"> <span class="dbrow-error-summary-title"> sorry, there is a problem with your form: </span> <ul> <li>legs must be an integer</li> </ul> please fix this problem and resubmit the form. </div>
	</cfsavecontent>
	<cfreturn expected>
</cffunction>

</cfcomponent>
