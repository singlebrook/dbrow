<cfcomponent>

<cfset this.name = "TestApplication">
<cfset this.sessionmanagement = false>
<cfset this.applicationtimeout = "#CreateTimeSpan(0,0,0,5)#">

<cfset testDir = GetDirectoryFromPath(GetCurrentTemplatePath())>
<cfset dbrowDir = ListDeleteAt(testDir, ListLen(testDir, '/'), '/')>

<cfset this.mappings['dbrow'] = dbrowDir>
<cfset this.mappings['mxunit'] = testDir & '/mxunit'>

<cfset this.componentPaths = [ testDir ]>

<cfset this.datasources.dbrow_test = {
	class: 'org.postgresql.Driver',
	connectionString: 'jdbc:postgresql://localhost:5432/dbrow_test?user=dbrow_test&password=derp'
}>

<cffunction name="onApplicationStart">
	<cflock scope="application" throwOnTimeout="yes" timeout="1">
		<cfset application.datasource = "dbrow_test">
		<cfset application.objectMap = "dbrow.test">
		<cfset application.appRootURL = cgi.server_name>

		<!--- By setting dbrow3modernValAttrs to true, we are deciding
		to test only the most modern of the three options for validation
		attributes on form input tags. - Jared 2012-07-06 --->
		<cfset application.dbrow3modernValAttrs = true>
	</cflock>
</cffunction>


<cffunction name="onRequestStart" output="true">
<cfscript>
	if (StructKeyExists(URL, "resetApplication")) { onApplicationStart(); }
	request.timeNone = CreateTimeSpan(0, 0, 0, 0);
</cfscript>
<!DOCTYPE html>
<html>
<body>
</cffunction>

<cffunction name="onRequestEnd" output="true">
</body>
</html>
</cffunction>

</cfcomponent>
