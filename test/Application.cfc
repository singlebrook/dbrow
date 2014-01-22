<cfcomponent>

<cfset this.name = "TestApplication">
<cfset this.sessionmanagement = false>
<cfset this.applicationtimeout = "#CreateTimeSpan(0,0,0,5)#">

<cfset this.mappings.dbrow = ExpandPath('..')>
<cfset this.mappings.mxunit = ExpandPath('./mxunit')>

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


<cffunction name="onRequestStart">
<cfscript>
	if (StructKeyExists(URL, "resetApplication")) { onApplicationStart(); }
	request.timeNone = CreateTimeSpan(0, 0, 0, 0);
</cfscript>
</cffunction>

</cfcomponent>
