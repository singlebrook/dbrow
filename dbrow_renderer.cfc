<cfcomponent name="dbrow3renderer">
<cfscript>

public component function init(required component dbrowObj) {
	this.dbrowObj = arguments.dbrowObj;
	return this;
}

</cfscript>


<cffunction name="drawPropertyValue" returnType="string" output="no" access="public">
	<cfargument name="propertyname" type="string" required="yes">

	<cfset var formField = "">
	<cfset var stMD = this.dbrowObj.stColMetaData[arguments.propertyname]>
	<cfset var foreignColumn = "">
	<cfset var foreignTable = "">
	<cfset var foreignNameColumn = "">
	<cfset var foreignObjPath = "">
	<cfset var objForeign = "">

	<cfif structKeyExists(this.dbrowObj.stFKMetaData, arguments.propertyname)>
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
			<cfset objForeign = createObject('component', '#this.dbrowObj.objectMap#.#lcase(REReplaceNoCase(foreignColumn, '_?ID$', ''))#').init()>
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

		<cfset v.objForeign = createObject('component', '#foreignObjPath#').new()>

		<cfset v.objForeign.load( this.dbrowObj[arguments.propertyname] ) >

		<cfset formField = evaluate( "v.objForeign.#foreignNameColumn#" ) >

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
			<!--- <cfcase value="binary">
				<cfset formField = '<input type="file" name="#arguments.propertyname#" id="#arguments.propertyname#" #this.dbrowObj.getValidationAttribs(arguments.propertyname)# />'>
			</cfcase> --->
			<cfdefaultcase>
				<cfthrow message="dbrow3.drawPropertyValue() doesn't know how to handle the datatype '#stMD.datatype#'">
			</cfdefaultcase>
		</cfswitch>
	</cfif>
	<cfreturn formField >
</cffunction>


<cffunction name="getLabel" returntype="string" access="public" output="no">
	<cfargument name="propertyname" type="string" required="yes">
	<cfset var label = propertyname>
	<cfif StructKeyExists(this.dbrowObj.stLabel, propertyname)>
		<cfset label = this.dbrowObj.stLabel[propertyname]>
	</cfif>
	<cfreturn label>
</cffunction>

</cfcomponent>
