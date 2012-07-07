<cfcomponent extends="dbrow.test.units.abstract_testcase">
<cfscript>

public void function setUp() {
	arthropod = arthropod_factory.create();
}


public void function getDefaultTabIndex() {
	assertEquals(16383, arthropod.getDefaultTabIndex());
}


public void function getTabIndexAttr() {
	var expected = 'tabindex="' & arthropod.getDefaultTabindex() & '"';
	actual = arthropod.getTabIndexAttr('venemous');
	assertEquals(expected, actual);
}


/* `drawForm()` is a very brittle, trivial test. It is only
intended to provide a modicum of coverage so that we can delegate
dbrow3.drawForm() to dbrow_renderer.drawForm(). -Jared 2012-05-06 */

public void function drawForm() {
	var actual = normalizeWhitespace(Trim(arthropod.drawForm()));

	var mkp_beginning = 'method=saveform" method="post" onSubmit="return showErrors(getFormErrors(this), this);" id="';
	assert(actual contains mkp_beginning, "expected #HTMLEditFormat(actual)# to contain #HTMLEditFormat(mkp_beginning)#");

	var mkp_formsubmit = normalizeWhitespace(Trim(expectedField_formsubmit(arthropod)));
	assert(actual contains mkp_formsubmit, "expected #HTMLEditFormat(actual)# to contain #HTMLEditFormat(mkp_formsubmit)#");

	var mkp_subphylumid = normalizeWhitespace(Trim(expectedField_subphylumid()));
	assert(actual contains mkp_subphylumid, "expected #HTMLEditFormat(actual)# to contain #HTMLEditFormat(mkp_subphylumid)#");

	var mkp_venemous = normalizeWhitespace(Trim(expectedField_venemous()));
	assert(actual contains mkp_venemous);

	var mkp_remainder = normalizeWhitespace(Trim(expectedRemainder(arthropod)));
	assert(actual contains mkp_remainder, "expected #HTMLEditFormat(actual)# to contain #HTMLEditFormat(mkp_remainder)#");
}


public void function drawFormEnd() {
	assertEquals('</form>', arthropod.drawFormEnd());
}

</cfscript>


<cffunction name="expectedRemainder" returntype="string" access="private" output="no">
	<cfargument name="arthropod" type="component" required="yes">

	<cfsavecontent variable="local.remainder">
	<cfoutput>
		<input type="hidden" name="arthropodID" id="arthropodID" value="#arthropod.arthropodID#" /><span id="arthropodID_error" class="error hidden"></span>
		<table border="1">
			<tr>
				<th class="fieldLabel">Creepy crawly</th>
				<td><input type="text" size="40" name="arthropod_name" id="arthropod_name" tabindex="16383" value="Honey Bee"  desc="Creepy crawly" maxlength="50" /><span id="arthropod_name_error" class="error hidden"></span></td>
			</tr>
			<tr>
				<th class="fieldLabel">Legs</th>
				<td>Hexapods rule!  Everyone must have 6 legs.</td>
			</tr>
	</cfoutput>
	</cfsavecontent>
	<cfreturn local.remainder>
</cffunction>


<cffunction name="expectedField_formsubmit" returntype="string" access="private" output="no">
	<cfargument name="arthropod" type="component" required="yes">
	<cfsavecontent variable="local.markup">
	<cfoutput>
		<tr>
			<td colspan="2">
				<div class="formsubmit">
				<input type="submit" value="Save" id="submitbutton" tabindex="16383">
	</cfoutput>
	</cfsavecontent>
	<cfreturn local.markup>
</cffunction>


<cffunction name="expectedField_subphylumid" returntype="string" access="private" output="no">
	<cfsavecontent variable="local.markup">
				<tr>
					<th class="fieldLabel">Subphylumid</th>
					<td><select name="subphylumid" id="subphylumid" tabindex="16383" desc="Subphylumid"><option value=""></option></select><span id="subphylumid_error" class="error hidden"></span></td>
				</tr>
	</cfsavecontent>
	<cfreturn local.markup>
</cffunction>


<cffunction name="expectedField_venemous" returntype="string" access="private" output="no">
	<cfsavecontent variable="local.markup">
		<tr>
			<th class="fieldLabel">Venemous</th>
			<td>
			<input type="checkbox" name="venemous_checkbox" id="venemous_checkbox" value="1" tabindex="16383" desc="Venemous"  onclick="document.getElementById('venemous').value=this.checked;" />
			<input type="hidden" name="venemous" id="venemous" value="0" />
		<span id="venemous_error" class="error hidden"></span></td>
		</tr>
	</cfsavecontent>
	<cfreturn local.markup>
</cffunction>

</cfcomponent>
