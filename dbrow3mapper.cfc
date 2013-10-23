<cfcomponent name="dbrow3mapper">

	<cfscript>
		dbrow3mapperLogging = false;
		lastTick = getTickCount();

		private string function getCacheFilePath() {
			return getTempDirectory() & '/dbrow3mapper_#variables.applicationName#.xml';
		}

		public void function deleteCacheFile() {
			if (FileExists(getCacheFilePath())) {
				FileDelete(getCacheFilePath());
			}
		}
	</cfscript>

	<cffunction name="init" returntype="dbrow3mapper" output="yes" access="public">
		<cfargument name="applicationName" type="string" required="true">
		<cfargument name="useCacheFile" type="boolean" required="true">

		<cfset variables.applicationName = arguments.applicationName>
		<cfset var cacheFile = getCacheFilePath()>
		<cfset var cacheXML = "">

		<!--- Private variables - leon 12/12/07 --->
		<cfset stObjInfo = structNew() />
		<cfset stObjInfo.stTableToObject = structNew()>
		<cfset stObjInfo.stObjectToTable = structNew()>
		<cfset stObjInfo.stObjectToName = structNew()>
		<cfset stObjInfo.stObjectToID = structNew()>
		<cfset stObjInfo.stObjectToPath = structNew()>
		<cfset stObjInfo.rsTypeTable = QueryNew( "tableName,immutableName,id,objPath" ) >

		<!--- Figure out if we should use the cache file instead of instantiating
			all of the objects.

			This is much faster than instantiation, but won't include objects/
			tables created after the cache file was last built. As such, the
			default behavior is to not use the cache file. - leon 2/21/11 --->
		<cfif arguments.useCacheFile AND NOT Len(Trim(variables.applicationName))>
			<cflog type="warning" text="App indicated that dbrow3mapper cache should be used,
				but application.applicationName is not present, so we can't name the cache file and won't use it.">
		</cfif>

		<cfif arguments.useCacheFile and fileExists(cacheFile)>
			<cfset logIt("Reading cache file: #cacheFile#") />
			<cffile action="read" file="#cacheFile#" variable="cacheXML" />

			<cfset logIt('Deserializing stObjInfo from cache XML') />
			<cfwddx action="wddx2cfml" input="#cacheXML#" output="stObjInfo" />

		<cfelse>
			<cfset logIt('Cache file not present or being ignored. Scanning for objects.') />
			<cfset this.scanForObjects()>

			<cfif arguments.useCacheFile>
				<cfset logIt('Serializing stObjInfo scope to XML') />
				<cfwddx action="cfml2wddx" input="#stObjInfo#" output="cacheXML" />

				<cfset logIt('Writing new cache file') />
				<cffile action="write" file="#cacheFile#" output="#cacheXML#" />
			<cfelse>
				<cfset logIt('Not writing new cache file') />
			</cfif>
		</cfif>

		<!--- If scan failed to find any objects, then DB con is probably down - Jared 9/29/08 --->
		<cfif StructCount(stObjInfo.stTableToObject) EQ 0>
			<cfthrow message="The dbrow mapper failed to find any dbrow objects."
				detail="Check your database connection.  (It could be that the objects are there, but dbrow can't get their metatdata.)">
		</cfif>

		<cfreturn this>
	</cffunction> <!--- init --->


	<cffunction name="clearAll" returntype="void" output="no">
		<cfset this.init()>
	</cffunction> <!--- clearAll --->


	<cffunction name="elapsed" returntype="numeric" output="no">
		<cfset var elapsedTime = getTickCount() - lastTick>
		<cfset lastTick = getTickCount()>
		<!--- Convert to seconds - leon 9/27/09 --->
		<cfset elapsedTime = elapsedTime / 1000>
		<!--- Format for display by prepending spaces to get a fixed width. - leon 9/27/09 --->
		<cfset elapsedTime = repeatString(' ', 10 - len(elapsedTime)) & elapsedTime>
		<cfreturn elapsedTime>
	</cffunction> <!--- elapsed --->


	<cffunction name="getFilePathFromObjPath" returntype="string" output="no" access="public">
		<cfargument name="objPath" type="string" required="yes">
		<cfif structKeyExists(stObjInfo.stObjectToPath, objPath)>
			<cfreturn stObjInfo.stObjectToPath[objPath]>
		<cfelse>
			<cfreturn "">
		</cfif>
	</cffunction> <!--- getFilePathFromObjPath --->


	<cffunction name="getIDColFromObjPath" returntype="string" output="no" access="public">
		<cfargument name="objPath" type="string" required="yes">
		<cfif structKeyExists(stObjInfo.stObjectToID, objPath)>
			<cfreturn stObjInfo.stObjectToID[objPath]>
		<cfelse>
			<cfreturn "">
		</cfif>
	</cffunction> <!--- getNameColFromObjPath --->


	<cffunction name="getNameColFromObjPath" returntype="string" output="no" access="public">
		<cfargument name="objPath" type="string" required="yes">
		<cfif structKeyExists(stObjInfo.stObjectToName, objPath)>
			<cfreturn stObjInfo.stObjectToName[objPath]>
		<cfelse>
			<cfreturn "">
		</cfif>
	</cffunction> <!--- getNameColFromObjPath --->


	<cffunction name="getObjPathFromTable" returntype="string" output="no" access="public">
		<cfargument name="tableName" type="string" required="yes">
		<cfif structKeyExists(stObjInfo.stTableToObject, tableName)>
			<cfreturn stObjInfo.stTableToObject[tableName]>
		<cfelse>
			<cfreturn "">
		</cfif>
	</cffunction> <!--- getObjPathFromTable --->


	<cffunction name="getTableFromObjPath" returntype="string" output="no" access="public">
		<cfargument name="objPath" type="string" required="yes">
		<cfif structKeyExists(stObjInfo.stObjectToTable, objPath)>
			<cfreturn stObjInfo.stObjectToTable[objPath]>
		<cfelse>
			<cfreturn "">
		</cfif>
	</cffunction> <!--- getTableFromObjPath --->


	<cffunction name="isChildOfDbrow" returntype="boolean" output="no" access="public">
		<cfargument name="obj" type="any" required="yes" hint="An instantiated CFC">
		<cfset var v = structNew()>

		<cfset v.parentName = getMetaData(obj).extends.name>

		<cfif v.parentName eq "WEB-INF.cftags.component">
			<!--- A regular CFC with no defined parent - leon 5/16/08 --->
			<cfreturn false>
		<cfelseif findNoCase('dbset', v.parentName)>
			<!--- A child of dbset, so not dbrow - leon 9/27/09 --->
			<cfreturn false>
		<cfelseif REFindNoCase('dbrow\d?(_|$)', v.parentName)>
			<!--- A direct descendant of dbrow! - leon 5/16/08 --->
			<cfreturn true>
		<cfelse>
			<cfreturn isChildOfDbrow(createObject('component', v.parentName))>
		</cfif>

		<cfreturn false>
	</cffunction> <!--- isChildOfDbrow --->


	<cffunction name="logIt" returntype="void" output="no">
		<cfargument name="theText" type="string" required="yes">
		<cfif dbrow3mapperLogging>
			<cflog file="dbrow3mapper" text="#elapsed()# #theText#">
		</cfif>
	</cffunction> <!--- logIt --->


	<cffunction name="dbrowChildren" returntype="array" output="no" access="private"
		hint="Returns an array of structs representing the dbrow
			children found under application.objectMap">

		<cfif NOT StructKeyExists(application, 'objectMap')>
			<cfthrow type="com.singlebrook.dbrow3mapper.noObjectMapException"
				message="application.objectMap is not defined, so dbrow3mapper can't scan for objects">
		</cfif>

		<cfset var v = {}>
		<cfset v.pathSep = pathSeparator()>
		<cfset v.basePath = expandPath(v.pathSep & replace(application.objectMap, '.', v.pathSep, 'all'))>

		<cfdirectory action="list"
				directory="#v.basePath#"
				name="v.rsCFCs"
				filter="*.cfc"
				recurse="yes"
				sort="name asc">

		<cfset logIt('Found #v.rsCFCs.RecordCount# CFCs in #v.basePath#')>

		<cfset v.arCFCs = []>
		<cfloop query="v.rsCFCs">

			<!--- Don't try to instantiate dbrow3mapper or you'll have an infinite loop! - leon 12/13/07 --->
			<cfif v.rsCFCs.name NEQ "dbrow3mapper.cfc">

				<cfset v.relativeDir = replace(v.rsCFCs.directory, v.basePath, '')>
				<cfset v.objPath = application.objectMap & replace(v.relativeDir, v.pathSep, '.', 'all') & '.' & REReplace(v.rsCFCs.name, '.cfc$', '')>

				<!--- Does this CFC extend dbrow? --->
				<cftry>
					<cfset v.obj = CreateObject('component', v.objPath)>

					<cfif isChildOfDbrow(v.obj)>
						<cfset ArrayAppend(v.arCFCs, {
							'name' = v.rsCFCs.name,
							'obj' = v.obj,
							'objPath' = v.objPath,
							'relativeDir' = v.relativeDir
						})>
					</cfif>
					<cfcatch type="any">
						<cfset logIt('Error: #v.objPath# #cfcatch.message#')>
					</cfcatch>
				</cftry>
			</cfif>
		</cfloop>

		<cfset logIt('Found #ArrayLen(v.arCFCs)# children of dbrow')>

		<cfreturn v.arCFCs>
	</cffunction>


	<cffunction name="pathSeparator" returntype="string" output="no" access="private">
		<cfif structKeyExists(application, 'pathSeparator')>
			<cfreturn application.pathSeparator>
		<cfelse>
			<cfreturn "/">
		</cfif>
	</cffunction>


	<cffunction name="isRootObject" returntype="boolean" output="no" access="private">
		<cfargument name="obj" type="component" required="yes">
		<cfset var v = {}>

		<cfset v.parentName = getMetaData(arguments.obj).extends.name >
		<cfif v.parentName contains "dbrow3">
			<cfset v.rootObject = true>
		<cfelse>
			<!--- Attempt to instantiate the parent. - leon 9/28/09 --->
			<cftry>
				<cfset v.rootObject = false >
				<cfset v.parentObj = createObject('component', v.parentName).init() >
				<cfcatch>
					<cfset v.rootObject = true >
				</cfcatch>
			</cftry>
		</cfif>

		<cfreturn v.rootObject>
	</cffunction>


	<cffunction name="scanForObjects" returntype="void" output="no" access="public"
			hint="Looks for dbrow3-based objects in application.objectMap and
			populates private data structures with their information.">
		<cfset var v = structNew()>

		<cfset v.arCFCs = dbrowChildren()>
		<cfset v.pathSep = pathSeparator()>
		<cfset v.stDbrowObjects = structnew()>

		<cfloop array="#v.arCFCs#" index="stCFC">

			<cfset logIt('Is #stCFC.name# a root object? (has abstract parent)')>
			<cfset v.rootObject = isRootObject(stCFC.obj)>

			<!--- This is not the root of the inheritance tree, skip adding it - dave 12/3/08 --->
			<cfif not v.rootObject>
				<cfset v.isTypeObj = false >

				<cfset logIt('Calling init() on #stCFC.objPath#')>
				<cfset stCFC.obj.init()>
				<cfset logIt('Done calling init() on #stCFC.objPath#')>


				<!--- See if the object has values for theImmutableNameField and theImmutableNameFieldValue.
					If it does, it most likely is a type object referencing only one row of the table. - dave 12/3/08 --->
				<cfif isDefined( "stCFC.obj.theImmutableNameField" )
						and stCFC.obj.theImmutableNameField neq ""
						and isDefined( "stCFC.obj.theImmutableNameFieldValue" )
						and stCFC.obj.theImmutableNameFieldValue neq "" >

					<cfset v.loadSuccess = stCFC.obj.loadBy( filterField = stCFC.obj.theImmutableNameField, filterValue = stCFC.obj.theImmutableNameFieldValue ) >
					<!--- if the object loads then the appropriate record was found in the database, store the type information - dave 12/3/08 --->

					<cfif v.loadSuccess >
						<cfset QueryAddRow( stObjInfo.rsTypeTable ) >
						<!--- tableName,immutableName,id,objPath --->
						<cfset QuerySetCell( stObjInfo.rsTypeTable, "tableName", stCFC.obj.theTable ) >
						<cfset QuerySetCell( stObjInfo.rsTypeTable, "immutableName", stCFC.obj.theImmutableNameFieldValue ) >
						<cfset QuerySetCell( stObjInfo.rsTypeTable, "id", evaluate( "stCFC.obj.#stCFC.obj.theID#" ) ) >
						<cfset QuerySetCell( stObjInfo.rsTypeTable, "objPath", stCFC.objPath ) >
					</cfif>
				</cfif>
			<cfelse>
				<!--- This is the root of the inheritance tree, add it to the mapping - dave 12/3/08 --->
				<cftry>
					<!--- Read in all relevant data about the object - leon 12/13/07 --->
					<cfset logIt('Calling init() on #stCFC.objPath#')>
					<cfset stCFC.obj.init()>
					<cfset logIt('Done calling init() on #stCFC.objPath#')>
					<cfset v.stObjData = structNew()>
					<cfset v.stObjData.extends = getMetaData(stCFC.obj).extends.name>
					<cfset v.stObjData.table = stCFC.obj.getTableName()>
					<cfset v.stObjData.idCol = stCFC.obj.getIDColumn()>
					<cfset v.stObjData.nameCol = stCFC.obj.getNameColumn()>
					<cfif StructKeyExists( application, "objectURL" ) >
						<cfset v.stObjData.filePath = application.objectURL & stCFC.relativeDir & v.pathSep & stCFC.name >
					</cfif>
					<cfset v.stDbrowObjects[stCFC.objPath] = v.stObjData>
					<cfcatch type="any">
						<cfset logIt("Error: #stCFC.objPath# #cfcatch.message#")>
					</cfcatch>
				</cftry>
			</cfif>

			<cfset logIt('DONE processing #stCFC.objPath#')>

		</cfloop>

		<!--- Now that we have all of the dbrow-based objects, build up our mappings - leon 12/13/07 --->
		<cfloop collection="#v.stDbrowObjects#" item="v.objPath">
			<cfset v.stObj = v.stDbrowObjects[v.objPath]>
			<cfset stObjInfo.stTableToObject[v.stObj.table] = v.objPath>
			<cfset stObjInfo.stObjectToTable[v.objPath] = v.stObj.table>
			<cfif structKeyExists(v.stObj, 'nameCol')>
				<cfset stObjInfo.stObjectToName[v.objPath] = v.stObj.nameCol>
			</cfif>
			<cfset stObjInfo.stObjectToID[v.objPath] = v.stObj.IDCol>
			<cfif StructKeyExists( v.stObj, "filePath" ) >
				<cfset stObjInfo.stObjectToPath[v.objPath] = v.stObj.filePath>
			</cfif>
		</cfloop>

	</cffunction> <!--- scanForObjects --->


	<cffunction name="getTypeObj" returntype="string" output="no" access="public"
			hint="Returns the object path of an object with a specific table and either a specific id or immutable name.">
		<cfargument name="tableName" type="string" required="yes">
		<cfargument name="id" type="string" required="no" default="">
		<cfargument name="immutableName" type="string" required="no" default="">

		<cfset var rsTypeTable = "" />

		<cfif ( Len( Trim( arguments.id ) ) and Len( Trim( arguments.immutableName ) ) )
				or ( not( Len( Trim( arguments.id ) ) ) and not( Len( Trim( arguments.immutableName ) ) ) ) >
			<cfthrow message="Exactly one of id or immutableName must be passed to dbrowmapper.getTypeObj">
		</cfif>

		<!--- Can't use dots in table names in QoQ - Leon --->
		<cfset rsTypeTable = stObjInfo.rsTypeTable />
		<cfquery name="rsObjType" dbtype="query">
			SELECT * FROM rsTypeTable WHERE
			tableName = <cfqueryparam value="#tableName#" cfsqltype="cf_sql_varchar"> AND
			(
				id = <cfqueryparam value="#id#" cfsqltype="cf_sql_varchar"> OR
				immutableName = <cfqueryparam value="#immutableName#" cfsqltype="cf_sql_varchar">
			)
		</cfquery>

		<cfif rsObjType.RecordCount eq 0 >
			<cfthrow message="No type object was found for table '#tableName#', id '#id#', and immutableName '#immutableName#'">
		<cfelseif rsObjType.RecordCount gt 1 >
			<cfthrow message="More than one type object was found for table '#tableName#', id '#id#', and immutableName '#immutableName#'">
		</cfif>

		<cfreturn rsObjType.objPath >
	</cffunction>


</cfcomponent>
