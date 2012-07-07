<cfcomponent name="dbview3">

<!--- This is a component template. To use it, extend it via an "extends" parameter in your
	cfcomponent tag.

Sample constructor code for use in child component:

	<cfscript>
		// This is the only required field.
		theObject = "User";

		// You may supply these fields as necessary. Otherwise init() will use defaults like the
		// following
		theOrderField = "sortorder";
		theTable = "tblUser";
		theDatasource = "application.datasource";
		bUsesTombstoning = false;

		// Then call
		this.init()
	</cfscript>

This component depends on having the timespans request.timeLong and request.timeNone defined
	for caching purposes.

--->

	<cffunction name="init" returntype="void" access="public"
			hint="This is the new 'constructor' method. ">
		<cfif not(isdefined('theObject'))>
			<cfthrow message="dbview3 requires 'theObject' to be set in the constructor">
		</cfif>
		<cfif not(isdefined('theDatasource') or structKeyExists(application, 'datasource'))>
			<cfthrow message="dbview3 requires 'theDatasource' to be set in the constructor OR that 'application.datasource' exists">
		</cfif>
		<cfparam name="theOrderField" default="sortorder">
		<cfparam name="theTable" default="tbl#theObject#">
		<cfparam name="theDatasource" default="#application.datasource#">
		<cfparam name="theNameField" default="#theObject#_name">
		<cfparam name="bUsesTombstoning" type="boolean" default="false">
		<cfparam name="listViewFieldList" default="#theNameField#">

		<cfset this.initializeObject(theOrderField, theTable, theObject, theDatasource, bUsesTombstoning)>

		<cfset this.theNameField = theNameField>
		<cfset this.listViewFieldList = REReplace(',#listViewFieldList#', ',[[:space:]]+', ',', 'all')>
		<cfif isdefined('theObjectMap')>
			<cfset this.objectMap = theObjectMap>
		<cfelse>
			<cfset this.objectMap = application.objectMap>
		</cfif>

	</cffunction> <!--- init --->


	<cffunction name="initializeObject"
			access="package"
			output="no"
			hint="constructor method">
		<cfargument name="theOrderField"
				type="string"
				required="yes">
		<cfargument name="theTable"
				type="string"
				required="yes">
		<cfargument name="theObject"
				type="string"
				required="yes">
		<cfargument name="theDatasource"
				type="string"
				required="yes">
		<cfargument name="bUsesTombstoning"
				type="boolean"
				required="yes">

		<cfset this.theOrderField = arguments.theOrderField>
		<cfset this.theTable = arguments.theTable>
		<cfset this.theObject = arguments.theObject>
		<cfset this.datasource = arguments.theDatasource>
		<cfset this.bUsesTombstoning = arguments.bUsesTombstoning>

		<cfset this.isInitialized = 1>

	</cffunction> <!--- initializeObject --->


	<cffunction name="checkRemoteMethodAuthorization" returntype="void" output="false" access="public"
			hint="Called by all remote methods.  Override with authorization checks to get access to the methods.">
		<cfthrow type="com.singlebrook.dbrow3.UnauthorizedAccessException" message="Unauthorized access" detail="You are not allowed to access this method">
	</cffunction>


	<cffunction name="getAll" returnType="query" access="remote" output="no">
		<cfargument name="bUseCache" type="boolean" required="no" default="0">
		<cfargument name="asXML" type="boolean" required="no" default="no">
		<cfargument name="filterField" type="string" required="no">
		<cfargument name="filterValue" type="string" required="no">
		<cfargument name="filterSet" type="struct" required="no">
		<cfargument name="includeDeleted" type="boolean" required="no" default="0">

		<!--- Check to make sure the user has permissions --->
		<cfif StructKeyExists( url, "method" )>
			<cfset this.checkRemoteMethodAuthorization() >
		</cfif>

		<cfif (structKeyExists(arguments, 'filterField') or structKeyExists(arguments, 'filterValue'))
				and (not(structKeyExists(arguments, 'filterField')) or not(structKeyExists(arguments, 'filterValue')))>
			<cfthrow message="dbset3.getAll requires both filterField and filterValue if either is passed">
		</cfif>
		<cfif structKeyExists(arguments, 'filterField') and structKeyExists(arguments, 'filterSet')>
			<cfthrow message="dbset3.getAll cannot accept both filterField/filterValue and filterSet">
		</cfif>

		<cfif arguments.asXML>
			<!--- These are necessary for JavaScript's XMLHttpRequest to successfully consume this as a web service --->
			<cfsetting showdebugoutput="no">
			<cfheader name="Content-Type" value="text/xml;charset=utf-8">
		</cfif>

		<cfif bUseCache>
			<cfset cacheTime = request.timeLong>
		<cfelse>
			<cfset cacheTime = request.timeNone>
		</cfif>

		<cfquery name="getSet" datasource="#this.datasource#" cachedwithin="#cacheTime#">
			select *
			from #this.theTable#
			where 1=1
			<cfif structKeyExists(arguments, 'filterField')>
				<cfif LCase( filterValue ) eq "null" >
					and #filterField# is null
				<cfelseif LCase( filterValue ) eq "not null" >
					and #filterField# is not null
				<cfelse>
					and #filterField# in (
						<!--- Version 7 and earlier did not support cfqueryparam in combination with cachedwithin - leon 5/8/08 --->
						<cfif len(filterValue)>
							<cfif REFind("[^\d,\.]", filterValue)>
								#listQualify(filterValue, "'")#
							<cfelse>
								#filterValue#
							</cfif>
						<cfelse>
							null
						</cfif>
					)

				</cfif>
			<cfelseif structKeyExists(arguments, 'filterSet') >
				<cfset v.setKeys = StructKeyList( filterSet ) >
				<cfloop list="#v.setKeys#" index="v.currentKey">
					<cfif LCase( StructFind( filterSet, v.currentKey ) ) eq "null" >
						and #v.currentKey# is null
					<cfelseif LCase( StructFind( filterSet, v.currentKey ) ) eq "not null" >
						and #v.currentKey# is not null
					<cfelse>
						and #v.currentKey# in (
							<!--- Version 7 and earlier did not support cfqueryparam in combination with cachedwithin - leon 5/8/08 --->
							<cfif len(filterSet[v.currentKey])>
								<cfif REFind("[^\d,\.]", filterSet[v.currentKey])>
									#listQualify(filterSet[v.currentKey], "'")#
								<cfelse>
									#filterSet[v.currentKey]#
								</cfif>
							<cfelse>
								null
							</cfif>
						)
					</cfif>
				</cfloop>
			</cfif>
			<cfif this.bUsesTombstoning and not arguments.includeDeleted>
				and deleted = '0'
			</cfif>
			order by #this.theOrderField#
		</cfquery>

		<cfreturn getSet>

	</cffunction> <!--- getAll --->


	<cffunction name="getRelated" returnType="string" output="no" access="public">
		<cfargument name="localKeyField" type="string" required="yes">
		<cfargument name="foreignColumn" type="string" required="yes">

		<!--- Determine foreign object name --->
		<!--- supports obj_id and objid notation - Jared 6/15/07 --->
		<cfset var forObjName = REReplaceNoCase(localKeyField, '_?ID$', '')>

		<!--- create foreign object --->
		<cfset var objForeign = createObject('component', '#this.objectMap#.#forObjName#').init()>

		<!--- get value --->
		<cfset var rsForeign = "">
		<cfquery name="rsForeign" datasource="#this.datasource#" cachedwithin="#request.timeLong#">
			select #arguments.foreignColumn# as foreignColumn
			from #objForeign.theTable#
			where #objForeign.theID# = '#evaluate(arguments.localKeyField)#'
		</cfquery>

		<cfreturn rsForeign.foreignColumn>

	</cffunction> <!--- getRelated --->


	<cffunction name="usesTombstoning" returnType="boolean" access="public" output="no">
		<cfreturn this.bUsesTombstoning >
	</cffunction> <!--- usesTombstoning --->

</cfcomponent>
