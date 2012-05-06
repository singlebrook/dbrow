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
