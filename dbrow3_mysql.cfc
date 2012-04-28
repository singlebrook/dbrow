<cfcomponent name="dbrow3_mysql"
	extends="dbrow3">

	<cffunction name="getColumnMetaData" returntype="struct" access="public" output="yes">
		<cfset var rsMetaData = "">
		<cfset var stColMetaData = structNew()>
		<cfset var thisCol = "">


		<cfquery name="rsMetaData" datasource="#this.datasource#" cachedwithin="#request.timeLong#">
			select character_maximum_length, column_default, column_name, data_type, numeric_scale,
				is_nullable, ordinal_position
			from information_schema.columns
			where lower(table_name) = '#lcase(this.theTable)#'
				and table_schema = '#application.mysql_schema#'
		</cfquery>

		<cfoutput query="rsMetaData">
			<cfset stColMetaData[column_name] = structNew()>
			<cfset thisCol = stColMetaData[column_name]>
			<cfset thisCol.datatype = translateDataType(data_type)>
			<cfset thisCol.maxlen = character_maximum_length>
			<cfset thisCol.default = translateDefault(column_default,thisCol.datatype)>
			<cfset thisCol.notNull = not(is_nullable)>
			<cfset thisCol.decimalPlaces = numeric_scale>
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
			select column_name, referenced_table_name, referenced_column_name
			from information_schema.key_column_usage
			where lower(table_name) = lower('#tableName#')
				and referenced_table_name is not null
				and table_schema = '#application.mysql_schema#'
		</cfquery>

		<cfoutput query="rsFKs">
			<cfset localColumn = column_name>
			<cfif structKeyExists(stFKMetaData, localColumn)>
				<cfthrow message="Found two foreign keys for column '#localColumn#'">
			</cfif>
			<cfset structInsert(stFKMetaData, localColumn, structNew())>
			<cfset thisFK = stFKMetaData[localColumn]>
			<cfset thisFK.localColumn = localColumn>
			<cfset thisFK.foreignTable = referenced_table_name>
			<cfset thisFK.foreignColumn = referenced_column_name>

		</cfoutput>

		<cfreturn stFKMetaData>

	</cffunction> <!--- getForeignKeyMetaData --->


	<cffunction name="translateDataType" returntype="string" access="private" output="yes">
		<cfargument name="nativeType" type="string" required="yes">

		<cfscript>
			switch (nativeType) {
				// Numeric Types
				case "bigint" : return "bigint"; break;
				case "bit" : return "bit"; break;
				case "decimal" : return "decimal"; break;
				case "double" : return "float"; break;
				case "float" : return "float"; break;
				case "int" : return "integer"; break;
				case "integer" : return "integer"; break;
				case "mediumint" : return "integer"; break;
				case "numeric" : return "decimal"; break;
				case "real" : return "float"; break;
				case "smallint" : return "smallint"; break;
				case "tinyint" : return "bit"; break;

				// Date Types
				case "date" : return "date"; break;
				case "datetime" : return "timestamp"; break;
				case "time" : return "time"; break;
				case "timestamp" : return "timestamp"; break;
				case "year" : return "numeric"; break;

				// String Type
				case "binary" : return "binary"; break;
				case "blob" : return "binary"; break;
				case "char" : return "char"; break;
				case "longblob" : return "binary"; break;
				case "longtext" : return "varchar"; break;
				case "mediumblob" : return "binary"; break;
				case "mediumtext" : return "varchar"; break;
				case "text" : return "varchar"; break;
				case "tinyblob" : return "binary"; break;
				case "tinytext" : return "varchar"; break;
				case "varbinary" : return "binary"; break;
				case "varchar" : return "varchar"; break;
			}
		</cfscript>

	</cffunction> <!--- translateDataType --->


	<cffunction name="translateDefault" returntype="string" access="private" output="yes">
		<cfargument name="defaultString" type="string" required="yes">
		<cfargument name="dataType" type="string" required="yes">

		<cfreturn defaultString>

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


	<cffunction name="useEscapedBackslashes" returnType="boolean" access="public" output="no"
			hint="Blackslashes can be used to escape single-quotes and do mischief
				in mysql, so escape them for safety. Note that cfqueryparam should
				do this for us, but we can't use it for text due to the single-quote
				doubling problem.">
	 <cfreturn 1>
	</cffunction> <!--- useEscapedBackslashes --->


	<cffunction name="useIntForBool" returnType="boolean" access="public" output="no"
			hint="mySQL doesn't like the cf_sql_bit datatype. This function override will cause dbrow to
				use cf_sql_integer instead.">
		<cfreturn 1>
	</cffunction> <!--- useIntForBool --->


	<cffunction name="useQueryParamForText" returnType="boolean" access="public" output="no"
			hint="MySQL seems to double single-quotes when strings are passed in via cfqueryparam,
				regardless of the preserveSingleQuotes(). So, we don't use it.">
	 <cfreturn 0>
	</cffunction> <!--- useQueryParamForText --->

</cfcomponent>