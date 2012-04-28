<cfcomponent name="dbrow3_mssql"
	extends="dbrow3">

	<cffunction name="getColumnMetaData" returntype="struct" access="public" output="yes">
		<cfset var rsMetaData = "">
		<cfset var stColMetaData = structNew()>
		<cfset var thisCol = "">

		<cfquery name="rsMetaData" datasource="#this.datasource#" cachedwithin="#request.timeLong#">
			sp_columns '#this.theTable#'
		</cfquery>

		<cfoutput query="rsMetaData">
			<cfset stColMetaData[column_name] = structNew()>
			<cfset thisCol = stColMetaData[column_name]>
			<cfset thisCol.datatype = translateDataType(type_name)>
			<cfset thisCol.maxlen = char_octet_length>
			<cfset thisCol.default = translateDefault(column_def,thisCol.datatype)>
			<cfset thisCol.notNull = not(trim(is_nullable))>
			<cfif listFindNoCase('decimal,float', thisCol.datatype)>
				<cfset thisCol.decimalPlaces = scale>
			<cfelse>
				<cfset thisCol.decimalPlaces = "">
			</cfif>
			<cfset thisCol.sortorder = ordinal_position>
		</cfoutput>

		<!--- <cfdump var="#rsMetaData#">
		<cfdump var="#stColMetaData#"> - leon 2/3/06 --->

		<cfreturn stColMetaData>
	</cffunction> <!--- getColumnMetaData --->


	<cffunction name="getForeignKeyMetaData" returntype="struct" access="public" output="yes">
		<cfargument name="tableName" type="string" required="no" default="#this.theTable#"
				hint="Can be used to retrieve FK data for linking tables, etc.">

		<cfset var rsFKs = "">
		<cfset var stFKMetaData = structNew()>
		<cfset var thisFKList = "">
		<cfset var arThisFK = "">
		<cfset var localColumn = "">
		<cfset var thisFK = "">

		<cfquery name="rsFKs" datasource="#this.datasource#" cachedwithin="#request.timeLong#">
			sp_fkeys @fktable_name = '#tableName#'
		</cfquery>

		<cfoutput query="rsFKs">
			<cfset localColumn = fkcolumn_name>
			<cfif structKeyExists(stFKMetaData, localColumn)>
				<cfthrow message="Found two foreign keys for column '#localColumn#'">
			</cfif>
			<cfset structInsert(stFKMetaData, localColumn, structNew())>
			<cfset thisFK = stFKMetaData[localColumn]>
			<cfset thisFK.localColumn = localColumn>
			<cfset thisFK.foreignTable = pktable_name>
			<cfset thisFK.foreignColumn = pkcolumn_name>

		</cfoutput>

		<cfreturn stFKMetaData>

	</cffunction> <!--- getForeignKeyMetaData --->


	<cffunction name="translateDataType" returntype="string" access="private" output="yes">
		<cfargument name="nativeType" type="string" required="yes">

		<cfscript>
			switch (nativeType) {
				// Numeric Types
				case "bigint" : return "bigint";
				case "bigint identity" : return "bigint";
				case "bit" : return "bit";
				case "decimal" : return "decimal";
				case "float" : return "float";
				case "int" : return "integer";
				case "int identity" : return "integer";
				case "money" : return "decimal";
				case "numeric" : return "decimal";
				case "real" : return "float";
				case "smallint" : return "smallint";
				case "smallint identity" : return "smallint";
				case "smallmoney" : return "decimal";
				case "tinyint" : return "tinyint";

				// Date Types
				case "datetime" : return "timestamp";
				case "datetime2" : return "timestamp";
				case "smalldatetime" : return "timestamp";
				case "timestamp" : return "timestamp";

				// String Type
				case "binary" : return "binary";
				case "blob" : return "binary";
				case "char" : return "char";
				case "image" : return "binary";
				case "nchar" : return "char";
				case "ntext" : return "varchar";
				case "nvarchar" : return "varchar";
				case "text" : return "varchar";
				case "varbinary" : return "binary";
				case "varchar" : return "varchar";
				case "uniqueidentifier" : return "varchar";
			}

		</cfscript>

		<cfthrow message="dbrow3_mssql.translateDataType() doesn't understand the datatype '#nativeType#'">

	</cffunction> <!--- translateDataType --->


	<cffunction name="translateDefault" returntype="string" access="private" output="yes">
		<cfargument name="defaultString" type="string" required="yes">
		<cfargument name="dataType" type="string" required="yes">

		<cfset defaultString = REReplace(defaultString, "(^\(|\)$)", '', 'all')>
		<cfset defaultString = REReplace(defaultString, "(^\(|\)$)", '', 'all')>
		<cfreturn REReplace(defaultString, "(^'|'$)", '', 'all')>

		<!--- <cfif not(len(arguments.defaultString))>
			<cfreturn "">
		<cfelseif left(arguments.defaultString, len('nextval(')) eq "nextval(">
			<!--- This is a serial field. Don't put the nextval() function in the default. - leon 2/3/06 --->
			<cfreturn "">
		<cfelse>
			<!--- Remove cast - leon 2/3/06 --->
			<cfset defaultString = REReplace(defaultString,'::.*$','')>
			<cfif datatype eq "varchar">
				<cfset defaultString = REReplace(defaultString, "(^'|'$)", "", "all")>
			</cfif>
			<cfreturn defaultString>
		</cfif> - leon 2/8/06 --->

	</cffunction>	<!--- translateDefault --->

	<cffunction name="useQueryParamForText" returnType="boolean" access="public" output="no">
	 <cfreturn 0>
	</cffunction> <!--- useQueryParamForText --->

</cfcomponent>
