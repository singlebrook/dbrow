<cfcomponent extends="dbrow.test.units.abstract_testcase">
<cfscript>

public void function beforeTests() {
	arthropod_factory = CreateObject('support.factories.arthropod_factory');
}


public void function setUp() {
	arthropod = arthropod_factory.create();
}


/* This is another brittle, trivial test. It is intended to provide a
modicum of coverage so that we can delegate dbrow3.drawForm() to
dbrow_renderer.drawForm(). -Jared 2012-05-06 */

public void function drawForm() {
	var beginning = '<form action="/index.cfm?method=saveform" method="post" onSubmit="return showErrors(getFormErrors(this), this);" id="';
	var remainder = normalizeWhitespace(Trim(expectedRemainder(arthropod)));
	var actual = normalizeWhitespace(Trim(arthropod.drawForm()));
	assert(actual contains beginning);
	assert(actual contains remainder);
}

</cfscript>


<cffunction name="expectedRemainder" returntype="string" access="private" output="no">
	<cfargument name="arthropod" type="component" required="yes">

	<cfsavecontent variable="local.remainder">
	<cfoutput>
		<input type="hidden" name="goto" value="/index.cfm.cfc?method=list">

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

				<tr>
					<th class="fieldLabel">Subphylumid</th>
					<td><select name="subphylumid" id="subphylumid" tabindex="16383" desc="Subphylumid"><option value=""></option></select><span id="subphylumid_error" class="error hidden"></span></td>
				</tr>

				<tr>
					<th class="fieldLabel">Venemous</th>
					<td>
					<input type="checkbox" name="venemous_checkbox" id="venemous_checkbox" value="1" tabindex="16383" desc="Venemous"  onclick="document.getElementById('venemous').value=this.checked;" />
					<input type="hidden" name="venemous" id="venemous" value="0" />
				<span id="venemous_error" class="error hidden"></span></td>
				</tr>


		<tr>
			<td colspan="2">
				<div class="formsubmit">
				<input type="submit" value="Save" id="submitbutton" tabindex="16383">

					<input type="button" value="Delete" tabindex="16383" onclick="if (confirm('Are you sure?')) document.location='/index.cfm?method=delete&amp;id=#arthropod.arthropodID#';">

				</div>
			</td>
		</tr>

		</table>

		</form>
	</cfoutput>
	</cfsavecontent>
	<cfreturn local.remainder>
</cffunction>

</cfcomponent>
