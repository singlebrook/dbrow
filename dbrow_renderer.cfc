<cfcomponent name="dbrow3renderer">
<cfscript>

public component function init(required component dbrowObj) {
	this.dbrowObj = arguments.dbrowObj;
	return this;
}

</cfscript>


<cffunction name="getLabel" returntype="string" access="public" output="no">
	<cfargument name="propertyname" type="string" required="yes">
	<cfset var label = propertyname>
	<cfif StructKeyExists(this.dbrowObj.stLabel, propertyname)>
		<cfset label = this.dbrowObj.stLabel[propertyname]>
	</cfif>
	<cfreturn label>
</cffunction> <!--- getLabel --->

</cfcomponent>
