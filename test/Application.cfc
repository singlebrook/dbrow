<cfcomponent>
<cfscript>
this.name = "TestApplication";
this.sessionmanagement = false;
this.applicationtimeout = CreateTimeSpan(0,0,0,5);

variables.testDir = ReReplace(GetDirectoryFromPath(GetCurrentTemplatePath()), '/?$', '');
variables.dbrowDir = ListDeleteAt(variables.testDir, ListLen(variables.testDir, '/'), '/');

this.mappings = {
	'/dbrow': variables.dbrowDir,
	'/mxunit': variables.testDir & '/mxunit'
}

this.componentPaths = [ testDir ];

this.datasources["dbrow_test"] = {
	class: "org.postgresql.Driver",
	bundleName: "org.postgresql.jdbc",
	bundleVersion: "42.6.0",
	connectionString: "jdbc:postgresql://localhost:5432/dbrow_test",
	username: "dbrow_test",
	password: "derp",
    url: "jdbc:postgresql://localhost:5432/dbrow_test?user=dbrow_test&password=derp",
	dbdriver: "PostgreSql"
};

this.datasource = "dbrow_test";
</cfscript>

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
