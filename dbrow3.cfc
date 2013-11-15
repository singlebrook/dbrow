<!--- Sample child component extending dbrow:

<cfcomponent extends="dbrow3_mysql"> // choose the correct adapter
	<cfscript>
		// This is the only required field.
		theObject = "User";

		// You may supply these fields as necessary. Otherwise init() will use defaults like the
		// following
		theID = "UserID";
		theFieldsToSkip = "";
		theTable = "tblUser";
		theDatasource = application.datasource;
		theNameField = "User_name";

		/* RELATIONSHIPS
		- Belongs-to-one relationships will be automatically detected based on
			foreign key constraints
		- Has-many relationships can be defined in the constructor by using
			hasMany(). Both one-to-many and many-to-many relationships are supported.
		- Belongs-to-many relationships are the same this as has-many, so you can
			define them with hasMany().
		*/
	</cfscript>
</cfcomponent>
--->

<cfcomponent name="dbrow3" hint="represents a database record">

	<!--- Vars supporting logging - leon 9/27/09 --->
	<!--- Set to 0 to disable logging. - leon 9/27/09 --->
	<cfset dbrow3Logging = 0>
	<cfset lastTick = getTickCount()>
	<!--- End vars supporting logging - leon 9/27/09 --->

	<!--- Flag indicates whether initializeObject() has run - leon 8/31/06 --->
	<cfparam name="this.isInitialized" default="0">
	<!--- Flag indicates whether init() has run - leon 8/31/06 --->
	<cfparam name="this.isInited" default="0">
	<!--- Flag indicates whether object has ever been stored in database - leon 3/12/07 --->
	<cfparam name="this.isStored" default="0">

	<!--- Automatically calling `init()` from the pseudoconstructor
	doesn't work - it complains about theObject not being defined. I
	think this has something to do with the order in which constructors
	are called in child/parent objects. - leon 12/27/07 --->

	<!--- This used to have returntype="dbrow3", but that doesn't seem to work
		when you have grandchildren in another directory. - leon 7/25/07 --->
	<cffunction name="init" access="public"
			hint="This is the new 'constructor' method. It's called automatically by load() and new()." output="yes">
		<cfif not(isdefined('theObject'))>
			<cfthrow message="dbrow3 requires 'theObject' to be set in the constructor">
		</cfif>
		<cfif not(isdefined('theDatasource') or structKeyExists(application, 'datasource'))>
			<cfthrow message="dbrow3 requires 'theDatasource' to be set in the constructor OR that 'application.datasource' exists">
		</cfif>
		<cfif not(isdefined('theObjectMap') or structKeyExists(application, 'objectMap'))>
			<cfthrow message="dbrow3 requires 'theObjectMap' to be set in the constructor OR that 'application.objectMap' exists">
		</cfif>

		<cfparam name="theID" default="#theObject#ID">
		<cfparam name="theFieldsToSkip" default="">
		<cfparam name="theTable" default="tbl#theObject#">
		<cfparam name="theDatasource" default="#application.datasource#">
		<cfparam name="binaryFieldList" default="">
		<cfparam name="theNameField" default="#theObject#_name">
		<!--- Define the default immutable name field.
			Type objects need to define the value they represent - dave 12/2/08 --->
		<cfparam name="theImmutableNameField" default="name_immutable">
		<cfparam name="theImmutableNameFieldValue" default="">
		<!--- The type id field is the id field of this object that refers to the the
			foreign key id that defines this objects type.  The type obj is an actual
			instance of this object - dave 12/2/08 --->
		<cfparam name="typeIDField" default="">
		<cfparam name="this.typeObj" default="">
		<cfparam name="hiddenFieldList" default="">

		<cfscript>
			/* Define cache timespans.  Do not depend on request.timeLong
			to be defined. - Jared 2012-02-16 */
			this.timeLong = StructKeyExists(request, "timeLong") ? request.timeLong : cacheTimeoutDefault();
			this.timeNone = StructKeyExists(request, "timeNone") ? request.timeNone : CreateTimeSpan(0,0,0,0);
		</cfscript>

		<cfset logIt('init() called on dbrow object #theNameField#. Generating classUniqueID...')>

		<!--- classUniqueID holds an alphanumeric string that uniquely identifies this CFC. We use it
			in the cache manager method calls to prevent name collisions. - leon 4/5/07 --->
		<cfset this.classUniqueID = hash(getMetadata(this).path)>

		<cfset logIt('Calling initializeObject()...')>
		<cfset initializeObject(theID, theFieldsToSkip, theTable, theObject, theDatasource, theImmutableNameField, theImmutableNameFieldValue, typeIDField, binaryFieldList)>

		<cfset this.theNameField = theNameField>
		<cfset this.hiddenFieldList = hiddenFieldList>
		<cfif isdefined('theObjectMap')>
			<cfset this.objectMap = theObjectMap>
		<cfelse>
			<cfset this.objectMap = application.objectMap>
		</cfif>

		<!--- Create stMany if it doesn't exist yet. - leon 4/21/08 --->
		<cfif not(structKeyExists(this, 'stMany'))>
			<!--- Stores information about this-to-many relationships - leon 4/21/08 --->
			<cfset this.stMany = structNew()>
		</cfif>

		<!--- Create stCustomValidation if it doesn't exist yet. - leon 4/21/08 --->
		<cfif not(structKeyExists(this, 'stCustomValidation'))>
			<!--- Stores custom validation rules - leon 4/21/08 --->
			<cfset this.stCustomValidation = structNew()>
			<!--- This struct has property names for keys.
				The value is always an array of custom rules for that property.
				Custom rules are structs with keys (regex, function, errorText).
			- leon 12/11/08 --->
		</cfif>

		<!--- There are a dozen methods in dbrow3.cfc which are more
		concerned with rendering a record (eg. in html) than they are
		with core responsibilities like persistence.  In dbrow 3.2,
		these methods will be delegated to a dbrow_renderer without
		changing the behavior of dbrow or its interface (method
		signatures).  In future versions of dbrow, these methods may be
		deprecated, or the delegate (dbrow_renderer) could become a
		decorator, or these methods could be removed from the dbrow api
		entirely.  - Jared 4/28/12 --->
		<cfset initializeRenderer()>

		<cfset this.isInited = 1>

		<cfreturn this>
	</cffunction> <!--- init --->


	<cfscript>

	public void function initializeRenderer() {
		if (NOT StructKeyExists(this, "renderer")) {
			this.renderer = CreateObject('component', 'dbrow_renderer').init(this);
		}
	}

	</cfscript>


	<cffunction name="initializeObject" returnType="boolean" access="package"
			hint="This initializes the object's properties and metadata. It is called by init(), but may
				also be manually run in the constructor area of the child component (for legacy apps).">
		<cfargument name="theID" type="string" required="yes">
		<cfargument name="theFieldsToSkip" type="string" required="yes">
		<cfargument name="theTable" type="string" required="yes">
		<cfargument name="theObject" type="string" required="yes">
		<cfargument name="theDatasource" type="string" required="yes">
		<cfargument name="theImmutableNameField" type="string" required="yes">
		<cfargument name="theImmutableNameFieldValue" type="string" required="no" default="">
		<cfargument name="typeIDField" type="string" required="no" default="">
		<cfargument name="binaryFieldList" type="string" required="no" default="">

		<cfparam name="this.isInitialized" default="0">

		<cfset logIt('Running initializeObject()')>

		<!--- This is a workaround for the situation when you have a grandchild object of dbrow's. The
			child object's constructor runs first, thus initializing the object with what may not
			be the correct information. So, when the grandchild's constructor runs, we've got to clear out
			the child's information before we can set up the grandchild's. - leon 6/30/05 --->
		<cfif this.isInitialized>
			<cfset logIt('Clearing dbrow child info so we can use grandchild''s instead')>
			<cfset structclear(this)>
		</cfif>

		<cfset this.theID = arguments.theID>
		<cfset this.theFieldsToSkip = arguments.theFieldsToSkip>
		<cfset this.theTable = arguments.theTable>
		<cfset this.theObject = arguments.theObject>
		<cfset this.datasource = arguments.theDatasource>
		<cfset this.theImmutableNameField = arguments.theImmutableNameField>
		<cfset this.theImmutableNameFieldValue = arguments.theImmutableNameFieldValue>
		<cfset this.typeIDField = arguments.typeIDField >
		<cfset this.binaryFieldList = arguments.binaryFieldList>

		<cfif not(find("cfcexplorer.cfc", cgi.script_name))>

			<!--- Generate metadata structures - leon 2/4/06 --->
			<cfset logIt('Setting stColMetaData')>
			<cfif not(structKeyExists(this, 'stColMetaData'))>
				<cfset this.stColMetaData = getCachedColumnMetaData()>
			</cfif>

			<cfset logIt('Setting stFKMetaData')>
			<cfif not(structKeyExists(this, 'stFKMetaData'))>
				<cfset this.stFKMetaData = getCachedForeignKeyMetaData()>
			</cfif>
			<!--- Done generating metadata - leon 2/4/06 --->

			<cfset logIt('Populating stOrigState')>
			<cfset this.stOrigState = structNew()>
			<cfloop list="#structKeyList(this.stColMetaData)#" index="i">
				<cfset structInsert(this, i, '')>
				<cfset structInsert(this.stOrigState, i, '')>
			</cfloop>

			<cfset variables.properties = StructSort(this.stColMetaData, 'numeric', 'asc', 'sortorder')>
			<cfset this.isInitialized = 1>
			<cfset this.isStored = 0>

			<cfscript>
			/* Set up labels for properties - leon 2/4/06 */
			logIt('Populating stLabel');
			if ( NOT StructKeyExists(this, 'stLabel') ) {
				this.stLabel = StructNew();
			}
			for( var i in variables.properties ){
				if (NOT StructKeyExists(this.stLabel, i) ) {
					this.stLabel[i] = REReplace(Replace(i, '_', ' ', 'all'), '((^| ))([a-zA-Z])', '\1\u\3', 'all');
				}
			}
			/* Done setting up labels - leon 2/4/06 */
			</cfscript>

		</cfif>

		<cfreturn true>
	</cffunction> <!--- initializeObject --->


	<cffunction name="addValidation" returntype="void" output="no" access="public">
		<cfargument name="propertyName" type="string" required="yes">
		<cfargument name="regex" type="string" required="no" default=""
				hint="Regex checks will work client-side (if using formvalidation.js) and server-side.">
		<cfargument name="function" type="string" required="no" default=""
				hint="The name of a CF function that takes in a property value and
					returns a boolean value indicating that the value is OK or not. These
					obviously won't work client-side.">
		<cfargument name="errorText" type="string" required="no"
				hint="Gets prepended with property label.">

		<cfset var v = structNew()>

		<!--- Check input - leon 12/11/08 --->
		<cfif not(structKeyExists(arguments, 'regex') or structKeyExists(arguments, 'function'))>
			<cfthrow message="addValidation() requires either a regex or a function">
		</cfif>

		<cfset v.newRule = structNew()>
		<cfset v.newRule.regex = arguments.regex>
		<cfset v.newRule['function'] = arguments['function']>
		<cfset v.newRule.errorText = arguments.errorText>

		<!--- Create stCustomValidation if it doesn't exist yet. - leon 4/21/08 --->
		<cfif not(structKeyExists(this, 'stCustomValidation'))>
			<cfset this.stCustomValidation = structNew()>
		</cfif>

		<cfif not(structKeyExists(this.stCustomValidation, propertyName))>
			<cfset this.stCustomValidation[propertyName] = arrayNew(1)>
		</cfif>

		<cfset arrayAppend(this.stCustomValidation[propertyName], v.newRule)>

	</cffunction> <!--- addValidation --->


	<cffunction name="afterDelete" returnType="void" output="false" access="package"
			hint="A stub function that's called at the end of a delete() process">
	</cffunction> <!--- afterDelete --->

	<cffunction name="afterLoad" returnType="void" output="false" access="package"
			hint="A stub function that's called at the end of a load() process">
	</cffunction> <!--- afterLoad --->


	<cffunction name="afterStore" returnType="void" output="false" access="package"
			hint="Called at the end of a store() process.  Children should call super.afterStore()">

		<cfset var v = structNew()>

		<!--- Store data for this-to-many relationships  - leon 4/22/08 --->
		<cfloop collection="#this.stMany#" item="v.relName">
			<cfset v.stRel = this.stMany[v.relName]>
			<cfif len(v.stRel.myID)>
				<cfset v.myID = v.stRel.myID>
			<cfelse>
				<cfset v.myID = theID>
			</cfif>

			<!--- Only need to store dirty records. - leon 4/22/08 --->
			<cfif v.stRel.dirty>

				<cfset v.objForeignObj = createObject('component', '#application.objectMap#.#v.stRel.objectType#').new()>

				<cfif len(v.stRel.linkTable)>
					<!--- Store related IDs in linking table - leon 4/21/08 --->

					<!--- Determine relevant column names in linking table - Jared 5/9/08 --->
					<cfset v.stLTInfo = getLinkingTableInfo(v.relName)>
					<cfset v.linksToMyID = v.stLTInfo.linksToMyID>
					<cfset v.linksToForeignID = v.stLTInfo.linksToForeignID>

					<!--- First clear out removed links  - leon 4/22/08 --->
					<cfquery datasource="#this.datasource#">
						delete from #v.stRel.linkTable#
						where #v.linksToMyID# = <cfqueryparam value="#this[v.myID]#" cfsqltype="cf_sql_#this.stColMetaData[v.myID].datatype#">
							<cfif len(v.stRel.idList)>
								and #v.linksToForeignID# not in (#v.stRel.idList#)
							</cfif>
							<cfif len(v.stRel.linkTableFilterField)>
								and #v.stRel.linkTableFilterField# = <cfqueryparam value="#v.stRel.linkTableFilterValue#">
							</cfif>
					</cfquery>

					<!--- Then add missing links, if any - leon 4/22/08 --->
					<cfif len(v.stRel.idList)>
						<cfquery datasource="#this.datasource#">
							insert into #v.stRel.linkTable# (#v.linksToMyID#, #v.linksToForeignID#
									<cfif len(v.stRel.linkTableFilterField)>
										, #v.stRel.linkTableFilterField#
									</cfif>
								)
							select <cfqueryparam value="#this[v.myID]#" cfsqltype="cf_sql_#this.stColMetaData[v.myID].datatype#">,
								#v.objForeignObj.theID#
								<cfif len(v.stRel.linkTableFilterField)>
									, <cfqueryparam value="#v.stRel.linkTableFilterValue#">
								</cfif>
							from #v.objForeignObj.theTable# f
							where #v.objForeignObj.theID# in (#v.stRel.idList#)
								and not(exists(
									select #v.linksToMyID# from #v.stRel.linkTable# l
									where l.#v.linksToMyID# = <cfqueryparam value="#this[v.myID]#" cfsqltype="cf_sql_#this.stColMetaData[v.myID].datatype#">
										and l.#v.linksToForeignID# = f.#v.objForeignObj.theID#
								))
						</cfquery>
					</cfif>

				<cfelse>
					<!--- Update items with related IDs in foreign table - leon 4/21/08 --->

					<!--- This is a little bit weird because we could be setting the foreign key field
						in the other table to null if we're removing entities from the relationship. This
						will certainly fail in some relationships where the foreign key field is not nullable.
						Under these circumstances, the user interface should only allow reassignment, not
						removal of an entity from the relationship. - leon 4/22/08 --->

					<!--- Load up array of items - leon 4/22/08 --->
					<cfset v.objForeignSet = createObject('component', '#application.objectMap#.#v.stRel.objectType#_set')>

					<!--- Find the foreign key field in the other table - leon 4/22/08 --->
					<cfset v.foreignKeyCol = v.objForeignObj.getForeignKeyCol(theID, theTable)>


					<!--- Remove entities from the relationship where appropriate - leon 4/22/08 --->
					<cfset v.rsForeign = v.objForeignSet.getAll(
							filterField = v.foreignKeyCol,
							filterValue = this[theID]
						)>

					<!--- XXX - maybe we shouldn't convert them all to objects. Maybe we should test
						first and then convert where necessary. - leon 4/22/08 --->
					<cfset v.arForeign = v.objForeignObj.queryToArray(v.rsForeign)>
					<cfloop from="1" to="#arrayLen(v.arForeign)#" index="v.i">
						<cfset v.thisObj = v.arForeign[v.i]>
						<cfif not(listFindNoCase(v.stRel.idList, v.thisObj[v.thisObj.theID]))>
							<cfset v.thisObj[v.foreignKeyCol] = "">
							<cfset v.thisObj.store()>
						</cfif>
					</cfloop>
					<!--- Done removing entities - leon 4/22/08 --->


					<!--- Add entities to the relationship (if any) - leon 4/22/08 --->
					<cfif len(v.stRel.idList)>
						<cfset v.rsForeign = v.objForeignSet.getAll(
								filterField = v.objForeignObj.theID,
								filterValue = v.stRel.idList
							)>
						<!--- XXX - maybe we shouldn't convert them all to objects. Maybe we should test
							first and then convert where necessary. - leon 4/22/08 --->
						<cfset v.arForeign = v.objForeignObj.queryToArray(v.rsForeign)>
						<cfloop from="1" to="#arrayLen(v.arForeign)#" index="v.i">
							<cfset v.thisObj = v.arForeign[v.i]>
							<cfif v.thisObj[v.foreignKeyCol] neq this[theID]>
								<cfset v.thisObj[v.foreignKeyCol] = this[theID]>
								<cfset v.thisObj.store()>
							</cfif>
						</cfloop>
					</cfif> <!--- len(v.stRel.idList) --->
					<!--- Done adding entities - leon 4/22/08 --->

				</cfif>

				<!--- Now that it's stored, it's no longer dirty. - leon 4/22/08 --->
				<cfset v.stRel.dirty = 0>
				<!--- It is "loaded", though. - leon 4/22/08 --->
				<cfset v.stRel.loaded = 1>

			</cfif> <!--- v.stRel.dirty --->
		</cfloop>

	</cffunction> <!--- afterStore --->


	<cffunction name="beforeDelete" returnType="void" output="false" access="package"
			hint="A stub function that's called at the beginning of a delete() process">
	</cffunction> <!--- beforeDelete --->

	<cffunction name="beforeLoad" returnType="void" output="false" access="package"
			hint="A stub function that's called at the beginning of a load() process">
	</cffunction> <!--- beforeLoad --->

	<cffunction name="beforeStore" returnType="void" output="false" access="package"
			hint="A stub function that's called at the beginning of a store() process">
	</cffunction> <!--- beforeStore --->


	<cffunction name="cacheTimeout" returntype="date" output="no" access="public">
		<cfargument name="useCache" type="boolean" required="yes">
		<cfreturn IIF(arguments.useCache, this.timeLong, this.timeNone)>
	</cffunction> <!--- cacheTimeout --->


	<cffunction name="cacheTimeoutDefault" returntype="date" output="no" access="public"
			hint="The default cache timeout.  Only used if request.timeLong is
				undefined.  If a time span other than two hours is required, override
				this function in the child class.">
		<cfreturn CreateTimeSpan(0,2,0,0)>
	</cffunction> <!--- cacheTimeoutDefault --->


	<cffunction name="checkRemoteMethodAuthorization" returntype="void" output="false" access="public"
			hint="Called by all remote methods.  Override with authorization checks to get access to the methods.">
		<cfthrow type="com.singlebrook.dbrow3.UnauthorizedAccessException" message="Unauthorized access" detail="You are not allowed to access this method">
	</cffunction>


	<cfscript>
	/* Clears this object's properties so that it can be safely
		load()ed again with a new ID */
	public void function clear(){
		if ( NOT this.isInited ) {
			init();
		}
		for (var i in variables.properties)) {
			StructUpdate(this, i, '');
			StructUpdate(this.stOrigState, i, '');
		}
		this.isStored = 0;
		clearThisToManyData();
	}
	</cfscript>


	<cffunction name="clearThisToManyData" returntype="void" output="no" access="public">
		<cfset var v = structNew()>

		<!--- Clear out this-to-many relationships - leon 4/22/08 --->
		<cfloop collection="#this.stMany#" item="v.i">
			<cfset this.stMany[v.i].idList = "">
			<cfset this.stMany[v.i].loaded = 0>
			<cfset this.stMany[v.i].dirty = 0>
		</cfloop>

	</cffunction> <!--- clearThisToManyData --->


	<cffunction name="delete" returnType="boolean" access="remote"
			hint="Delete this object's data from the database">

		<cfargument name="ID" required="no">
		<cfargument name="goto" type="string" required="no" default="#replace(cgi.script_name, '.cfc', '_set.cfc')#?method=list">

		<!--- Check to make sure the user has permissions --->
		<cfif StructKeyExists( url, "method" ) and url.method eq "delete">
			<cfset checkRemoteMethodAuthorization() >
		</cfif>

		<cfif structKeyExists(arguments, 'ID')>
			<cfset load(arguments.ID)>
		</cfif>

		<cfset beforeDelete()>

		<cfset IDToDelete = this[theID]>

		<!--- Tombstoning - Jared 4/23/08 --->
		<cfif usesTombstoning()>

			<!--- RecordAlreadyDeletedException --->
			<cfif isDeleted()>
				<cfthrow type="com.singlebrook.dbrow3.RecordAlreadyDeletedException"
					message="Attempt to delete() a tombstoned record">
			</cfif>

			<!--- Set deleted in database ... --->
			<cfquery name="delete#theObject#" datasource="#this.datasource#">
				update #theTable#
				set deleted = <cfqueryparam value="1" cfsqltype="cf_sql_#this.stColMetaData['deleted'].datatype#">
				where #theID# = <cfqueryparam value="#IDToDelete#" cfsqltype="cf_sql_#this.stColMetaData[theID].datatype#">
			</cfquery>

			<!--- ... and in memory --->
			<cfset this.deleted = true>

		<!--- Normal deletion --->
		<cfelse>
			<cfquery name="delete#theObject#" datasource="#this.datasource#">
				delete
				from #theTable#
				where #theID# = <cfqueryparam value="#IDToDelete#" cfsqltype="cf_sql_#this.stColMetaData[theID].datatype#">
			</cfquery>
		</cfif>

		<cfset afterDelete()>

		<cfif structKeyExists(arguments, 'ID')>
			<cflocation url="#goto#" addToken="no">
		</cfif>

		<cfreturn true>
	</cffunction> <!--- delete --->


	<cffunction name="drawPropertyValue" returnType="string" output="no" access="public">
		<cfargument name="propertyname" type="string" required="yes">
		<cfset initializeRenderer()>
		<cfreturn this.renderer.drawPropertyValue(arguments.propertyname)>
	</cffunction>


	<cffunction name="drawForm" returnType="string" output="no" access="public">
		<cfset initializeRenderer()>
		<cfreturn this.renderer.drawForm(argumentCollection = arguments)>
	</cffunction>


	<cffunction name="drawFormEnd" returnType="string" output="no" access="public">
		<cfset initializeRenderer()>
		<cfreturn this.renderer.drawFormEnd()>
	</cffunction>


	<cffunction name="drawFormField" returnType="string" output="no" access="public">
		<cfset initializeRenderer()>
		<cfreturn this.renderer.drawFormField(argumentCollection = arguments)>
	</cffunction>


	<cffunction name="drawFormErrorSummary" returnType="string" output="no" access="public">
		<cfset initializeRenderer()>
		<cfreturn this.renderer.drawFormErrorSummary(argumentCollection = arguments)>
	</cffunction>


	<cffunction name="drawFormStart" returnType="string" output="no" access="public">
		<cfset initializeRenderer()>
		<cfreturn this.renderer.drawFormStart(argumentCollection = arguments)>
	</cffunction>


	<cffunction name="drawStandardFormField" returnType="string" output="no" access="public">
		<cfset initializeRenderer()>
		<cfreturn this.renderer.drawStandardFormField(argumentCollection = arguments)>
	</cffunction>


	<cffunction name="drawErrorField" returnType="string" output="no" access="public">
		<cfset initializeRenderer()>
		<cfreturn this.renderer.drawErrorField(argumentCollection = arguments)>
	</cffunction>


	<cffunction name="edit" returnType="void" output="yes" access="remote">
		<cfset initializeRenderer()>
		#this.renderer.edit(argumentCollection = arguments)#
	</cffunction> <!--- edit --->



	<cffunction name="elapsed" returntype="numeric" output="no">
		<cfset var elapsedTime = getTickCount() - lastTick>
		<cfset lastTick = getTickCount()>
		<!--- Convert to seconds - leon 9/27/09 --->
		<cfset elapsedTime = numberFormat(elapsedTime / 1000, '9999.000')>
		<!--- Format for display by prepending spaces to get a fixed width. - leon 9/27/09 --->
		<cfset elapsedTime = repeatString(' ', 10 - len(elapsedTime)) & elapsedTime>
		<cfreturn elapsedTime>
	</cffunction> <!--- elapsed --->



	<cffunction name="getCachedColumnMetaData" returnType="struct" output="no"
			hint="Returns the column meta data for this object. Uses the cached version if possible.">

		<cfset var stResults = "">

		<cftry>
			<cfset stResults = application.dbrow3cache.getColumnMetaData(this.classUniqueID)>

			<cfif stResults.hit>
				<cfset stColMetaData = stResults.stMetaData>
			<cfelse>

				<!--- dbrow3cache miss.  Ask the rdbms adapter (eg. dbrow3_pgsql)
				for the metadata.  Be aware that the adapter probably uses CF query
				caching in its getColumnMetaData() method. - Jared 2012-02-16 --->
				<cfset stColMetaData = getColumnMetaData()>
				<cfset application.dbrow3cache.setColumnMetaData(this.classUniqueID, stColMetaData)>
			</cfif>

			<cfcatch type="any">
				<cfset stColMetaData = getColumnMetaData()>
			</cfcatch>
		</cftry>
		<cfreturn stColMetaData>

	</cffunction> <!--- getCachedColumnMetaData --->


	<cffunction name="getCachedForeignKeyMetaData" returnType="struct" output="no"
			hint="Returns the column meta data for this object. Uses the cached version if possible.">

		<cfset var stResults = "">

		<cftry>
			<cfset stResults = application.dbrow3cache.getForeignKeyMetaData(this.classUniqueID)>

			<cfif stResults.hit>
				<cfset stFKMetaData = stResults.stMetaData>
			<cfelse>
				<cfset stFKMetaData = getForeignKeyMetaData()>
				<cfset application.dbrow3cache.setForeignKeyMetaData(this.classUniqueID, stFKMetaData)>
			</cfif>
			<cfcatch type="any">
				<cfset stFKMetaData = getForeignKeyMetaData()>
			</cfcatch>
		</cftry>
		<cfreturn stFKMetaData>

	</cffunction> <!--- getCachedForeignKeyMetaData --->


	<cffunction name="getColDataType" returnType="string" output="no" access="public">
		<cfargument name="col" type="string" required="yes">
		<cfreturn stColMetaData[arguments.col].dataType>
	</cffunction> <!--- getColDataType --->


	<cffunction name="getChanges" returnType="struct" output="no"
			hint="Returns a struct of arrays, where each inner struct is an old/new value pair for a property">

		<cfset stChanges = request.structCompare(this.stOrigState, this)>

		<cfreturn stChanges>

	</cffunction> <!--- getChanges --->


	<cffunction name="getDefaultTabIndex" returnType="numeric" output="no" access="public">
		<cfset initializeRenderer()>
		<cfreturn this.renderer.getDefaultTabIndex()>
	</cffunction>


	<cffunction name="getError" returntype="struct" output="no" access="public"
			hint="Pulls an error for a particular field out of an error array. Error is a struct with keys (propertyName, propertyLabel, errorText).
				Struct values will be empty if there was no error.">
		<cfargument name="arErrors" type="array" required="yes" hint="Array of validation errors. See getErrorArray().">
		<cfargument name="propertyName" type="string" required="yes" hint="The property you're checking.">
		<cfset var v = structNew()>

		<cfloop from="1" to="#arrayLen(arErrors)#" index="v.i">
			<cfif arErrors[v.i].propertyName eq arguments.propertyName>
				<cfreturn arErrors[v.i]>
			</cfif>
		</cfloop>

		<cfreturn newError('', '', '')>

	</cffunction> <!--- getError --->


	<cffunction name="getErrorArray" returntype="array" output="no" access="public"
			hint="Returns an array of errors. Each error is a hash with keys (propertyName, propertyLabel, errorText).
				We return an array in order to preserve the ordering of fields.">
		<cfset var v = structNew()>
		<cfset var stMD = "">

		<cfset v.arErrors = arrayNew(1)>

		<cfloop array="#variables.properties#" index="v.thisProp">
			<cfif v.thisProp neq theID and not(listFindNoCase(theFieldsToSkip, v.thisProp))>

				<cfset stMD = this.stColMetaData[v.thisProp]>

				<!--- Check not null constraint - leon 12/9/08 --->
				<cfif stMD.notNull and NOT isBinary(this[v.thisProp])
						and IsSimpleValue(this[v.thisProp]) and this[v.thisProp] eq "">
					<cfset arrayAppend(v.arErrors, newError(v.thisProp, getLabel(v.thisProp), 'cannot be blank'))>
				</cfif>

				<!--- Check maximum length - leon 12/9/08 --->
				<cfif val(stMD.maxLen) and (len(this[v.thisProp]) gt stMD.maxLen)>
					<cfset arrayAppend(v.arErrors, newError(v.thisProp, getLabel(v.thisProp), 'cannot contain more than #stMD.maxLen# characters'))>
				</cfif>

				<!--- These checks don't get run on blank values - leon 12/9/08 --->
				<cfif NOT IsSimpleValue(this[v.thisProp]) OR len(this[v.thisProp])>

					<!--- Check datatype - leon 12/11/08 --->
					<cfswitch expression="#stMD.datatype#">
						<!--- ALL: char,bigint,integer,bit,binary,date,float,decimal,varchar,time,timestamp - leon 2/4/06 --->
						<!--- LEFT: char,bit,binary,other,varchar - don't think these need validation for now. - leon 2/4/06 --->
						<cfcase value="float,decimal" delimiters=",">
							<cfif not(isNumeric(this[v.thisProp]))>
								<cfset arrayAppend(v.arErrors, newError(v.thisProp, getLabel(v.thisProp), 'must be a number'))>
							</cfif>
						</cfcase>
						<cfcase value="integer,bigint" delimiters=",">
							<cfif listFirst(Server.ColdFusion.ProductVersion) gte 7 >
								<cfif not(isValid('integer', this[v.thisProp]))>
									<cfset arrayAppend(v.arErrors, newError(v.thisProp, getLabel(v.thisProp), 'must be an integer'))>
								</cfif>
							</cfif>
						</cfcase>
						<cfcase value="date,timestamp" delimiters=",">
							<cfif not(isDate(this[v.thisProp]))>
								<cfset arrayAppend(v.arErrors, newError(v.thisProp, getLabel(v.thisProp), 'must be a valid #stMD.datatype#'))>
							</cfif>
						</cfcase>
						<cfcase value="time">
							<cfif not(REFindNoCase('^((([0]?[1-9]|1[0-2])(:|\.)[0-5][0-9]((:|\.)[0-5][0-9])?( )?(AM|am|aM|Am|PM|pm|pM|Pm))|(([0]?[0-9]|1[0-9]|2[0-3])(:|\.)[0-5][0-9]((:|\.)[0-5][0-9])?))$', this[v.thisProp]))>
								<cfset arrayAppend(v.arErrors, newError(v.thisProp, getLabel(v.thisProp), 'must be a valid time'))>
							</cfif>
						</cfcase>
						<cfcase value="char,varchar">
							<!--- IsValid is only available on CF7 or greater - dave 10/20/09 --->
							<cfif listFirst(Server.ColdFusion.ProductVersion) gte 7 >
								<cfif v.thisProp EQ "email" AND NOT IsValid('email', this[v.thisProp])>
									<cfset arrayAppend(v.arErrors, newError(v.thisProp, getLabel(v.thisProp), 'must be a valid email address'))>
								</cfif>
							</cfif>
						</cfcase>
					</cfswitch>
					<!--- Done checking datatype - leon 12/11/08 --->

					<!--- Check custom rules - leon 12/11/08 --->
					<cfif structKeyExists(this.stCustomValidation, v.thisProp)>
						<cfset v.arRules = this.stCustomValidation[v.thisProp]>
						<cfloop from="1" to="#arrayLen(v.arRules)#" index="v.i">
							<cfset v.stRule = v.arRules[v.i]>
							<cfif len(v.stRule.regex)>
								<cfif not(REFind(v.stRule.regex, this[v.thisProp]))>
									<cfset arrayAppend(v.arErrors, newError(v.thisProp, getLabel(v.thisProp), v.stRule.errorText))>
								</cfif>
							</cfif>
							<cfif Len(v.stRule['function'])>
								<cfif NOT Evaluate('#v.stRule["function"]#("#this[v.thisProp]#")')>
									<cfset arrayAppend(v.arErrors, newError(v.thisProp, getLabel(v.thisProp), v.stRule.errorText))>
								</cfif>
							</cfif>
						</cfloop>
					</cfif>

				</cfif> <!--- len(this[v.thisProp]) --->

			</cfif> <!--- v.thisProp neq theID and not(listFindNoCase(theFieldsToSkip, v.thisProp)) --->
		</cfloop> <!--- variables.properties --->

		<cfreturn v.arErrors>

	</cffunction> <!--- getErrorArray --->


	<cffunction name="getErrorStruct" returntype="struct" output="no" access="public"
			hint="Returns a struct of validation errors with the property names as keys.
				Each error is a struct with keys (propertyName, propertyLabel, errorText).
				Currently limited to one error per property.">
		<cfset var arErrors = getErrorArray()>
		<cfset var stErrors = structNew()>
		<cfset var i = "">

		<cfloop from="1" to="#arrayLen(arErrors)#" index="i">
			<cfif not(structKeyExists(stErrors, arErrors[i].propertyName))>
				<cfset structInsert(stErrors, arErrors[i].propertyName, arErrors[i])>
			</cfif>
		</cfloop>

		<cfreturn stErrors>

	</cffunction> <!--- getErrorStruct --->


	<cffunction name="getForeignKeyCol" returntype="string" output="no" access="public">
		<cfargument name="refersToCol" type="string" required="yes"
				hint="The name of the column the foreign key col refers to">
		<cfargument name="refersToTable" type="string" required="yes"
				hint="The name of the table containing the foreign key">

		<cfset var v = structNew()>

		<cfloop collection="#this.stFKMetaData#" item="v.i">
			<cfset v.stFK = this.stFKMetaData[v.i]>
			<cfif v.stFK.foreignColumn eq refersToCol and v.stFK.foreignTable eq refersToTable>
				<cfreturn v.i>
			</cfif>
		</cfloop>

		<cfthrow message="Could not find foreign key col referring to #refersToTable# (#refersToCol#)"
			detail="Is this a many-to-many relationship?  Perhaps you forgot to specify linkTable in your call to hasMany()">

	</cffunction> <!--- getForeignKeyCol --->


	<cffunction name="getLabel" returntype="string" access="public" output="no">
		<cfargument name="propertyname" type="string" required="yes">
		<cfset initializeRenderer()>
		<cfreturn this.renderer.getLabel(arguments.propertyname)>
	</cffunction> <!--- getLabel --->


	<cffunction name="getLinkingTableInfo" returntype="struct" access="public" output="no"
			hint="Returns a structure with information about the important columns in a linking table">
		<cfargument name="relName" type="string" required="yes">

		<cfset var v = StructNew()>
		<cfset v.stInfo = StructNew()>

		<!--- Has the given relationship been defined? - Jared 5/9/08 --->
		<cfif not StructKeyExists(this.stMany, arguments.relName)>
			<cfthrow message="There is no relationship with the name '#arguments.relName#'.  Define relationships with hasMany()"
				detail="#StructKeyList(this.stMany)#">
		</cfif>

		<!--- The relationship - Jared 5/9/08 --->
		<cfset v.stRel = this.stMany[arguments.relName]>

		<!--- Either the relevant columns already been defined - Jared 5/9/08 --->
		<cfif len(v.stRel.linksToMyID)>
			<cfset v.stInfo.linksToMyID = v.stRel.linksToMyID>
		<cfelse>
			<!--- First figure out which column in linking table links to my ID field. - leon 4/21/08 --->
			<cfset v.stInfo.linksToMyID = lookupColLinkingTo(v.stRel.linkTable, this.theID, this.theTable)>
		</cfif>

		<cfif len(v.stRel.linksToForeignID)>
			<cfset v.stInfo.linksToForeignID = v.stRel.linksToForeignID>
		<cfelse>
			<!--- Then figure out which column in linking table links to foreign object's ID field. - leon 4/21/08 --->
			<cfset v.objForeignObj = createObject('component', '#application.objectMap#.#v.stRel.objectType#').new()>
			<cfset v.stArgs = StructNew()>
			<cfset v.stArgs.linkTable 		= v.stRel.linkTable>
			<cfset v.stArgs.linksToColumn = v.objForeignObj.theID>
			<cfset v.stArgs.linksToTable 	= v.objForeignObj.theTable>
			<cfset v.stInfo.linksToForeignID = lookupColLinkingTo(argumentCollection = v.stArgs)>

		</cfif>

		<cfreturn v.stInfo>
	</cffunction> <!--- getLinkingTableInfo --->


	<cffunction name="getIDColumn" returntype="string" output="no" access="public">
		<cfreturn this.theID>
	</cffunction> <!--- getIDColumn --->


	<cffunction name="getManyRelatedArray" returntype="array" output="no" access="public">
		<cfargument name="relName" type="variableName" required="yes"
				hint="The name of the relationship given in the initial hasMany()">
		<cfargument name="filterField" type="string" required="no">
		<cfargument name="filterValue" type="string" required="no">
		<cfargument name="filterSet" type="struct" required="no">

		<!--- Same arguments as getManyRelatedRS() - leon 5/8/08 --->
		<cfset var v = structNew()>

		<cfset v.stRel = this.stMany[relName]>
		<cfset v.objForeign = createObject('component', '#application.objectMap#.#v.stRel.objectType#').new()>

		<cfset v.rsRelated = getManyRelatedRS(argumentCollection = arguments)>

		<cfreturn v.objForeign.queryToArray(v.rsRelated)>

	</cffunction> <!--- getManyRelatedArray --->


	<cffunction name="getManyRelatedIDs" returntype="string" output="no" access="public"
			hint="Returns a list of IDs of the items in the named relationship">
		<cfargument name="relName" type="variableName" required="yes"
				hint="The name of the relationship given in the initial hasMany()">
		<cfargument name="reload" type="boolean" required="no" default="false"
				hint="Reload the IDs even if they are loaded or dirty">
		<cfargument name="bUseCache" type="boolean" required="no" default="no">

		<cfset var v = structNew()>

		<cfif not(structKeyExists(this.stMany, arguments.relName))>
			<cfthrow message="#theObject#.stMany has no information about the relationship #relName#">
		</cfif>

		<cfset v.stRel = this.stMany[arguments.relName]>
		<!--- If reloading but the relation is dirty, throw an error - dave 5/19/08 --->
		<cfif v.stRel.dirty and arguments.reload >
			<cfthrow message="Attempting to reload relation when the relation is already modified">
		</cfif>
		<!--- Don't load links from the database if they've already been loaded or have been modified
			since the last store(), unless reloading. - leon 4/22/08 --->
		<cfif not(v.stRel.loaded or v.stRel.dirty) or arguments.reload >
			<!--- Links have not been loaded yet. Load 'em up. - leon 4/21/08 --->

			<cfif len(v.stRel.myID)>
				<cfset v.myID = v.stRel.myID>
			<cfelse>
				<cfset v.myID = theID>
			</cfif>

			<cfset v.objForeignObj = createObject('component', '#application.objectMap#.#v.stRel.objectType#').new()>


			<cfif this.isStored>
				<cfif not(len(this[v.myID]))>
					<cfthrow message="Can't call getManyRelatedIDs on an object that is stored but has no data in the relavant ID field (#v.myID#). If the ID is the primary key, maybe you should add getID=1 when you store().">
				</cfif>

				<cfif len(v.stRel.linkTable)>
					<!--- Load related IDs from linking table - leon 4/21/08 --->

					<!--- Determine relevant column names in linking table - Jared 5/9/08 --->
					<cfset v.stLTInfo = getLinkingTableInfo(arguments.relName)>
					<cfset v.linksToMyID = v.stLTInfo.linksToMyID>
					<cfset v.linksToForeignID = v.stLTInfo.linksToForeignID>

					<cfquery name="v.rsForeign" datasource="#this.datasource#" cachedwithin="#this.timeLong#">
						select #v.linksToForeignID# as ID
						from #v.stRel.linkTable#
						where #v.linksToMyID# = <cfqueryparam value="#this[v.myID]#" cfsqltype="cf_sql_#this.stColMetaData[v.myID].datatype#">
							<cfif len(v.stRel.linkTableFilterField)>
								and #v.stRel.linkTableFilterField# = <cfqueryparam value="#v.stRel.linkTableFilterValue#">
							</cfif>
					</cfquery>

					<cfset v.idList = valueList(v.rsForeign.ID)>

				<cfelse>
					<!--- Load related IDs from foreign table - leon 4/21/08 --->
					<cfset v.objForeignSet = createObject('component', '#application.objectMap#.#v.stRel.objectType#_set')>

					<cfset v.rsForeign = v.objForeignSet.getAll(
							filterField = v.objForeignObj.getForeignKeyCol(v.myID, theTable),
							filterValue = this[v.myID],
							IDOnly = 1,
							bUseCache = bUseCache
						)>

					<cfset v.idList = "">
					<cfloop query="v.rsForeign">
						<cfset v.idList = listAppend(v.idList, evaluate(v.objForeignObj.theID))>
					</cfloop>

				</cfif>

			<cfelse>
				<!--- Not stored, so can't be linked to anything. - leon 6/10/08 --->
				<cfset v.idList = "">
			</cfif>

			<cfset v.stRel.idList = v.idList>
			<cfset v.stRel.loaded = 1>
			<cfset v.stRel.dirty = 0>

		</cfif> <!--- not(v.stRel.loaded) --->

		<cfreturn v.stRel.idList>

	</cffunction> <!--- getManyRelatedIDs --->


	<cffunction name="getManyRelatedRS" returntype="query" output="no" access="public">
		<cfargument name="relName" type="variableName" required="yes"
				hint="The name of the relationship given in the initial hasMany()">
		<cfargument name="filterField" type="string" required="no">
		<cfargument name="filterValue" type="string" required="no">
		<cfargument name="filterSet" type="struct" required="no">
		<cfargument name="bUseCache" type="boolean" required="no" default="no">

		<cfset var v = structNew()>

		<cfif (structKeyExists(arguments, 'filterField') or structKeyExists(arguments, 'filterValue'))
				and (not(structKeyExists(arguments, 'filterField')) or not(structKeyExists(arguments, 'filterValue')))>
			<cfthrow message="dbrow3.getManyRelatedRS requires both filterField and filterValue if either is passed">
		</cfif>
		<cfif structKeyExists(arguments, 'filterField') and structKeyExists(arguments, 'filterSet')>
			<cfthrow message="dbrow3.getManyRelatedRS cannot accept both filterField/filterValue and filterSet">
		</cfif>


		<!--- Load up the IDs of the related objects - leon 5/8/08 --->
		<cfset v.idList = getManyRelatedIDs(relName = relName, bUseCache = bUseCache)>
		<!--- Grab a reference to the metadata about the relationship. Note that the call to
			getManyRelatedIDs() above will confirm that relName is valid, so I'm not checking
			it here. - leon 5/8/08 --->
		<cfset v.stRel = this.stMany[relName]>
		<!--- And to the foreign object, so we can find out its ID field. - leon 5/8/08 --->
		<cfset v.objForeign = createObject('component', '#application.objectMap#.#v.stRel.objectType#').new()>


		<!--- If filterField is specified, we need to use filterSet instead since we're adding our own
			filter for ID here. Let's always use filterSet for simplicity. - leon 5/8/08 --->
		<cfif not(structKeyExists(arguments, 'filterSet'))>
			<cfset arguments.filterSet = structNew()>
		</cfif>

		<cfif structKeyExists(arguments, 'filterField')>
			<!--- Need to figure out if the passed-in filter is for the ID field. - leon 5/8/08 --->
			<cfif arguments.filterField eq v.objForeign.theID>
				<!--- The passed-in filter is for the ID field, so we need to limit the loaded objects to
					the intersection of the set of related IDs with the requested IDs. - leon 5/8/08 --->
				<cfset v.idList = listIntersection(v.idList, arguments.filterValue)>
			<cfelse>
				<!--- The passed in filter is something other than the ID field. - leon 5/8/08 --->
				<cfset filterSet[filterField] = filterValue>
			</cfif>
		</cfif>

		<!--- Now add the ID filter - leon 5/8/08 --->
		<cfset filterSet[v.objForeign.theID] = v.idList>

		<!--- And finally get the recordset of objects - leon 5/8/08 --->
		<cfset v.objForeignSet = createObject('component', '#application.objectMap#.#v.stRel.objectType#_set')>
		<cfreturn v.objForeignSet.getAll(filterSet = filterSet, bUseCache = bUseCache)>

	</cffunction> <!--- getManyRelatedRS --->


	<cffunction name="getNameColumn" returntype="string" output="no" access="public">
		<cfreturn this.theNameField>
	</cffunction> <!--- getNameColumn --->


	<cffunction name="getNotNull" returnType="boolean" output="no" access="public">
		<cfargument name="propertyName" required="yes">
		<cfreturn this.stColMetaData[arguments.propertyname].notNull>
	</cffunction> <!--- getNotNull --->


	<cfscript>
	public array function getProperties(
		boolean includeTheID = false
		, boolean includeFieldsToSkip = false){

		var props = [];
		for( var p in variables.properties ){
			if( (NOT p EQ this.theID OR arguments.includeTheID)
					AND (NOT ListContainsNoCase(this.theFieldsToSkip, p)
						OR arguments.includeFieldsToSkip) ){
				ArrayAppend(props, p);
			}
		}

		return props;
	}
	</cfscript>


	<cffunction name="getPropertyList" returntype="string" access="public" output="no">
		<cfargument name="includeTheID" type="boolean" required="no" default="no">
		<cfargument name="includeFieldsToSkip" type="boolean" required="no" default="no">

		<cfreturn ArrayToList(getProperties(argumentCollection = arguments))>
	</cffunction> <!--- getPropertyList --->


	<cffunction name="getPropertyValue" returnType="string" output="no" access="public"
			hint="Jared wants to deprecate drawPropertyValue() because it is poorly named">
		<cfargument name="propertyname" type="string" required="yes">
		<cfreturn drawPropertyValue(propertyname)>
	</cffunction>


	<cffunction name="getTabIndexAttr" returntype="string" output="no" access="public">
		<cfargument name="propertyname" type="string" required="yes">
		<cfset initializeRenderer()>
		<cfreturn this.renderer.getTabIndexAttr(arguments.propertyname)>
	</cffunction>


	<cffunction name="getTableName" returntype="string" output="no" access="public">
		<cfreturn this.theTable>
	</cffunction> <!--- getTableName --->


	<cffunction name="getValidationAttribs" returntype="string" access="public" output="no">
		<cfargument name="propertyname" type="string" required="yes">
		<cfset initializeRenderer()>
		<cfreturn this.renderer.getValidationAttribs(arguments.propertyname)>
	</cffunction>


	<cffunction name="hasMany" returntype="void" output="no" access="package">
		<cfargument name="relName" type="variableName" required="yes"
				hint="Relationship name that we can use to retrieve the related elements later.
					Must be a valid CF struct key name.">
		<cfargument name="objectType" type="string" required="yes"
				hint="Instantiable name of object (dot notation)">
		<cfargument name="label" type="string" required="yes">
		<cfargument name="linkTable" type="string" required="no" default=""
				hint="Linking table in a many-to-many relationship">
		<cfargument name="linksToMyID" type="string" required="no" default=""
				hint="Only needed when both id columns in linkTable reference the same table">
		<cfargument name="linksToForeignID" type="string" required="no" default=""
				hint="Only needed when both id columns in linkTable reference the same table">
		<cfargument name="myID" type="string" required="no" default=""
				hint="Use an alternate column as the key (e.g. uid instead of id)">
		<cfargument name="linkTableFilterField" type="string" required="no" default=""
				hint="Filter linking table by this column">
		<cfargument name="linkTableFilterValue" type="string" required="no" default=""
				hint="Filter linking table by looking for this value in linkTableFilterField">

		<cfset var v = structNew()>

		<!--- Validate arguments --->
		<cfif (len(arguments.linksToMyID) or len(arguments.linksToForeignID)) and not len(linkTable)>
			<cfthrow message="Invalid arguments in hasMany()">
		</cfif>

		<!--- Create stMany if it doesn't exist yet. We do this here *in addition to*
			in init() because hasMany will get called before init(). - leon 4/21/08 --->
		<cfif not(structKeyExists(this, 'stMany'))>
			<!--- Stores information about this-to-many relationships - leon 4/21/08 --->
			<cfset this.stMany = structNew()>
		</cfif>

		<cfset this.stMany[relName] = structNew()>
		<cfset v.stRel = this.stMany[relName]>

		<cfset v.stRel.objectType 	= objectType>
		<cfset v.stRel.label 				= label>
		<cfset v.stRel.linkTable 		= linkTable>
		<cfset v.stRel.linksToMyID 			= linksToMyID>
		<cfset v.stRel.linksToForeignID = linksToForeignID>
		<cfset v.stRel.myID = myID>
		<cfset v.stRel.linkTableFilterField = linkTableFilterField>
		<cfset v.stRel.linkTableFilterValue = linkTableFilterValue>

		<cfset v.stRel.idList = "">
		<cfset v.stRel.loaded = 0>
		<!--- "dirty" means it needs to be loaded. - leon 4/22/08 --->
		<cfset v.stRel.dirty = 0>

	</cffunction> <!--- hasMany --->


	<cffunction name="isDeleted" returnType="boolean" access="public" output="no">
	 	<cfif not usesTombstoning()>
	 		<cfthrow message="isDeleted() is only meaningful for objects that support tombstoning"
	 			detail="usesTombstoning() returned false during isDeleted()">
	 	</cfif>
	 	<cfreturn this.deleted>
	</cffunction> <!--- isDeleted --->


	<cffunction name="getIsStored" returnType="boolean" access="public" output="no">
	 	<cfreturn this.isStored>
	</cffunction> <!--- isStored --->


	<cffunction name="listIntersection" returntype="string" output="no" access="private"
			hint="Returns the case-sensitive intersection of two lists.">
		<cfargument name="list1" type="string" required="yes">
		<cfargument name="list2" type="string" required="yes">
		<cfargument name="delimiters" type="string" required="no" default=",">

		<cfset var newList = "">
		<cfset var i = "">

		<cfloop list="#list1#" index="i" delimiters="#delimiters#">
			<cfif listFind(list2, i)>
				<cfset newList = listAppend(newList, i)>
			</cfif>
		</cfloop>

		<cfreturn newList>

	</cffunction> <!--- listIntersection --->


	<cffunction name="load" returnType="dbrow3" output="no" access="public"
			hint="Loads an object's data from the database into the object">
		<cfargument name="ID" type="string" required="false">
		<cfargument name="bUseCache" type="boolean" required="false" default="0">
		<cfargument name="includeDeleted" type="boolean" required="false" default="0">

		<!--- You can pass either of these instead of ID, and the values in them will be used
			to populate the object instead of loading it from the database. - leon 5/8/08 --->
		<cfargument name="stValues" type="struct" required="no">
		<cfargument name="rsValues" type="query" required="no">

		<cfset var IDToLoad = "">
		<cfset var thisVal = "">
		<cfset var thisDataType = "">

		<cfif not(this.isInited)>
			<cfset init()>
		</cfif>

		<!--- Begin validating arguments --->
		<cfif iif(structKeyExists(arguments, 'ID'),1,0) + iif(structKeyExists(arguments, 'stValues'),1,0) + iif(structKeyExists(arguments, 'rsValues'),1,0) neq 1>
			<cfthrow message="dbrow3.load() requires exactly one of (ID, stValues, rsValues)">
		</cfif>

		<cfset var propList = ArrayToList(variables.properties)>

		<cfif StructKeyExists(arguments, 'stValues')
				AND ListSort(LCase(StructKeyList(stValues)), 'text')
					NEQ ListSort(LCase(propList), 'text')>
			<cfthrow message="stValues must contain exactly the keys (#propList#)">
		</cfif>

		<cfif structKeyExists(arguments, 'rsValues')>
			<cfif rsValues.recordcount neq 1>
				<cfthrow message="rsValues must have exactly one row">
			</cfif>
			<cfif ListSort(rsValues.columnlist, 'textnocase') neq ListSort(propList, 'textnocase')>
				<cfthrow message="rsValues must contain exactly the columns (#propList#)"
					detail="rsValues.Columnlist = #rsValues.Columnlist#">
			</cfif>
		</cfif>
		<!--- End validating arguments --->

		<cfset beforeLoad()>

		<cfset cacheTime = cacheTimeout(arguments.bUseCache)>

		<!--- If we were passed an ID, get the values associated with it and create rsValues. - leon 5/8/08 --->
		<cfif structKeyExists(arguments, 'ID')>
			<cfset IDToLoad = arguments.ID>

			<!--- Strip surrounding quotes from pre-quoted non-numeric IDs - leon 9/27/07 --->
			<cfif not(isNumeric(arguments.ID))>
				<cfset arguments.ID = REReplace(arguments.ID, "(^'|'$)", "", "all")>
			</cfif>

			<cfquery name="arguments.rsValues" datasource="#this.datasource#" cachedWithin="#cacheTime#">
				select *
				from #theTable#
				where #theID# = <!--- <cfqueryparam value="#IDToLoad#" cfsqltype="cf_sql_#this.stColMetaData[theID].datatype#"> - leon 2/7/06 --->
					<cfif isNumeric(arguments.ID)>#arguments.ID#<cfelse>'#arguments.ID#'</cfif>
			</cfquery>

			<cfif not(arguments.rsValues.recordcount)>
				<cfthrow type="com.singlebrook.dbrow3.RecordNotFoundException"
					message="#theObject# with #theID# (#arguments.ID#) could not be loaded."
					detail="The ID does not exist.">
			</cfif>

		</cfif>


		<cfloop array="#variables.properties#" index="i">
			<cfif structKeyExists(arguments, 'rsValues')>
				<cfset thisVal = arguments.rsValues[i][1]>
			<cfelse>
				<cfset thisVal = stValues[i]>
			</cfif>
			<cfset thisDataType = this.stColMetaData[i].datatype>

			<!--- Some DBMSs return date(times) formatted such that formvalidation.js can't interpret them.
				Standardize the format here. - leon 2/18/06 --->
			<cfif listFindNoCase('date,timestamp', thisDataType) and isDate(thisVal)>
				<cfif dateCompare(thisVal, dateFormat(thisVal))>
					<cfset thisVal = dateFormat(thisVal, 'mm/dd/yyyy') & " " & timeFormat(thisVal)>
				<cfelse>
					<cfset thisVal = dateFormat(thisVal, 'mm/dd/yyyy')>
				</cfif>
			</cfif>
			<!--- Sometimes the data comes back in a structure with a type and value key if coldfusion or
			the JDBC driver doesn't understand the datatype.  The actual place of failure is unknown.
			This moves the value to where it is expected out of the structure - dave 5/1/08 --->
			<cfif isStruct( thisVal ) and StructKeyExists( thisVal, "value" ) >
				<cfset thisVal = thisVal.value >
			</cfif>

			<cfif thisDataType eq 'json' and Len(thisVal)>
				<cftry>
					<cfset thisVal = DeserializeJSON(thisVal)>
					<cfcatch type="any">
						<cfthrow type="com.singlebrook.dbrow3.malformedJSONException"
							message="There was a problem deserializing the JSON for the property '#i#'"
							detail="#i#">
					</cfcatch>
				</cftry>
			</cfif>

			<cfset structUpdate(this, i, thisVal)>
			<cfset structUpdate(this.stOrigState, i, thisVal)>

		</cfloop>

		<!--- If this object has a non-empty ID, assume that it has been stored in the database. - leon 5/8/08 --->
		<cfset this.isStored = iif(len(this[theID]), 1, 0)>
		<cfset setOrigState()>


		<!--- LoadDeletedRecordException - Jared 4/23/08 --->
		<cfif usesTombstoning()
				and not arguments.includeDeleted
				and isDeleted()>
			<cfthrow type="com.singlebrook.dbrow3.LoadDeletedRecordException"
				message="Loading #theObject# with #theID# (#arguments.ID#) failed"
				detail="#theObject# with #theID# (#arguments.ID#) is tombstoned.  Try using arguments.includeDeleted">
		</cfif>

		<!--- Clear out this-to-many relationships - leon 4/22/08 --->
		<cfset clearThisToManyData()>

		<cfif isDefined( "this.typeIDField" ) and this.typeIDField neq "" >
			<cfset setTypeByID( evaluate( "this.#typeIDField#" ) ) >
		</cfif>

		<cfset afterLoad()>

		<cfreturn this>
	</cffunction> <!--- load --->


	<cffunction name="loadBy" access="public" returntype="boolean" output="no">
		<cfargument name="bUseCache" type="boolean" required="no" default="false">
		<cfargument name="filterField" type="string" required="no">
		<cfargument name="filterValue" type="string" required="no">
		<cfargument name="filterSet" type="struct" required="no" default="#structNew()#">
		<cfargument name="includeDeleted" type="boolean" required="false" default="0">

		<cfset var v = StructNew() >
		<cfset var valueIsNull = 0>

		<cfif (structKeyExists(arguments, 'filterField') or structKeyExists(arguments, 'filterValue'))
				and (not(structKeyExists(arguments, 'filterField')) or not(structKeyExists(arguments, 'filterValue')))>
			<cfthrow message="dbrow3.loadBy requires both filterField and filterValue if either is passed">
		</cfif>

		<cfif structKeyExists(arguments, 'filterField') and structKeyExists(arguments.filterSet, filterField)>
			<cfthrow message="filterField #filterField# was also specified as a key of filterSet. This is not acceptable.">
		</cfif>

		<cfif not(this.isInited)>
			<cfset init()>
		</cfif>

		<!--- Roll filterField and filterValue in filterSet so we can just deal with the latter. - leon 6/3/08 --->
		<cfif structKeyExists(arguments, 'filterField')>
			<cfset filterSet[filterField] = filterValue>
		</cfif>

		<cfquery name="getID" datasource="#this.datasource#">
			select #theID# as ID
			from #theTable#
			where 1 = 1
				<cfset v.setKeys = StructKeyList( filterSet ) >
				<cfloop list="#v.setKeys#" index="v.currentKey">
					<cfif LCase( StructFind( filterSet, v.currentKey ) ) eq "null" >
						and #v.currentKey# is null
					<cfelseif LCase( StructFind( filterSet, v.currentKey ) ) eq "not null" >
						and #v.currentKey# is not null
					<cfelse>

						<cfif this.stColMetaData[v.currentKey].datatype eq "json">
							<cfthrow type="com.singlebrook.dbrow3.unsupportedFilterException"
								message="JSON Fields are not supported for filtering at this time.">

						<cfelseif filterSet[v.currentKey] contains "*">
							<!--- Use LIKE instead of IN for wildcard support - leon 6/3/08 --->
							and (1=0
								<cfloop list="#filterSet[v.currentKey]#" index="v.currentValue">
									<cfset valueIsNull = iif(len(filterSet[v.currentKey]),0,1)>
									<cfif this.stColMetaData[v.currentKey].datatype eq "varchar">
										or lower(#v.currentKey#) like <cfqueryparam value="#lcase(replace(v.currentValue, '*', '%', 'all'))#" null="#valueIsNull#" cfsqltype="cf_sql_#this.stColMetaData[v.currentKey].datatype#" list="#NOT valueIsNull#">
									<cfelse>
										or #v.currentKey# like <cfqueryparam value="#replace(v.currentValue, '*', '%', 'all')#" null="#valueIsNull#" cfsqltype="cf_sql_#this.stColMetaData[v.currentKey].datatype#" list="#NOT valueIsNull#">
									</cfif>
								</cfloop>
							)

						<cfelse>
							<cfif this.stColMetaData[v.currentKey].datatype eq "varchar">
								and lower(#v.currentKey#) in ( <cfqueryparam value="#lcase(StructFind( filterSet, v.currentKey ))#" cfsqltype="cf_sql_#this.stColMetaData[v.currentKey].datatype#" list="yes"> )
							<cfelse>
								and #v.currentKey# in ( <cfqueryparam value="#StructFind( filterSet, v.currentKey )#" cfsqltype="cf_sql_#this.stColMetaData[v.currentKey].datatype#" list="yes"> )
							</cfif>
						</cfif>

					</cfif>
				</cfloop>
				<cfif usesTombstoning() and not arguments.includeDeleted >
					<cfif useIntForBool() >
						and deleted = 0
					<cfelse>
						and deleted = false
					</cfif>
				</cfif>
		</cfquery>

		<cfif getID.recordcount eq 1>
			<cfset IDtoLoad = getID.ID>
			<cfset load(ID=getID.ID, bUseCache=arguments.bUseCache, includeDeleted=arguments.includeDeleted)>
			<cfreturn true>
		<cfelse>
			<cfreturn false>
		</cfif>

	</cffunction> <!--- loadBy --->


	<cffunction name="loadByName" access="public" returntype="boolean" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="bUseCache" type="boolean" required="no" default="false">
		<cfargument name="filterField" type="string" required="no">
		<cfargument name="filterValue" type="string" required="no">
		<cfargument name="includeDeleted" type="boolean" required="false" default="0">

		<cfif (structKeyExists(arguments, 'filterField') or structKeyExists(arguments, 'filterValue'))
				and (not(structKeyExists(arguments, 'filterField')) or not(structKeyExists(arguments, 'filterValue')))>
			<cfthrow message="dbrow3.loadByName requires both filterField and filterValue if either is passed">
		</cfif>

		<cfif not(this.isInited)>
			<cfset init()>
		</cfif>

		<cfset v.cacheTime = cacheTimeout(arguments.bUseCache)>

		<cfquery name="getID" datasource="#this.datasource#" cachedWithin="#v.cacheTime#">
			select #theID# as ID
			from #theTable#
			where lower(#theNameField#) = '#lcase(arguments.name)#'
				<cfif structKeyExists(arguments, 'filterField')>
					<cfif this.stColMetaData[arguments.filterField].datatype eq "varchar">
						and lower(#arguments.filterField#) in (
							<cfqueryparam value="#lcase(arguments.filterValue)#"
								cfsqltype="cf_sql_#this.stColMetaData[arguments.filterField].datatype#"
								list="yes">
							)

					<cfelseif this.stColMetaData[arguments.filterField].datatype eq "json">
						<cfthrow type="com.singlebrook.dbrow3.unsupportedFilterException"
							message="JSON Fields are not supported for filtering at this time.">

					<cfelse>
						and #arguments.filterField# in ( <cfqueryparam value="#arguments.filterValue#" cfsqltype="cf_sql_#this.stColMetaData[arguments.filterField].datatype#" list="yes"> )
					</cfif>
				</cfif>
				<cfif usesTombstoning() and not arguments.includeDeleted >
					<cfif useIntForBool() >
						and deleted = 0
					<cfelse>
						and deleted = false
					</cfif>
				</cfif>
		</cfquery>

		<cfif getID.recordcount eq 1>
			<cfset IDtoLoad = getID.ID>
			<cfset load(ID=getID.ID, bUseCache=arguments.bUseCache, includeDeleted=arguments.includeDeleted)>
			<cfreturn true>
		<cfelse>
			<cfreturn false>
		</cfif>

	</cffunction> <!--- loadByName --->



	<cffunction name="logIt" returntype="void" output="no">
		<cfargument name="theText" type="string" required="yes">
		<cfif dbrow3Logging>
			<cflog file="dbrow3" text="#elapsed()# #theText#">
		</cfif>
	</cffunction> <!--- logIt --->



	<cffunction name="lookupColLinkingTo" returntype="string" output="no" access="package"
			hint="Determines which column in a table refers to a specified column in a specified table">
		<cfargument name="linkTable" type="string" required="yes">
		<cfargument name="linksToColumn" type="string" required="yes">
		<cfargument name="linksToTable" type="string" required="yes">

		<cfset var v = structNew()>

		<cfset v.stLinkFKs = getForeignKeyMetaData(linkTable)>

		<cfloop collection="#v.stLinkFKs#" item="v.i">
			<cfset v.stFK = v.stLinkFKs[v.i]>
			<cfif v.stFK.foreignColumn eq linksToColumn and v.stFK.foreignTable eq linksToTable>
				<cfreturn v.i>
			</cfif>
		</cfloop>

		<cfthrow message="Could not find column in table #linkTable# linking to #linksToTable#.#linksToColumn#">

	</cffunction> <!--- lookupColLinkingTo --->


	<cfscript>
	/* Sets up default values for this object (only theID
		by default). Used when creating a new row. */
	public dbrow3 function new(){
		if (NOT this.isInited) { init(); }

		/* Set properties to database defaults - leon 2/3/06 */
		for( var i in variables.properties ){
			if( Len(this.stColMetaData[i].default) ) {
				this[i] = this.stColMetaData[i].default;
			}
		}

		this.isStored = 0;

		/* Set "custom" defaults that aren't defined in the database - leon 2/3/06 */
		setDefaults();

		clearThisToManyData();

		return this;
	}
	</cfscript>

	<cffunction name="newError" returntype="struct" output="no" access="public">
		<cfargument name="propertyName" type="string" required="yes">
		<cfargument name="propertyLabel" type="string" required="yes">
		<cfargument name="errorText" type="string" required="yes">

		<cfreturn arguments>
	</cffunction> <!--- newError --->


	<cffunction name="queryToArray" returnType="array"
			hint="Takes a query containing rows from theTable and returns an array of theObject objects">

		<cfargument name="theQuery" type="query" required="yes">

		<cfset var v = structNew()>
		<cfset var theObjectPath = "#this.objectMap#.#lcase(this.theObject)#">

		<!--- If the dbrow3mapper singleton exists, it takes precedence for theObjectPath - Jared 12/13/07 --->
		<cfif structKeyExists(application, 'dbrow3mapper')>
			<cfset theObjectPath = application.dbrow3mapper.getObjPathFromTable(this.theTable)>
		</cfif>

		<cfset v.arTmp = arrayNew(1)>

		<cfloop query="theQuery">
			<cfquery name="v.rsOneRow" dbtype="query" maxrows="1">
				select * from theQuery
				where #theID# = <cfqueryparam value="#theQuery[theID][currentRow]#" cfsqltype="cf_sql_#this.stColMetaData[theID].datatype#">
			</cfquery>
			<cfset v.oTmp = createObject('component', theObjectPath ).new()>
			<cfset v.oTmp.load(rsValues = v.rsOneRow, includeDeleted = true )>
			<cfset arrayAppend(v.arTmp, v.oTmp)>
		</cfloop>

		<cfreturn v.arTmp>

	</cffunction> <!--- queryToArray --->


	<cffunction name="saveForm" returntype="void" output="yes" access="remote"
			hint="Accesses the form scope to populate and save this object. Form must include [theID] and goto.">

		<cfset var v = structNew()>

		<!--- Check to make sure the user has permissions --->
		<cfif StructKeyExists( url, "method" ) and url.method eq "saveForm">
			<cfset checkRemoteMethodAuthorization() >
		</cfif>

		<cfset init()>

		<cfif len(form[this.theID])>
			<cfset load(id=form[this.theID],includeDeleted='yes')>
		<cfelse>
			<cfset new()>
		</cfif>

		<cfset loadform(structKeyList(form))>

		<cfset v.arErrors = getErrorArray()>
		<cfif arrayLen(v.arErrors)>
			<!--- Redisplay the edit form with the errors included. - leon 12/9/08 --->
			<cfset edit(id = form[this.theID], goto = form.goto, arErrors = v.arErrors, stValues = form)>

		<cfelse>
			<!--- No errors were found! - leon 12/9/08 --->
			<cfset store(getID=1)>
			<cflocation url="#goto#" addtoken="no">
		</cfif>

	</cffunction> <!--- saveForm --->


	<cffunction name="setDefaults" access="package"
			hint="This is a skeleton function. Child objects should implement their own setDefaults function.">

	</cffunction> <!--- setDefaults --->


	<cffunction name="setField" returntype="void" access="package">
		<cfset initializeRenderer()>
		<cfreturn this.renderer.setField(argumentCollection = arguments)>
	</cffunction>


	<cffunction name="setLabel" returntype="void" access="package">
		<cfset initializeRenderer()>
		<cfreturn this.renderer.setLabel(argumentCollection = arguments)>
	</cffunction>


	<cffunction name="setManyRelatedIDs" returntype="void" output="no" access="public"
			hint="Sets a list of IDs of the items in the named relationship">
		<cfargument name="relName" type="variableName" required="yes"
				hint="The name of the relationship given in the initial hasMany()">
		<cfargument name="IDList" type="string" required="yes"
				hint="Comma-delimited list of IDs">

		<cfset var v = structNew()>

		<cfif not(structKeyExists(this.stMany, relName))>
			<cfthrow message="#theObject#.stMany has no information about the relationship #relName#">
		</cfif>

		<!--- Remove empty elements from the ID list - Jared 12/30/08 --->
		<cfset v.arIDs = ListToArray(arguments.IDList)>
		<cfset v.IDListClean = ArrayToList(v.arIDs)>

		<!--- Don't process if the list has been loaded and is un-changed. - leon 4/22/08 --->
		<cfif not(this.stMany[relName].loaded and listSort(this.stMany[relName].idList, 'numeric') eq listSort(v.IDListClean, 'numeric'))>

			<cfset this.stMany[relName].idList = v.IDListClean>
			<!--- "dirty" means it needs to be stored - leon 4/22/08 --->
			<cfset this.stMany[relName].dirty = 1>

		</cfif>

	</cffunction> <!--- setManyRelatedIDs --->


	<cfscript>
	/* Updates the stOrigState struct, containing the original
		(empty or database) state of the object */
	package boolean function setOrigState(){
		for (i in variables.properties) {
			StructUpdate(this.stOrigState, i, StructFind(this, i));
		}

		return true;
	}
	</cfscript>

	<cffunction name="store"
			returnType="boolean"
			hint="Saves the object data in the object to the database">

		<cfargument name="bBreakCache" type="boolean" required="no" default="yes">
		<cfargument name="getID" type="boolean" required="no" default="no">

		<cfset var v = structNew()>

		<cfset beforeStore()>

		<cfset v.arErrors = getErrorArray()>
		<cfif arrayLen(v.arErrors)>
			<cfset v.errorList = "">
			<cfloop from="1" to="#arrayLen(v.arErrors)#" index="v.i">
				<cfset v.errorList = v.errorList & "* " & v.arErrors[v.i].propertyName & " " & v.arErrors[v.i].errorText & "<br />">
			</cfloop>
			<cfthrow message="Found data validation errors. Refusing to store(). You should check your data first." detail="#v.errorList#">
		</cfif>

		<cftransaction>

			<cfset firstOne = 1>

			<!--- UPDATE --->
			<cfif this.isStored>
				<cfset IDToUpdate = this[theID]>

				<cfif not(len(IDToUpdate))>
					<cfthrow type="com.singlebrook.dbrow3.updateNullIDException"
						message="The ID field should never be null when updating an existing record">
				</cfif>

				<cfquery name="update#theObject#" datasource="#this.datasource#">
					update #theTable#
					set
						<cfloop array="#variables.properties#" index="i">
							<cfif (i neq theID) and not(listFindNoCase(this.theFieldsToSkip, i))>
								<cfset thisVal = this[i]>
								<cfif NOT IsBinary(thisVal) AND IsSimpleValue(thisVal)>
									<!--- The following preserveSingleQuotes is necessary in CF 6 and below - Jared 2/5/07 --->
									<cfset thisVal = trim(preserveSingleQuotes(thisVal))>
								</cfif>
								<cfif firstOne><cfset firstOne = 0><cfelse>,</cfif>
								#i# =
									<cfif len(thisVal)>
										<cfif listFindNoCase('char,varchar,text', this.stColMetaData[i].datatype)>
											<!--- This is a workaround for MySQL, which seems to double single-quotes when strings are passed in via
												cfqueryparam, regardless of the preserveSingleQuotes(). - leon 2/18/06 --->
											<cfif useQueryParamForText()>
												<cfqueryparam value="#thisVal#" cfsqltype="cf_sql_varchar">
											<cfelseif useEscapedBackslashes()>
												'#replace(thisVal, '\', '\\', 'all')#'
											<cfelse>
												'#thisVal#'
											</cfif>
										<cfelseif val(this.stColMetaData[i].decimalPlaces)>
											<!--- Need to specify scale for these otherwise they'll get rounded to integers - leon 2/18/06 --->
											<cfqueryparam value="#thisVal#" cfsqltype="cf_sql_#this.stColMetaData[i].datatype#" scale="#this.stColMetaData[i].decimalPlaces#">
										<cfelseif this.stColMetaData[i].datatype eq "bit">
											<cfif useIntForBool()>
												<!--- Some versions of MySQL don't seem to like cf_sql_bit. Workaround this by saving as an integer. - leon 4/6/06 --->
												<cfqueryparam value="#thisVal#" cfsqltype="cf_sql_integer">
											<cfelse>
												<cfqueryparam value="#thisVal#" cfsqltype="cf_sql_bit">
											</cfif>
										<cfelseif this.stColMetaData[i].datatype eq "json">
											<cfset var serializedVal = IsJson(thisVal) ? thisVal : SerializeJSON(thisVal)>
											<cfif useQueryParamForText()>
												<cfqueryparam value="#serializedVal#" cfsqltype="cf_sql_varchar">
											<cfelse>
												'#serializedVal#'
											</cfif>
										<cfelse>
											<cfqueryparam value="#thisVal#" cfsqltype="cf_sql_#this.stColMetaData[i].datatype#">
										</cfif>
									<cfelse>
										null
									</cfif>
							</cfif>
						</cfloop>
					where #theID# = <cfqueryparam value="#IDToUpdate#" cfsqltype="cf_sql_#this.stColMetaData[theID].datatype#">
				</cfquery>

			<!--- INSERT --->
			<cfelse>

				<cfscript>
				/* Populate fieldsToInsertList */
				if ( NOT IsDefined('this.fieldsToInsertList') ) {
					this.fieldsToInsertList = "";
					for ( var i in variables.properties ) {
						if ( NOT ListFindNoCase(this.theFieldsToSkip, i) ) {
							this.fieldsToInsertList = ListAppend(this.fieldsToInsertList, i);
						}
					}
				}
				</cfscript>

				<cflock name="create#theObject#" type="exclusive" timeout="30">

					<cfquery name="insert#theObject#" datasource="#this.datasource#">
						insert into #theTable# (#this.fieldsToInsertList#)
						values(
							<cfloop array="#variables.properties#" index="i">
								<cfif not(listFindNoCase(this.theFieldsToSkip, i))>
									<cfset thisVal = this[i]>
									<cfif NOT isBinary(thisVal) AND IsSimpleValue(thisVal)>
										<cfset thisVal = trim(thisVal)>
									</cfif>
									<cfif firstOne><cfset firstOne = 0><cfelse>,</cfif>
									<cfif NOT IsSimpleValue(thisVal) OR Len(thisVal)>

										<cfif listFindNoCase('char,varchar,text', this.stColMetaData[i].datatype)>
											<!--- This is a workaround for MySQL, which seems to double single-quotes
												when strings are passed in via cfqueryparam, regardless of
												the preserveSingleQuotes(). - leon 2/18/06 --->
											<cfif useQueryParamForText()>
												<cfqueryparam value="#thisVal#" cfsqltype="cf_sql_varchar">
											<cfelseif useEscapedBackslashes()>
												'#replace(thisVal, '\', '\\', 'all')#'
											<cfelse>
												'#thisVal#'
											</cfif>

										<cfelseif val(this.stColMetaData[i].decimalPlaces)>
											<!--- Need to specify scale for these otherwise they'll get rounded to integers - leon 2/18/06 --->
											<cfqueryparam value="#thisVal#" cfsqltype="cf_sql_#this.stColMetaData[i].datatype#" scale="#this.stColMetaData[i].decimalPlaces#">

										<cfelseif this.stColMetaData[i].datatype eq "bit">
											<cfif useIntForBool()>
												<!--- Some versions of MySQL don't seem to like cf_sql_bit. Workaround this by saving as an integer. - leon 4/6/06 --->
												<cfqueryparam value="#thisVal#" cfsqltype="cf_sql_integer">
											<cfelse>
												<cfqueryparam value="#thisVal#" cfsqltype="cf_sql_bit">
											</cfif>

										<cfelseif this.stColMetaData[i].datatype eq "json">
											<cfset var serializedVal = IsJson(thisVal) ? thisVal : SerializeJSON(thisVal)>
											<cfif useQueryParamForText()>
												<cfqueryparam value="#serializedVal#" cfsqltype="cf_sql_varchar">
											<cfelse>
												'#serializedVal#'
											</cfif>

										<cfelse>
											<cfqueryparam value="#thisVal#" cfsqltype="cf_sql_#this.stColMetaData[i].datatype#">

										</cfif>
									<cfelse>
										null
									</cfif>
								</cfif>
							</cfloop>
						)
					</cfquery>

					<cfif arguments.getID>
						<cfquery name="getNewID" datasource="#this.datasource#">
							select max(#theID#) as newID
							from #theTable#
						</cfquery>

						<cfset this[theID] = getNewID.newID>
					</cfif>

				</cflock>

			</cfif>

		</cftransaction>

		<cfset this.isStored = 1>
		<cfset setOrigState()>
		<cfset afterStore()>

		<cfreturn true>
	</cffunction> <!--- store --->


	<cffunction name="useEscapedBackslashes" returnType="boolean" access="public" output="no">
		<cfreturn 0>
	</cffunction> <!--- useEscapedBackslashes --->


	<cffunction name="useIntForBool" returnType="boolean" access="public" output="no"
			hint="Most databases have a bit or boolean datatype. Some (mySQL) don't, and don't like the
				cf_sql_bit datatype. Children can override this function to return 1 if they need to use
				an int instead of a bit/bool.">
		<cfreturn 0>
	</cffunction> <!--- useIntForBool --->


	<cffunction name="usesTombstoning" returnType="boolean" access="public" output="no">
		<cfreturn ArrayFindNoCase(variables.properties,"deleted") GT 0>
	</cffunction> <!--- usesTombstoning --->


	<cffunction name="usesTombstoningTimestamp" returnType="boolean" access="public" output="no">
		<cfreturn ArrayFindNoCase(variables.properties,"deleted_timestamp") GT 0>
	</cffunction> <!--- usesTombstoningTimestamp --->


	<cffunction name="usesTombstoningUserID" returnType="boolean" access="public" output="no">
		<cfreturn ArrayFindNoCase(variables.properties,"deleted_user_id") GT 0>
	</cffunction> <!--- usesTombstoningUserID --->


	<cffunction name="useQueryParamForText" returnType="boolean" access="public" output="no">
		<cfreturn 1>
	</cffunction> <!--- useQueryParamForText --->


	<cffunction name="getProperty">
		<cfargument name="property" required="true" type="string">

		<cfreturn structFind(this, property)>
	</cffunction> <!--- getProperty --->


	<cffunction name="hasProperty" returnType="boolean">
		<cfargument name="property" required="true" type="string">
		<cfreturn ArrayFindNoCase( variables.properties, arguments.property ) GT 0 >
	</cffunction> <!--- hasProperty --->


	<cffunction name="setProperty">
		<cfargument name="property" required="true" type="string">
		<cfargument name="value" required="true">

		<cfset structUpdate(this, property, value)>
	</cffunction> <!--- setProperty --->

	<cffunction name="loadForm"
			output="true"
			returntype="boolean"
			hint="Populates instance fields with values from HTML form. Assumes corresponding
			form fields and properties have the same names.">

		<cfargument name="fieldNameList" type="string" required="true">

		<cfset var listPos = "">
		<cfset var propertyName = "">

		<cfscript>
			try {
				/* Set properties by evaluating form fields with the same names. */
				for (listPos = 1; listPos lte listLen(fieldNameList); listPos = listPos +1) {
					propertyName = listGetAt(fieldNameList, listPos);
					if (structKeyExists(this, propertyName) and structKeyExists(form, propertyName))
						structUpdate(this, propertyName, form[propertyName]);
				}
				return true;
			} catch (Any excpt) {
				writeOutput("<p>" & excpt & "</p>");
				writeOutput("Properties could not be set to form field values. Make sure corresponding properties and form fields have the same name.");
				return false;
			}
		</cfscript>
	</cffunction> <!--- loadForm --->


	<cfscript>
	/* Populates the properties of this instance with values from the provided struct. */
	public void function loadStruct(required struct stProperties){
		for( var prop in arguments.stProperties ) {
			/* The IsDefined protects against "[undefined struct element]" - Jared 1/13/09 */
			if( ArrayFindNoCase(variables.properties, prop)
					AND StructKeyExists(arguments.stProperties, prop) ){
				this[prop] = arguments.stProperties[prop];
			}
		}
	}
	</cfscript>


	<cffunction name="setTypeByID"
			output="false"
			returntype="void"
			hint="Sets the objects type object based on an ID value.  Called by load only when an object can have a type.">

		<cfargument name="typeID" type="string" required="true">

		<cfset var typeMetaData = this.stFKMetaData[typeIDField] >
		<cfset var tableName = typeMetaData.foreignTable >
		<cfset var typeObjPath = application.dbrow3mapper.getTypeObj( tableName = tableName, id = typeID ) >
		<cfset this.typeObj = createObject( "component", typeObjPath ) >
		<cfset this.typeObj.load( typeID ) >

	</cffunction>


	<cffunction name="setTypeByImmutableName"
			output="false"
			returntype="void"
			hint="Sets the objects type object based on an immutable name value.  Called by setDefaults only when an object can have a type.">

		<cfargument name="immutableName" type="string" required="true">

		<cfset var typeMetaData = this.stFKMetaData[typeIDField] >
		<cfset var tableName = typeMetaData.foreignTable >
		<cfset var typeObjPath = application.dbrow3mapper.getTypeObj( tableName = tableName, immutableName = immutableName ) >
		<cfset this.typeObj = createObject( "component", typeObjPath ) >
		<cfset this.typeObj.init() >
		<cfset this.typeObj.loadBy( filterField = this.typeObj.theImmutableNameField, filterValue = arguments.immutableName ) >

		<!--- Set the ID if it is not already set --->
		<cfif Not( Len( StructFind( this, this.typeIDField ) ) ) >
			<cfset StructUpdate( this, this.typeIDField, this.typeObj.id ) >
		</cfif>

	</cffunction>

</cfcomponent>
