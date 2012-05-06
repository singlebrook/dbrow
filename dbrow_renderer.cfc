<cfcomponent name="dbrow3renderer">
<cfscript>

public component function init(required component dbrowObj) {
	this.dbrowObj = arguments.dbrowObj;
	return this;
}

</cfscript>


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


<cfscript>

public void function setLabel(required string propertyname, required string label) {
	if (NOT StructKeyExists(this.dbrowObj, 'stLabel')) {
		this.dbrowObj.stLabel = {};
	}
	this.dbrowObj.stLabel[arguments.propertyname] = arguments.label;
}

</cfscript>

</cfcomponent>
