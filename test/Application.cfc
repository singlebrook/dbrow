<cfcomponent>

<cfset this.name = "TestApplication">
<cfset this.sessionmanagement = false>
<cfset this.applicationtimeout = "#CreateTimeSpan(0,0,0,5)#">

<cffunction name="onApplicationStart">
  <cfset application.datasource = "dbrow_test">
  <cfset application.objectMap = "dbrow.test">
  <cfset application.appRootURL = cgi.server_name>
</cffunction>


<cffunction name="onRequestStart">
<cfscript>
	if (StructKeyExists(URL, "resetApplication")) { onApplicationStart(); }
	request.timeNone = CreateTimeSpan(0, 0, 0, 0);
</cfscript>
</cffunction>

</cfcomponent>
