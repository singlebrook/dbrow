<cfcomponent name="dbset3">

<!--- This is a component template. To use it, extend it via an "extends" parameter in your
	cfcomponent tag.

Sample constructor code for use in child component:

	<cfscript>
		// This is the only required field.
		theObject = "User";

		// You may supply these fields as necessary. Otherwise init() will use defaults like the
		// following
		theID = "userID";
		theOrderField = "sortorder";
		theTable = "tblUser";
		theDatasource = "application.datasource";

		// Then call
		this.init()
	</cfscript>

--->

	<cffunction name="init" returntype="void" access="public"
			hint="This is the new 'constructor' method. ">
		<cfif not(isdefined('theObject'))>
			<cfthrow message="dbset3 requires 'theObject' to be set in the constructor">
		</cfif>
		<cfif not(isdefined('theDatasource') or structKeyExists(application, 'datasource'))>
			<cfthrow message="dbset3 requires 'theDatasource' to be set in the constructor OR that 'application.datasource' exists">
		</cfif>
		<cfif not(isdefined('theObjectMap') or structKeyExists(application, 'objectMap'))>
			<cfthrow message="dbset3 requires 'theObjectMap' to be set in the constructor OR that 'application.objectMap' exists">
		</cfif>

		<cfparam name="theID" default="#theObject#ID">
		<cfparam name="theOrderField" default="sortorder">
		<cfparam name="theTable" default="tbl#theObject#">
		<cfparam name="theDatasource" default="#application.datasource#">
		<cfparam name="theNameField" default="#theObject#_name">
		<cfparam name="listViewFieldList" default="#theNameField#">

		<cfset initializeObject(theID, theOrderField, theTable, theObject, theDatasource)>

		<cfset this.theNameField = theNameField>
		<cfset this.listViewFieldList = REReplace(',#listViewFieldList#', ',[[:space:]]+', ',', 'all')>
		<cfif isdefined('theObjectMap')>
			<cfset this.objectMap = theObjectMap>
		<cfelse>
			<cfset this.objectMap = application.objectMap>
		</cfif>

		<cfscript>
			/* Define cache timespans.  Do not depend on request.timeLong
			to be defined. - Jared 2013 */
			this.timeLong = StructKeyExists(request, "timeLong") ? request.timeLong : cacheTimeoutDefault();
			this.timeNone = StructKeyExists(request, "timeNone") ? request.timeNone : CreateTimeSpan(0,0,0,0);
		</cfscript>

	</cffunction> <!--- init --->


	<cffunction name="initializeObject"
			access="package"
			output="no"
			hint="constructor method">
		<cfargument name="theID"
				type="string"
				required="yes">
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

		<cfset this.theID = arguments.theID>
		<cfset this.theOrderField = arguments.theOrderField>
		<cfset this.theTable = arguments.theTable>
		<cfset this.theObject = arguments.theObject>
		<cfset this.datasource = arguments.theDatasource>

		<cfset this.isInitialized = 1>

	</cffunction> <!--- initializeObject --->


	<!--- Railo/Lucee wants "timestamp" as the returntype. ACF wants "date". Just make it "any"
		so it works with both. --->
	<cffunction name="cacheTimeoutDefault" returntype="any" output="no" access="public"
			hint="See dbrow3.cacheTimeoutDefault()">
		<cfreturn CreateTimeSpan(0,2,0,0)>
	</cffunction>


	<cffunction name="checkRemoteMethodAuthorization" returntype="void" output="false" access="public"
			hint="Called by all remote methods.  Override with authorization checks to get access to the methods.">
		<cfthrow type="com.singlebrook.dbrow3.UnauthorizedAccessException" message="Unauthorized access" detail="You are not allowed to access this method">
	</cffunction>


	<cffunction name="getAll" returnType="query" access="remote" output="no"
			hint="filterValue and values in filterSet can use * as a wildcard">
		<cfargument name="bUseCache" type="boolean" required="no" default="0">
		<cfargument name="asXML" type="boolean" required="no" default="no">
		<cfargument name="filterField" type="string" required="no">
		<cfargument name="filterValue" type="string" required="no">
		<cfargument name="filterSet" type="struct" required="no" default="#structNew()#">
		<cfargument name="IDOnly" type="boolean" required="no" default="no" hint="Load IDs only">
		<cfargument name="includeDeleted" type="boolean" required="no" default="0">
		<cfargument name="orderBy" type="string" required="no" default="#this.theOrderField#">
		<cfargument name="limit" type="numeric" required="no">
		<cfargument name="offset" type="numeric" required="no">

		<cfset var objObj = "" >
		<cfset var cacheTime = "">
		<cfset var valueIsNull = 0>

		<!--- Check to make sure the user has permissions --->
		<cfif StructKeyExists( url, "method" ) and url.method eq "getAll">
			<cfset this.checkRemoteMethodAuthorization() >
		</cfif>

		<cfif structKeyExists(arguments, 'filterField') xor structKeyExists(arguments, 'filterValue')>
			<cfthrow message="dbset3.getAll requires both filterField and filterValue if either is passed">
		</cfif>

		<cfif structKeyExists(arguments, 'filterField') and structKeyExists(arguments.filterSet, filterField)>
			<cfthrow message="filterField #filterField# was also specified as a key of filterSet. This is not acceptable.">
		</cfif>

		<cfif structKeyExists( arguments, 'filterField' ) or not(structIsEmpty(arguments.filterSet)) >
			<cfset objObj = this.getDbrowObj() >
		</cfif>


		<cfif arguments.asXML>
			<!--- These are necessary for JavaScript's XMLHttpRequest to successfully consume this as a web service --->
			<cfsetting showdebugoutput="no">
			<cfheader name="Content-Type" value="text/xml;charset=utf-8">
		</cfif>

		<cfif bUseCache>
			<cfset cacheTime = this.timeLong>
		<cfelse>
			<cfset cacheTime = this.timeNone>
		</cfif>

		<!--- Roll filterField and filterValue in filterSet so we can just deal with the latter. - leon 6/3/08 --->
		<cfif structKeyExists(arguments, 'filterField')>
			<cfset filterSet[filterField] = filterValue>
		</cfif>

		<cfquery name="getSet" datasource="#this.datasource#" cachedwithin="#cacheTime#">
			select <cfif IDOnly>#this.theID#<cfelse>*</cfif>
			from #this.theTable#
			where 1=1
			<cfset v.setKeys = StructKeyList( filterSet ) >
			<cfloop list="#v.setKeys#" index="v.currentKey">
				<cfif LCase( StructFind( filterSet, v.currentKey ) ) eq "null" >
					and #v.currentKey# is null
				<cfelseif LCase( StructFind( filterSet, v.currentKey ) ) eq "not null" >
					and #v.currentKey# is not null
				<cfelse>
					<cfif filterSet[v.currentKey] contains "*">
						<!--- Use LIKE instead of IN for wildcard support - leon 6/3/08 --->
						and (1=0
							<cfloop list="#filterSet[v.currentKey]#" index="v.currentValue">
								<cfif objObj.stColMetaData[v.currentKey].datatype eq "varchar" and objObj.caseSensitiveComparisons()>
									or lower(#v.currentKey#) like
								<cfelse>
									or #v.currentKey# like
								</cfif>
								<cfset valueIsNull = iif(len(filterSet[v.currentKey]),0,1)>
								<cfqueryparam value="#lcase(replace(v.currentValue, '*', '%', 'all'))#" null="#valueIsNull#" cfsqltype="cf_sql_#objObj.stColMetaData[v.currentKey].datatype#" list="#NOT valueIsNull#">
							</cfloop>
						)
					<cfelse>
						and
							<cfif objObj.stColMetaData[v.currentKey].datatype eq "varchar" and objObj.caseSensitiveComparisons()>
								lower(#v.currentKey#) in
							<cfelse>
								#v.currentKey# in
							</cfif>
							(
							<cfset valueIsNull = iif(len(filterSet[v.currentKey]),0,1)>
							<cfqueryparam value="#lcase(filterSet[v.currentKey])#" null="#valueIsNull#" cfsqltype="cf_sql_#objObj.stColMetaData[v.currentKey].datatype#" list="#NOT valueIsNull#">
						)
					</cfif>
				</cfif>
			</cfloop>

			<cfif this.usesTombstoning() and not arguments.includeDeleted>
				and deleted = '0'
			</cfif>
			order by #orderBy#

			<!--- LIMIT/OFFSET --->
			<cfif useOffsetFetchSyntax()>
				<cfif arguments.keyExists('offset')>
					offset <cfqueryparam value="#arguments.offset#" cfsqltype="cf_sql_integer"> rows
					<cfif arguments.keyExists('limit')>
						fetch first <cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer"> rows only
					</cfif>
				<cfelseif arguments.keyExists('limit')>
					<cfthrow message="`limit` argument is not supported without `offset` in MS SQL Server">
				</cfif>
			<cfelse>
				<cfif arguments.keyExists('limit')>
					limit <cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer">
				</cfif>
				<cfif arguments.keyExists('offset')>
					offset <cfqueryparam value="#arguments.offset#" cfsqltype="cf_sql_integer">
				</cfif>
			</cfif>

		</cfquery>

		<cfreturn getSet>

	</cffunction> <!--- getAll --->


	<cffunction name="getAllArray" returntype="array" output="no" access="public">
		<!--- Same arguments as getAll() - leon 5/8/08 --->

		<cfreturn getDbrowObj().queryToArray(this.getAll(argumentCollection = arguments))>

	</cffunction> <!--- getAllArray --->


	<cffunction name="getDbrowObj" returnType="Any" access="package" output="yes">
		<cfset var theObjectPath = "#this.objectMap#.#theObject#">

		<!--- <cflog text="getDbrowObj()"> - leon 9/25/09 --->

		<cfif not(structKeyExists(this, 'dbrowObj'))>

			<!--- <cflog text="this.dbrowObj doesn't exist yet"> - leon 9/25/09 --->

			<!--- If the dbrow3mapper singleton exists, it takes precedence for theObjectPath - Jared 12/13/07 --->
			<cfif structKeyExists(application, 'dbrow3mapper')>
				<!--- <cflog text="Found dbrow3mapper"> - leon 9/25/09 --->
				<cfif len(application.dbrow3mapper.getObjPathFromTable(this.theTable))>
					<!--- <cflog text="dbrow3mapper knows about table #this.theTable#"> - leon 7/2/10 --->
					<cfset theObjectPath = application.dbrow3mapper.getObjPathFromTable(this.theTable)>
				<cfelse>
					<!--- <cflog text="dbrow3mapper doesn't know about table #this.theTable#"> - leon 7/2/10 --->
				</cfif>
			</cfif>

			<!--- <cflog text="theObjectPath is #theObjectPath#"> - leon 9/25/09 --->

			<!--- Instantiate based on theObjectPath - Jared 12/13/07 --->
			<cfset this.dbrowObj = createObject('component', '#theObjectPath#').init() >

		</cfif>
		<cfreturn this.dbrowObj >
	</cffunction> <!--- getDbrowObj --->


	<cffunction name="getRelated" returnType="string" output="no" access="public">
		<cfargument name="localKeyField" type="string" required="yes">
		<cfargument name="foreignColumn" type="string" required="yes">

		<cfset var v = structNew()>

		<cfset v.dbrowObj = getDbrowObj().load(#evaluate(theID)#)>
		<cfreturn v.dbrowObj.drawPropertyValue(localKeyField)>

	</cffunction> <!--- getRelated --->


	<cffunction name="list" returntype="void" output="yes" access="remote">
		<cfargument name="filterField" type="string" required="no">
		<cfargument name="filterValue" type="string" required="no">
		<cfargument name="showNewObjLink" type="boolean" required="no" default="yes">
		<cfargument name="editLink" type="string" required="no">
		<cfargument name="deleteLink" type="string" required="no">
		<cfargument name="rsObjects" type="query" required="no"
				hint="You can pass in your own set of objects instead of using the filters">
		<cfargument name="showTotals" type="boolean" required="no" default="false">
		<cfargument name="goto" type="string" required="no">


		<cfset var objObj = this.getDbrowObj() >

		<!--- Check to make sure the user has permissions --->
		<cfif StructKeyExists( url, "method" ) and url.method eq "list">
			<cfset this.checkRemoteMethodAuthorization() >
		</cfif>


		<!--- Figure out where edit/delete functionality lives if not specified - leon 7/1/08 --->
		<cfif not(structKeyExists(arguments, 'editLink') and structKeyExists(arguments, 'deleteLink'))>
			<cfif structKeyExists(application, 'dbrow3mapper') and
					len(application.dbrow3mapper.getObjPathFromTable(this.theTable)) >
				<!--- Use the dbrow mapper to determine the file location - dave 7/7/08 --->
				<cfset v.objPath = application.dbrow3mapper.getObjPathFromTable(this.theTable)>
				<cfset v.pathName = application.dbrow3mapper.getFilePathFromObjPath( v.objPath ) >
			<cfelseif structKeyExists(application, 'objectURL')>
				<cfset v.pathName = "#application.objectURL#/#theObject#.cfc">
			<cfelse>
				<!--- application.objectURL is not defined, so fall back to prior method.
					This will only work if list() is being called directly by the browser. - leon 12/7/07 --->
				<cfset v.pathName = replace(cgi.script_name, '_set', '')>
			</cfif>

			<cfif not(structKeyExists(arguments, 'editLink'))>
				<cfset arguments.editLink = v.pathName & "?method=edit">
			</cfif>
			<cfif not(structKeyExists(arguments, 'deleteLink'))>
				<cfset arguments.deleteLink = v.pathName & "?method=delete">
			</cfif>
		</cfif>


		<cfif find('?', editLink)>
			<cfset editLink = editLink & "&amp;">
		<cfelse>
			<cfset editLink = editLink & "?">
		</cfif>

		<cfif find('?', deleteLink)>
			<cfset deleteLink = deleteLink & "&amp;">
		<cfelse>
			<cfset deleteLink = deleteLink & "?">
		</cfif>

		<cfset stArgs = structNew()>
		<cfif structKeyExists(arguments, 'filterField')>
			<cfset structInsert(stArgs, 'filterField', arguments.filterField)>
		</cfif>
		<cfif structKeyExists(arguments, 'filterValue')>
			<cfset structInsert(stArgs, 'filterValue', arguments.filterValue)>
		</cfif>

		<cfif not(structKeyExists(arguments, 'rsObjects'))>
			<cfset rsObjects = this.getAll(argumentCollection = stArgs)>
		</cfif>

		<cfset this.init()>

		<!--- We used to check if the _content_header.cfm file existed with
			fileExists(), but expandPath() doesn't understand CF mappings on Windows,
			so we can't do it that way. - leon 3/28/07 --->
		<cftry>
			<cfinclude template="/#replace(this.objectMap, '.', '/', 'all')#/../include/_content_header.cfm">
			<cfcatch type="any" />
		</cftry>

		<cfif arguments.showNewObjLink>
			<cfset strObjName = replace(this.theObject, '_', ' ', 'all')>
			<cfset strObjName = REreplace(strObjName, '((^| ))([a-zA-Z])', '\1\u\3', 'all')>
			<cfoutput>
			<p><a href="#editLink#id=">New #strObjName#</a></p>
			</cfoutput>
		</cfif>

		<table border="0" class="zebra sortable tablesorter" id="<cfoutput>#theObject#</cfoutput>list">
			<thead>
			<cfoutput>
				<tr>
					<th></th>
					<cfloop list="#this.listViewFieldList#" index="i">

							<cfsavecontent variable="theHeader">
							<cfif i contains ":">
								#listFirst(i, ':')#
							<cfelse>
								#objObj.getLabel(i)#
							</cfif>
							</cfsavecontent>
							<th>#trim(theHeader)#</th>

					</cfloop>
				</tr>
			</cfoutput>
			</thead>
			<tbody>
			<cfoutput query="rsObjects">
				<tr>
					<td>
						<a href="#deleteLink#id=#rsObjects[this.theID][currentRow]#<cfif structKeyExists(arguments, 'goto')>&goto=#URLEncodedFormat(goto)#</cfif>" onclick="return confirm('Are you sure?');">delete</a>
					</td>
					<cfloop list="#this.listViewFieldList#" index="i">
						<cfif i contains ":">
							<cfset i = listLast(i, ':')>
						</cfif>
						<cfif structKeyExists(objObj.stColMetaData, i) and listContains('bigint,integer,smallint,tinyint,float,decimal,bit', objObj.stColMetaData[i].dataType)>
							<cfset cellClass="numeric">
						<cfelse>
							<cfset cellClass="">
						</cfif>
						<td class="#cellClass#">
							<cfif i eq this.theNameField>
								<a href="#editLink#id=#rsObjects[this.theID][currentRow]#<cfif structKeyExists(arguments, 'goto')>&goto=#URLEncodedFormat(goto)#</cfif>">#HTMLEditFormat(rsObjects[i][currentRow])#</a>
							<cfelseif i contains "(">
								#evaluate(replace(i, ';', ',', 'all'))#
							<cfelse>
								#HTMLEditFormat(rsObjects[i][currentRow])#
							</cfif>
						</td>
					</cfloop>
				</tr>
			</cfoutput>

			<cfif showTotals>
				<cfoutput><tr class="total numeric">
					<!--- Delete link column - leon 12/6/07 --->
					<td></td>
					<cfloop list="#this.listViewFieldList#" index="i">
						<td>
							<cfif i does not contain ":" and i does not contain "(">
								<cftry>
									<cfquery name="rsSum" dbtype="query">
										select sum(cast(#i# as decimal)) as theSum
										from rsObjects
										where #i# is not null
									</cfquery>
									#HTMLEditFormat(rsSum.theSum)#
									<cfcatch type="any">
										<cfif cfcatch.detail does not contain "operand of type"
											and cfcatch.message does not contain "cannot be converted to a number">
											<cfrethrow>
										</cfif>
									</cfcatch>
								</cftry>
							</cfif>
						</td>
					</cfloop>
				</tr></cfoutput>
			</cfif>

			</tbody>
		</table>

	</cffunction> <!--- list --->


	<cffunction name="orderBy" returntype="string" access="public" output="no"
			hint="Returns idList, sorted by orderColumn">
		<cfargument name="idList" type="string" required="yes" hint="list of integer ids">
		<cfargument name="orderColumn" type="variableName" required="yes">
		<cfargument name="orderDirection" type="string" required="yes">

		<cfset var v = StructNew()>
		<cfif arguments.orderDirection neq "asc" and arguments.orderDirection neq "desc" >
			<cfthrow message="orderDirection is not a valid value">
		</cfif>

		<!--- To Do: check that orderColumn is defined in theTable - Jared 4/1/09 --->

		<!--- Perform sort in database - Jared 4/1/09 --->
		<cfquery name="v.rsSorted" datasource="#application.datasource#">
			select #this.theID#, unitname from #this.theTable#
			where #this.theID# in (<cfqueryparam value="#arguments.idList#" list="yes" cfsqltype="cf_sql_integer">)
			order by #arguments.orderColumn# #arguments.orderDirection#
		</cfquery>

		<!--- Create the new (sorted) list.  We cannot use ValueList() for this,
		because it does not support a dynamic column name argument. - Jared 4/1/09 --->
		<cfset v.sortedIDList = "">
		<cfoutput query="v.rsSorted">
			<cfset v.currentID = v.rsSorted[this.theID]>
			<cfset v.sortedIDList = ListAppend( v.sortedIDList, v.currentID )>
		</cfoutput>

		<cfreturn v.sortedIDList>
	</cffunction> <!--- orderBy --->


	<cffunction name="useOffsetFetchSyntax" returnType="boolean" access="private" output="no"
			hint="Use weird OFFSET/FETCH syntax instead of common OFFSET/LIMIT syntax">
		<cfreturn false>
	</cffunction>


	<cffunction name="usesTombstoning" returnType="boolean" access="public" output="no">
		<cfset var objObj = this.getDbrowObj()>
		<cfreturn objObj.usesTombstoning()>
	</cffunction> <!--- usesTombstoning --->


</cfcomponent>
