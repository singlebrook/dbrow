<cfcomponent> 

<cfset this.name = "TestApplication"> 
<cfset this.sessionmanagement = false>
<cfset this.applicationtimeout = "#CreateTimeSpan(0,0,0,5)#">  

<cffunction name="onApplicationStart">
  <cfset application.datasource = "dbrow_test">
  <cfset application.objectMap = "dbrow.test">
</cffunction>

<cffunction name="onRequestStart">
  <cfif StructKeyExists(URL, "resetApplication")>
    <cfset onApplicationStart()>
  </cfif>
</cffunction>
 
</cfcomponent>
