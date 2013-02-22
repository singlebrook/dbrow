<cfcomponent extends="dbrow.test.units.abstract_testcase">
<cfscript>

public void function setUp() {
	arthropod = arthropod_factory.create();
}


/* `edit()` is a very brittle test, intended only to support the
delegation of `dbrow3.edit()` to the renderer. - Jared 2012-07-06 */
public void function edit() {
	savecontent variable="actual_raw" { arthropod.edit(arthropod.arthropodID); }
	var actual = HTMLEditFormat(normalizeWhitespace(Trim(actual_raw)));

	var expected_1 = HTMLEditFormat(normalizeWhitespace(Trim('<html> <body> <script type="text/javascript" src="' & cgi.server_name & '/js/formvalidation.js"></script> <div id="')));
	assert(actual contains expected_1);

	var expected_2 = HTMLEditFormat(normalizeWhitespace(Trim('class="dbrow-error-summary error,hidden"> </div> <form action="/index.cfm?method=saveform" method="post" onsubmit="return showerrors(getformerrors(this), this);" id="')));
	assert(actual contains expected_2);

	var expected_3 = HTMLEditFormat(normalizeWhitespace(Trim('<input type="hidden" name="goto" value="/index.cfm?method=list"> <input type="hidden" name="arthropodid" id="arthropodid" value="')));
	assert(actual contains expected_3, "Expected #actual# to contain #expected_3#");

	var expected_4 = HTMLEditFormat(normalizeWhitespace(Trim('</div> </td> </tr> </table> </form> </body> </html>')));
	assert(actual contains expected_4);
}

</cfscript>
</cfcomponent>
