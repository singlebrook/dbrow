<cfcomponent extends="abstract_testcase">

<cffunction name="can_instantiate" returntype="void" output="no" access="public">
  <cfset obj = CreateObject('arthropod')>
  <cfset assertFalse(obj.isInited)>
  <cfset assertFalse(obj.isInitialized)>
  <cfset assertFalse(obj.isStored)>
</cffunction>


<cffunction name="can_initialize" returntype="void" output="no" access="public">
  <cfset obj = CreateObject('arthropod').init()>
  <cfset assertTrue(obj.isInited)>
  <cfset assertTrue(obj.isInitialized)>
  <cfset assertFalse(obj.isStored)>
</cffunction>

</cfcomponent>
