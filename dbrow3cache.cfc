<cfcomponent name="dbrow3cache">

	<cfif not(isdefined('this.isInited') and this.isInited)>
		<cfset this.init()>
	</cfif>

	<cffunction name="init" returntype="dbrow3cache" output="no">
		<cfset this.stColumnMetaData = structNew()>
		<cfset this.stForeignKeyMetaData = structNew()>
		<cfset this.isInited = 1>
		<cfset this.timeout = 5>

		<cfreturn this>
	</cffunction> <!--- init --->


	<cffunction name="clearAll" returntype="void" output="no">
		<cfset this.init()>
	</cffunction>


	<cffunction name="getColumnMetaData" returntype="struct" output="no" access="public">
		<cfargument name="objectName" type="string" required="yes">

		<cfset var theSt = this.stColumnMetaData>
		<cfset var stResults = structNew()>

		<cfset stResults.hit = 0>
		<cfset stResults.stMetaData = structNew()>

		<cfif structKeyExists(theSt, objectName)>
			<cfif abs(dateDiff('n', theSt[objectName].timestamp, now())) gt this.timeout>
				<cfset structDelete(theSt, objectName)>
			<cfelse>
				<cfset stResults.hit = 1>
				<cfset stResults.stMetaData = theSt[objectName].stMetaData>
			</cfif>
		</cfif>

		<cfreturn stResults>

	</cffunction> <!--- getColumnMetaData --->


	<cffunction name="getForeignKeyMetaData" returntype="struct" output="no" access="public">
		<cfargument name="objectName" type="string" required="yes">

		<cfset var theSt = this.stForeignKeyMetaData>
		<cfset var stResults = structNew()>

		<cfset stResults.hit = 0>
		<cfset stResults.stMetaData = structNew()>

		<cfif structKeyExists(theSt, objectName)>
			<cfif abs(dateDiff('n', theSt[objectName].timestamp, now())) gt this.timeout>
				<cfset structDelete(theSt, objectName)>
			<cfelse>
				<cfset stResults.hit = 1>
				<cfset stResults.stMetaData = theSt[objectName].stMetaData>
			</cfif>
		</cfif>

		<cfreturn stResults>
	</cffunction> <!--- getForeignKeyMetaData --->


	<cffunction name="setColumnMetaData" returntype="void" output="no" access="public">
		<cfargument name="objectName" type="string" required="yes">
		<cfargument name="stMetaData" type="struct" required="yes">

		<cfset theSt = this.stColumnMetaData>

		<cfset theSt[objectName] = structNew()>
		<cfset theSt[objectName].timestamp = now()>
		<cfset theSt[objectName].stMetaData = stMetaData>

	</cffunction> <!--- setColumnMetaData --->


	<cffunction name="setForeignKeyMetaData" returntype="void" output="no" access="public">
		<cfargument name="objectName" type="string" required="yes">
		<cfargument name="stMetaData" type="struct" required="yes">

		<cfset theSt = this.stForeignKeyMetaData>

		<cfset theSt[objectName] = structNew()>
		<cfset theSt[objectName].timestamp = now()>
		<cfset theSt[objectName].stMetaData = stMetaData>

	</cffunction> <!--- setForeignKeyMetaData --->
</cfcomponent>