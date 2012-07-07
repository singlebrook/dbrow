<cfcomponent>
<cfscript>

/*
The `dbrow_renderer` currently is the *delegate* for a dozen methods
in `dbrow3`. These methods are concerned with presentation,
specifically HTML forms. In future versions of the base dbrow class,
these delegated methods may be deprecated, or this delegate
(`dbrow_renderer`) could become a decorator, or these methods could
be removed from the dbrow api entirely. - Jared 2012-07-06

FIELD LABELS
By default, field labels will be created from the property name by
- replacing underscores with spaces
- uppercasing the first letter of each word
You can override the default labels with setLabel(propertyname, label).
e.g. setLabel('address1', 'Street Address');

FORM FIELDS
You may override the default form field for a property. You can use
evaluate(de("##varname##")) to put CF vars into the field contents
at runtime.
e.g. setField('address1', '<textarea name="blah" />');
*/

public component function init(required component dbrowObj) {
	this.dbrowObj = arguments.dbrowObj;
	this.stCustomField = {};
	initValAttrPatterns();
	return this;
}

</cfscript>


<cffunction name="drawErrorField" returnType="string" output="no" access="public">
	<cfargument name="propertyname" type="string" required="yes">
	<cfargument name="errorText" type="string" required="no" default="">
	<cfargument name="identifierPrefix" type="string" required="no" default="">

	<cfreturn '<span id="' & arguments.identifierPrefix & propertyname & '_error" class="error#iif(len(errorText), de(''), de(' hidden'))#">#errorText#</span>'>
</cffunction>


<cffunction name="drawFormErrorSummary" returnType="string" output="no" access="public">
	<cfargument name="arErrors" type="array" required="yes"
		hint="Array of validation errors. See getErrorArray().">
	<cfargument name="formID" type="string" required="no">

	<cfset var summary = "">
	<cfset var divIdAttr = "">
	<cfset var divClassList = "dbrow-error-summary error">

	<cfif StructKeyExists(arguments, "formID")>
		<cfset divIdAttr = 'id' & '="' & formID & '"_error'>
	</cfif>
	<cfif NOT ArrayLen(arguments.arErrors)>
		<cfset divClassList = ListAppend(divClassList, "hidden")>
	</cfif>

	<cfsavecontent variable="summary">
		<cfoutput>
			<div #divIdAttr# class="#divClassList#">
				<cfif arrayLen(arErrors)>
					<span class="dbrow-error-summary-title">
						Sorry, there is a problem with your form:
					</span>
					<ul>
						<cfloop from="1" to="#arrayLen(arErrors)#" index="i">
							<li>#arErrors[i].propertyLabel# #arErrors[i].errorText#</li>
						</cfloop>
					</ul>
					Please fix <cfif arrayLen(arErrors) eq 1>this<cfelse>these</cfif>
					problem<cfif arrayLen(arErrors) neq 1>s</cfif> and resubmit the form.
				</cfif>
			</div>
		</cfoutput>
	</cfsavecontent>

	<cfreturn summary>
</cffunction> <!--- drawFormErrorSummary --->


<cffunction name="drawForm" returnType="string" output="no" access="public">
	<cfargument name="handlerScript" type="string" required="no" default="#cgi.script_name#?method=saveform">
	<cfargument name="bIncludeValScript" type="boolean" required="no" default="0">
	<cfargument name="jsIncludePath" type="string" required="no" default="/js/">
	<cfargument name="goto" type="string" required="no" default="#replace(cgi.script_name, '.cfc', '_set.cfc')#.cfc?method=list">
	<cfargument name="deleteLink" type="string" required="no" default="#cgi.script_name#?method=delete">
	<cfargument name="showDeleteButton" type="boolean" required="no" default="Yes">
	<cfargument name="arErrors" type="array" required="no" default="#arrayNew(1)#" hint="Array of validation errors. See getErrorArray().">
	<cfargument name="fieldList" type="string" required="no">

	<cfset var theFormHTML = "">
	<cfset var v = structNew()>

	<cfif arguments.bIncludeValScript and not(len(arguments.jsIncludePath))>
		<cfthrow message="dbrow3.drawForm() requires jsIncludePath if bIncludeValScript is true">
	</cfif>

	<cfif find('?', deleteLink)>
		<cfset deleteLink = deleteLink & "&amp;">
	<cfelse>
		<cfset deleteLink = deleteLink & "?">
	</cfif>

	<!--- Use arguments.fieldList to override the typical property list - Jared 1/19/09 --->
	<cfif StructKeyExists(arguments,"fieldList")>
		<cfset v.fieldList = arguments.fieldList>
	<cfelse>
		<cfset v.fieldList = this.dbrowObj.propertyList>
	</cfif>

	<cfsavecontent variable="theFormHTML">
		<cfoutput>
		#this.dbrowObj.drawFormStart(argumentCollection = arguments)#

		<input type="hidden" name="goto" value="#HTMLEditFormat(arguments.goto)#">

		#this.dbrowObj.drawFormField(this.dbrowObj.theID)#

		<table border="1">

		<cfloop list="#v.fieldList#" index="i">
			<cfset v.stError = this.dbrowObj.getError(arErrors, i)>
			<cfset v.errorMsg = trim(v.stError.propertyLabel & " " & v.stError.errorText)>

			<cfif listFindNoCase(this.dbrowObj.hiddenFieldList, i)>
				<input type="hidden" name="#i#" id="#i#" value="#HTMLEditFormat(this.dbrowObj[i])#">
			<cfelseif i neq this.dbrowObj.theID and not(listFindNoCase(this.dbrowObj.theFieldsToSkip, i))>
				<tr>
					<th class="fieldLabel">#this.getLabel(i)#</th>
					<td>#this.dbrowObj.drawFormField(i, v.errorMsg)#</td>
				</tr>
			</cfif>
		</cfloop>

		<cfloop list="#structKeyList(this.dbrowObj.stMany)#" index="i">
			<cfif structKeyExists(this.dbrowObj.stLabel, i) and structKeyExists(this.stCustomField, i)>
				<tr>
					<th class="fieldLabel">#this.getLabel(i)#</th>
					<td>#this.dbrowObj.drawFormField(i, v.errorMsg)#</td>
				</tr>
			</cfif>
		</cfloop>

		<tr>
			<td colspan="2">
				<div class="formsubmit">
				<input type="submit" value="Save" id="submitbutton" #this.dbrowObj.getTabindexAttr('submitbutton')#>
				<cfif this.dbrowObj.isStored and arguments.showDeleteButton>
					<input type="button" value="Delete" #this.dbrowObj.getTabindexAttr('submitbutton')# onclick="if (confirm('Are you sure?')) document.location='#deleteLink#id=#this.dbrowObj[this.dbrowObj.theID]#';">
				</cfif>
				</div>
			</td>
		</tr>

		</table>

		#this.dbrowObj.drawFormEnd()#
		</cfoutput>
	</cfsavecontent>

	<cfreturn theFormHTML>

</cffunction> <!--- drawForm --->


<cffunction name="drawFormEnd" returnType="string" output="no" access="public">
	<cfreturn "</form>">
</cffunction>


<cffunction name="drawFormField" returnType="string" output="no" access="public">
	<cfargument name="propertyname" type="string" required="yes">
	<cfargument name="errorText" type="string" required="no" default="">
	<cfargument name="identifierPrefix" type="string" required="no" default="">
	<cfargument name="appendErrorSpan" type="boolean" required="no" default="yes">
	<cfargument name="filterField" type="string" required="no">
	<cfargument name="filterValue" type="string" required="no">
	<cfargument name="filterSet" type="struct" required="no">

	<cfset var formField = "">

	<!--- If a custom form field has been defined for this property .. - leon 2/18/06 --->
	<cfif StructKeyExists(this.stCustomField, arguments.propertyname)>
		<cfset formField = Evaluate(DE(this.stCustomField[arguments.propertyname]))>
	<cfelse>
		<cfset formField = drawStandardFormField(argumentCollection = arguments)>
	</cfif>

	<cfreturn formField>
</cffunction>


<cffunction name="drawFormStart" returnType="string" output="no" access="public">
	<cfargument name="handlerScript" type="string" required="no" default="">
	<cfargument name="bIncludeValScript" type="boolean" required="no" default="0">
	<cfargument name="jsIncludePath" type="string" required="no" default="/js/">
	<cfargument name="arErrors" type="array" required="no" default="#arrayNew(1)#" hint="Array of validation errors. See getErrorArray().">

	<cfset var formStartHTML = "">
	<cfset var formID = Replace(CreateUUID(), '-', '', 'all')>

	<cfsavecontent variable="formStartHTML">
		<cfoutput>

		<cfif arguments.bIncludeValScript>
			<script type="text/javascript" src="#arguments.jsIncludePath#formvalidation.js"></script>
		</cfif>

		#drawFormErrorSummary(arguments.arErrors, formID)#

		<form action="#arguments.handlerScript#" method="post" onSubmit="return showErrors(getFormErrors(this), this);" id="#formID#"
			<cfif Len(this.dbrowObj.binaryFieldList)>
				enctype="multipart/form-data"
			</cfif>
		>

		</cfoutput>
	</cfsavecontent>

	<cfreturn formStartHTML>
</cffunction>


<cffunction name="drawPropertyValue" returnType="string" output="no" access="public">
	<cfargument name="propertyname" type="string" required="yes">

	<cfscript>
		var formField = "";
		var stMD = this.dbrowObj.stColMetaData[arguments.propertyname];
		var isForeignKey = structKeyExists(this.dbrowObj.stFKMetaData, arguments.propertyname);
	</cfscript>

	<cfif isForeignKey>
		<cfset var objForeign = getOneAssociatedModel(arguments.propertyname)>
		<cfset objForeign.load( this.dbrowObj[arguments.propertyname] )>
		<cfset var foreignNameColumn = objForeign.theNameField>
		<cfset formField = objForeign[foreignNameColumn]>

	<cfelse>

		<cfswitch expression="#stMD.datatype#">
			<cfcase value="bigint,char,date,decimal,float,integer,smallint,time,timestamp,uuid,varchar" delimiters=",">
				<cfif arguments.propertyname contains "password">
					<cfset formField = "(hidden)">
				<cfelse>
					<cfset formField = HTMLEditFormat(this.dbrowObj[arguments.propertyname]) >
				</cfif>
			</cfcase>
			<cfcase value="bit">
				<cfset formField = YesNoFormat( this.dbrowObj[arguments.propertyname] ) >
			</cfcase>
			<cfdefaultcase>
				<cfthrow message="dbrow3.drawPropertyValue() doesn't know how to handle the datatype '#stMD.datatype#'">
			</cfdefaultcase>
		</cfswitch>
	</cfif>
	<cfreturn formField >
</cffunction>


<cffunction name="drawStandardFormField" returnType="string" output="no" access="public">
	<cfargument name="propertyname" type="string" required="yes">
	<cfargument name="errorText" type="string" required="no" default="">
	<cfargument name="identifierPrefix" type="string" required="no" default="">
	<cfargument name="appendErrorSpan" type="boolean" required="no" default="yes">
	<cfargument name="filterField" type="string" required="no">
	<cfargument name="filterValue" type="string" required="no">
	<cfargument name="filterSet" type="struct" required="no">
	<cfargument name="drawEmptyOption" type="boolean" required="no" default="yes" hint="controls the presence of empty (aka default) option on selects">

	<cfset var formField = "">
	<cfset var stMD = "">
	<cfset var foreignColumn = "">
	<cfset var foreignTable = "">
	<cfset var foreignNameColumn = "">
	<cfset var foreignObjPath = "">
	<cfset var objForeign = "">
	<cfset var rsForeignObjects = "">
	<cfset var fieldType = "">
	<cfset var foundMatch = 0>
	<cfset var fieldClass = "">
	<cfset var size = "">
	<cfset var foreignObjArguments = StructNew() >

	<cfif arguments.propertyname eq this.dbrowObj.theID>
		<!--- You shouldn't ever need to manually edit a PK field - leon 2/7/06 --->
		<cfset formField = '<input type="hidden" name="#arguments.identifierPrefix##arguments.propertyname#" id="#arguments.identifierPrefix##arguments.propertyname#" value="#HTMLEditFormat(this.dbrowObj[arguments.propertyname])#" />'>

	<cfelseif structKeyExists(this.dbrowObj.stFKMetaData, arguments.propertyname)>
		<!--- This is a foreign key field. Load up a set of the related items and draw a dropdown. - leon 2/7/06 --->
		<cfset foreignColumn = this.dbrowObj.stFKMetaData[arguments.propertyname].foreignColumn>
		<cfset foreignTable = this.dbrowObj.stFKMetaData[arguments.propertyname].foreignTable>

		<!--- BEGIN - Figure out the name column in the foreign table and the right path for instantiating the foreign object - leon 12/13/07 --->
		<!--- First try to get the name column from the mapper - leon 12/13/07 --->
		<cfif structKeyExists(application, 'dbrow3mapper')>
			<cfset foreignObjPath = application.dbrow3mapper.getObjPathFromTable(foreignTable)>
			<cfif len(foreignObjPath)>
				<cfset foreignNameColumn = application.dbrow3mapper.getNameColFromObjPath(foreignObjPath)>
			</cfif>
		</cfif>
		<!--- If we couldn't get the name column from the mapper, guess at the foreign object name and try to get it from there - leon 12/13/07 --->
		<cfif not(len(foreignNameColumn))>
			<cfset foreignNameGuess = LCase(REReplaceNoCase(foreignColumn, '_?ID$', ''))>
			<cfif NOT len(foreignNameGuess)>
				<cfthrow message="Unable to draw dropdown menu for '#arguments.propertyname#' (see exception details)"
				detail="Unable to guess foreign object name.  You probably added a foreign key constraint, but forgot to create a dbrow object for that foreign table">
			</cfif>
			<cfset objForeign = createObject('component', '#this.dbrowObj.objectMap#.#foreignNameGuess#').init()>
			<cfset foreignNameColumn = objForeign.theNameField>
		</cfif>
		<cfif not(len(foreignNameColumn))>
			<cfthrow message="Could not determine name column in foreign key table.">
		</cfif>

		<cfif not(len(foreignObjPath))>
			<!--- We didn't get a foreignObjPath from the mapper, so guess at it. - leon 12/13/07 --->
			<cfset foreignObjPath = this.dbrowObj.objectMap & "." & REReplaceNoCase(foreignColumn, '_?id$', '')>
		</cfif>
		<!--- END - Figure out the name column in the foreign table and the right path for instantiating the foreign object - leon 12/13/07 --->

		<cfif StructKeyExists( arguments, "filterSet" ) >
			<cfset foreignObjArguments["filterSet"] = arguments.filterSet >
		<cfelseif StructKeyExists( arguments, "filterField" ) and StructKeyExists( arguments, "filterValue" )>
			<cfset foreignObjArguments["filterField"] = arguments.filterField >
			<cfset foreignObjArguments["filterValue"] = arguments.filterValue >
		</cfif>

		<cfinvoke component="#foreignObjPath#_set"
				method="getAll"
				returnVariable="rsForeignObjects"
				argumentCollection="#foreignObjArguments#" >

		<cfset formField = '<select name="#arguments.identifierPrefix##arguments.propertyname#" id="#arguments.identifierPrefix##arguments.propertyname#" #this.dbrowObj.getTabIndexAttr(arguments.propertyname)# #this.dbrowObj.getValidationAttribs(arguments.propertyname)#>'>
		<cfif arguments.drawEmptyOption>
			<cfset formField = formField & '<option value=""></option>'>
		</cfif>
		<cfif not(len(this.dbrowObj[arguments.propertyname]))>
			<cfset foundMatch = 1>
		</cfif>
		<cfoutput query="rsForeignObjects">
			<cfset formField = formField & '<option value="#rsForeignObjects[foreignColumn][currentRow]#"'>
			<cfif not(foundMatch) and rsForeignObjects[foreignColumn][currentRow] eq this.dbrowObj[arguments.propertyname]>
				<cfset foundMatch = 1>
				<cfset formField = formField & ' selected '>
			</cfif>
			<cfset formField = formField & '>#rsForeignObjects[foreignNameColumn][currentRow]#</option>'>
		</cfoutput>
		<cfset formField = formField & '</select>'>

	<cfelse>

		<cfset stMD = this.dbrowObj.stColMetaData[arguments.propertyname]>
		<cfswitch expression="#stMD.datatype#">
			<cfcase value="bigint,char,date,decimal,float,integer,smallint,time,timestamp,varchar" delimiters=",">
				<cfif (not(val(stMD.maxLen)) and stMD.datatype eq "varchar") or (stMD.maxLen gte 300)>
					<cfset formField = '<textarea rows="4" cols="50" name="#arguments.identifierPrefix##arguments.propertyname#" id="#arguments.identifierPrefix##arguments.propertyname#" #this.dbrowObj.getTabIndexAttr(arguments.propertyname)# #this.dbrowObj.getValidationAttribs(arguments.propertyname)#>#this.dbrowObj[arguments.propertyname]#</textarea>'>
				<cfelse>
					<cfif arguments.propertyname contains "password">
						<cfset fieldType = "password">
					<cfelse>
						<cfset fieldType = "text">
					</cfif>
					<cfif val(stMD.maxLen) and stMD.maxLen gte 50>
						<cfset size="40">
					<cfelse>
						<cfset size="20">
					</cfif>
					<cfif listFindNoCase('date,timestamp', stMD.datatype)>
						<cfset fieldClass = 'class="date"'>
					<cfelse>
						<cfset fieldClass = "">
					</cfif>
					<cfset formField = '<input type="#fieldType#" size="#size#" name="#arguments.identifierPrefix##arguments.propertyname#" id="#arguments.identifierPrefix##arguments.propertyname#" #this.dbrowObj.getTabIndexAttr(arguments.propertyname)# value="#HTMLEditFormat(this.dbrowObj[arguments.propertyname])#" #fieldClass# #this.dbrowObj.getValidationAttribs(arguments.propertyname)# />'>
				</cfif>
			</cfcase>
			<cfcase value="other">
				<cfset formField = '<input type="hidden" name="#arguments.identifierPrefix##arguments.propertyname#" id="#arguments.identifierPrefix##arguments.propertyname#" value="#HTMLEditFormat(this.dbrowObj[arguments.propertyname])#" />'>
			</cfcase>
			<cfcase value="bit">
				<cfset formField = '
						<input type="checkbox" name="#arguments.identifierPrefix##arguments.propertyname#_checkbox" id="#arguments.identifierPrefix##arguments.propertyname#_checkbox" value="1" #this.dbrowObj.getTabIndexAttr(arguments.propertyname)# #this.dbrowObj.getValidationAttribs(arguments.propertyname)# #iif(len(this.dbrowObj[arguments.propertyname]) and this.dbrowObj[arguments.propertyname], de("checked"), de(""))# onclick="document.getElementById(''#arguments.propertyname#'').value=this.checked;" />
						<input type="hidden" name="#arguments.identifierPrefix##arguments.propertyname#" id="#arguments.identifierPrefix##arguments.propertyname#" value="#iif(len(this.dbrowObj[arguments.propertyname]) and this.dbrowObj[arguments.propertyname], 1, 0)#" />
					'>
			</cfcase>
			<cfcase value="binary">
				<cfset formField = '<input type="file" name="#arguments.identifierPrefix##arguments.propertyname#" id="#arguments.identifierPrefix##arguments.propertyname#" #this.dbrowObj.getTabIndexAttr(arguments.propertyname)# #this.dbrowObj.getValidationAttribs(arguments.propertyname)# />'>
			</cfcase>
			<cfdefaultcase>
				<cfthrow message="dbrow3.drawFormField() doesn't know how to handle the datatype '#stMD.datatype#'">
			</cfdefaultcase>
		</cfswitch>

	</cfif>

	<!--- We often want to display validation errors in a span to the right of the form field.
	But not always!  So I have added this boolean argument appendErrorSpan - Jared 12/22/08 --->
	<cfif arguments.appendErrorSpan>
		<cfset formField = formField & this.dbrowObj.drawErrorField( propertyname = arguments.propertyname, errorText = arguments.errorText, identifierPrefix = arguments.identifierPrefix ) >
	</cfif>

	<cfreturn formField>

</cffunction> <!--- drawStandardFormField --->


<cffunction name="edit" returnType="void" output="yes" access="remote">
	<cfargument name="id" required="yes">
	<cfargument name="goto" type="string" required="no" default="#replace(cgi.script_name, '.cfc', '_set.cfc')#?method=list">
	<cfargument name="arErrors" type="array" required="no" default="#arrayNew(1)#" hint="Array of validation errors. See getErrorArray().">
	<cfargument name="stValues" type="struct" required="no" default="#structNew()#" hint="Previously submitted values to use instead of stored ones.">

	<!--- Check to make sure the user has permissions --->
	<cfif StructKeyExists( url, "method" ) and url.method eq "edit">
		<cfset this.dbrowObj.checkRemoteMethodAuthorization() >
	</cfif>

	<cfif len(id)>
		<cfset this.dbrowObj.load(id)>
	<cfelse>
		<cfset this.dbrowObj.new()>
	</cfif>

	<!--- Override existing values with submitted ones. This usually happens in an error condition and you want
		to redisplay what the user entered, not what is stored. - leon 12/9/08 --->
	<cfif not(structIsEmpty(stValues))>
		<cfset this.dbrowObj.loadStruct(stValues)>
	</cfif>

	<cfoutput>

	<html>
		<body>
			<!--- We used to check if the _content_header.cfm file existed with
				fileExists(), but expandPath() doesn't understand CF mappings on Windows,
				so we can't do it that way. - leon 3/28/07 --->
			<cftry>
				<cfinclude template="/#replace(this.dbrowObj.objectMap, '.', '/', 'all')#/../include/_content_header.cfm">
				<cfcatch type="any" />
			</cftry>
			#drawForm(bIncludeValScript = 1, jsIncludePath = '#application.appRootURL##iif(right(application.appRootURL,1) eq '/', de(''), de('/'))#js/', goto = arguments.goto, arErrors = arErrors)#
			<cfif 0>
				DEBUG<br />
				<cfdump var="#this.dbrowObj.stMany#">
				<cfloop collection="#this.dbrowObj.stMany#" item="v.i">
					#v.i#: #getManyRelatedIDs(v.i)#<br />
				</cfloop>
				<cfdump var="#this.dbrowObj.stMany#">
			</cfif>
		</body>
	</html>

	</cfoutput>
</cffunction> <!--- edit --->


<!--- `getDefaultTabIndex` - It is useful to specify a default
tabindex for all form elements. If form elements are drawn without a
tabindex, it is difficult for custom fields (or non-dbrow fields) to
override the tabindex. I have chosen the default value of 16383
because it is halfway through the valid tabindex range, allowing
overrriding either above or below the default. I have implemented
this default as a method to allow child classes to override it.
-Jared 5/25/11 --->
<cffunction name="getDefaultTabIndex" returnType="numeric" output="no" access="public">
	<cfreturn 16383>
</cffunction>


<cffunction name="getLabel" returntype="string" access="public" output="no">
	<cfargument name="propertyname" type="string" required="yes">
	<cfset var label = propertyname>
	<cfif StructKeyExists(this.dbrowObj.stLabel, propertyname)>
		<cfset label = this.dbrowObj.stLabel[propertyname]>
	</cfif>
	<cfreturn label>
</cffunction>


<cffunction name="getOneAssociatedModel" returntype="component"
	access="private" output="no" hint="Given the name of a foreign
		key column, return the associated model instance.">
	<cfargument name="propertyname" type="string" required="yes">

	<cfset var foreignObjPath = "">

	<!--- First try to get it from the mapper - leon 12/13/07 --->
	<cfif StructKeyExists(application, 'dbrow3mapper')>
		<cfset var foreignTable = this.dbrowObj.stFKMetaData[arguments.propertyname].foreignTable>
		<cfset foreignObjPath = application.dbrow3mapper.getObjPathFromTable(foreignTable)>
	</cfif>

	<!--- If we didn't get a foreignObjPath from the mapper, guess at it. - leon 12/13/07 --->
	<cfif NOT Len(foreignObjPath)>
		<cfset var foreignColumn = this.dbrowObj.stFKMetaData[arguments.propertyname].foreignColumn>
		<cfset foreignObjPath = this.dbrowObj.objectMap & "." & REReplaceNoCase(foreignColumn, '_?id$', '')>
	</cfif>

	<cfreturn CreateObject('component', '#foreignObjPath#').new()>
</cffunction>


<cffunction name="getTabIndexAttr" returntype="string" output="no" access="public">
	<cfargument name="propertyname" type="string" required="yes">
	<cfreturn 'tabindex="' & this.getDefaultTabindex() & '"'>
</cffunction>


<cffunction name="getValidationAttribs" returntype="string" access="public" output="no"
		hint="Returns attributes to be used in form field tag. These attributes are processed by
			formvalidation.js .">
	<cfargument name="propertyname" type="string" required="yes">

	<cfset var arAttribs = arrayNew(1)>
	<cfset var stMD = this.dbrowObj.stColMetaData[arguments.propertyname]>
	<cfset var isFK = 0>

	<!--- Put column label into attribs. Error messages will automatically be constructed using
		the label. - leon 2/4/06 --->
	<cfset arrayAppend(arAttribs, 'desc="#getLabel(arguments.propertyname)#"')>

	<cfif structKeyExists(this.dbrowObj.stFKMetaData, arguments.propertyname)>
		<cfset isFK = 1>
	</cfif>

	<cfif stMD.notNull>
		<cfif isFK>
			<!--- This is a foreign key field, and will be drawn as a dropdown. Dropdowns require
				"disallowEmptyValue" instead of "required". - leon 2/7/06 --->
			<cfset arrayAppend(arAttribs, 'disallowEmptyValue="1"')>
		<cfelse>
			<cfset arrayAppend(arAttribs, '#this.valAttr_required#="1"')>
		</cfif>
	</cfif>

	<cfif not(isFK)>

		<cfif val(stMD.maxLen)>
			<cfset arrayAppend(arAttribs, 'maxlength="#stMD.maxLen#"')>
		</cfif>

		<!--- Add number formatting support for decimal places. This isn't really validation, but it
				is a form of data cleaning. - leon 2/4/06 --->
		<cfif len(stMD.decimalPlaces)>
			<cfset arrayAppend(arAttribs, 'onChange="if (this.value != '''') this.value=Math.round(Math.pow(10,#val(stMD.decimalPlaces)#) * this.value) / Math.pow(10,#val(stMD.decimalPlaces)#);"')>
		</cfif>

		<cfswitch expression="#stMD.datatype#">
			<!--- ALL: char,bigint,integer,bit,binary,date,float,decimal,varchar,time,timestamp - leon 2/4/06 --->
			<!--- LEFT: char,bit,binary,other,varchar - don't think these need validation for now. - leon 2/4/06 --->
			<cfcase value="float,decimal" delimiters=",">
				<cfset arrayAppend(arAttribs, '#this.valAttr_pattern#="numeric"')>
			</cfcase>
			<cfcase value="integer,bigint" delimiters=",">
				<cfset arrayAppend(arAttribs, '#this.valAttr_pattern#="integer"')>
			</cfcase>
			<cfcase value="date,timestamp" delimiters=",">
				<cfset arrayAppend(arAttribs, '#this.valAttr_pattern#="datetime"')>
			</cfcase>
			<cfcase value="time">
				<cfset arrayAppend(arAttribs, '#this.valAttr_pattern#="time"')>
			</cfcase>
			<cfcase value="char,varchar">
				<cfif arguments.propertyname contains "email" >
					<cfset arrayAppend(arAttribs, '#this.valAttr_pattern#="email"')>
				</cfif>
			</cfcase>
		</cfswitch>

		<!--- Check custom rules - leon 12/11/08 --->
		<cfif structKeyExists(this.dbrowObj.stCustomValidation, propertyname)>
			<cfset v.arRules = this.dbrowObj.stCustomValidation[propertyname]>
			<cfloop from="1" to="#arrayLen(v.arRules)#" index="v.i">
				<cfset v.stRule = v.arRules[v.i]>
				<cfif len(v.stRule.regex)>
					<cfif not(REFind(v.stRule.regex, this[propertyname]))>
						<cfset arrayAppend(arAttribs, '#this.valAttr_pattern#="/#v.stRule.regex#/"')>
						<cfset arrayAppend(arAttribs, 'patternError="#getLabel(propertyname)# #v.stRule.errorText#"')>
					</cfif>
				</cfif>
			</cfloop>
		</cfif>
	</cfif>

	<cfreturn arrayToList(arAttribs, ' ')>
</cffunction> <!--- getValidationAttribs --->


<cffunction name="setField" returntype="void" access="public"
		hint="Override default form fields. Custom fields can include
			the standard fields with drawStandardFormField(propertyname).">
	<cfargument name="propertyname" type="string" required="yes">
	<cfargument name="formfield" type="string" required="yes">
	<cfargument name="escapePoundsigns" type="boolean" required="no" default="no">

	<cfset var formFieldHtml = arguments.formfield>

	<!--- Use the escapePoundsigns argument to double-up the poundsigns in
	arugments.formfield. This prevents CF syntax errors when
	drawFormField() calls evaluate().  This is useful when your custom form
	field contains user input with poundsigns. Example: A custom field with
	a WYSIWYG editor. (The user input stored in the database may have
	poundsigns, especially if the pasted from Word) - Jared 2/3/11 --->
	<cfif arguments.escapePoundsigns>
		<cfset formFieldHtml = REReplace(arguments.formfield, '##', '####', 'all')>
	</cfif>

	<!--- Add or replace this custom form field --->
	<cfset this.stCustomField[arguments.propertyname] = formFieldHtml>
</cffunction>


<cfscript>

public void function setLabel(required string propertyname, required string label) {
	if (NOT StructKeyExists(this.dbrowObj, 'stLabel')) {
		this.dbrowObj.stLabel = {};
	}
	this.dbrowObj.stLabel[arguments.propertyname] = arguments.label;
}


/* Private Methods */


/* `initValAttrPatterns()` determines which set of validation
attribute names to use for form inputs. There are three options:
1. Modern custom attributes, per HTML5 specs. Use these by setting
	application.dbrow3modernValAttrs = true.
2. Transitional attributes, implemented after original attributes
	caused problems, but before we knew about data- "namespace" for
	custom attributes. Use these by setting
	application.dbrow3legacyValAttrs = false.
3. Legacy attribute names (default). These cause problems in
	browsers that support HTML5 form validations. Use these by not
	setting either of the application vars mentioned above.
- leon 3/09/11 */
private void function initValAttrPatterns() {
	if (NOT StructKeyExists(this, 'valAttr_pattern')) {
		if (StructKeyExists(application, 'dbrow3modernValAttrs') and application.dbrow3modernValAttrs) {
			this.valAttr_pattern = "data-pattern";
			this.valAttr_required = "data-required";
		}
		else if (StructKeyExists(application, 'dbrow3legacyValAttrs') and not(application.dbrow3legacyValAttrs)) {
			this.valAttr_pattern = "val_pattern";
			this.valAttr_required = "val_required";
		}
		else {
			this.valAttr_pattern = "pattern";
			this.valAttr_required = "required";
		}
	}
}

</cfscript>

</cfcomponent>
