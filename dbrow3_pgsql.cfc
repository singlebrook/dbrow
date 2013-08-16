<cfcomponent name="dbrow3_pgsql"
	extends="dbrow3">

	<cffunction name="getColumnMetaData" returntype="struct" access="public" output="yes">
		<cfset var rsMetaData = "">
		<cfset var stColMetaData = structNew()>
		<cfset var thisCol = "">

		<cfquery name="rsMetaData" datasource="#this.datasource#" cachedwithin="#this.timeLong#">
			select character_maximum_length, column_default, column_name, data_type, datetime_precision,
				interval_precision, interval_type, is_nullable, numeric_precision, numeric_precision_radix,
				numeric_scale, ordinal_position
			from information_schema.columns
			where lower(table_name) = '#lcase(this.theTable)#'
		</cfquery>

		<!--- Assert that at least one column was found - Jared 2012-04-30 --->
		<cfif rsMetaData.RecordCount EQ 0>
			<cfthrow message="Table #this.theTable# either does not exist or has zero columns">
		</cfif>

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

		<cfreturn stColMetaData>
	</cffunction> <!--- getColumnMetaData --->


	<cffunction name="getForeignKeyMetaData" returntype="struct" access="public" output="yes">
		<cfargument name="tableName" type="string" required="no" default="#this.theTable#"
				hint="Can be used to retrieve FK data for linking tables, etc.">

		<cfset var rsFKs = "">
		<cfset var stFKMetaData = structNew()>
		<cfset var thisFK = "">

		<!--- Load single-column foreign keys only - leon 4/21/08 --->
		<!--- WARNING: Name your foreign key constraints uniquely!  This query does
		not support schema with duplicate FK names.  (see below) - Jared 10/2/09 --->
		<!--- NOTE: This query is slow. Most of the time it gets cached by the
		mapper, but if you have a lot of objects, your application startup time can
		be quite long. The information_schema is known to be slow, as each relation
		is really a fairly complex view. - leon 9/28/09 --->
		<cfquery name="rsFKs" datasource="#this.datasource#" cachedwithin="#this.timeLong#">
			SELECT kcu.column_name,
				ccu.table_name AS references_table,
				ccu.column_name AS references_field
			FROM information_schema.table_constraints tc
				LEFT JOIN information_schema.key_column_usage kcu
					ON tc.constraint_catalog = kcu.constraint_catalog
						AND tc.constraint_schema = kcu.constraint_schema
						AND tc.table_name = kcu.table_name
						AND tc.constraint_name = kcu.constraint_name

				<!--- The join between table_constraints and referential_constraints is
				flawed, because it uses only the constraint name, and not the table name
				(on which the constraint is defined). This means that if you do not name
				your foreign key constraints uniquely, you can get the wrong data back.
				I don't know how to fix this while still using the information_schema
				because referential_constraints doesn't contain table_name and
				table_constraints doesn't contain unique_constraint_name. - leon 9/28/09 --->
				LEFT JOIN information_schema.referential_constraints rc
					ON tc.constraint_catalog = rc.constraint_catalog
						AND tc.constraint_schema = rc.constraint_schema
						AND tc.constraint_name = rc.constraint_name
				LEFT JOIN information_schema.constraint_column_usage ccu
					ON rc.unique_constraint_catalog = ccu.constraint_catalog
						AND rc.unique_constraint_schema = ccu.constraint_schema
						AND rc.unique_constraint_name = ccu.constraint_name
			WHERE tc.table_name = lower('#tableName#')
				AND tc.constraint_type = 'FOREIGN KEY'

				AND tc.constraint_name in (

					<!--- This subquery identifies the single-key foreign keys - leon 4/21/08 --->
					SELECT tc.constraint_name
					FROM information_schema.table_constraints tc
						LEFT JOIN information_schema.key_column_usage kcu
							ON tc.constraint_catalog = kcu.constraint_catalog
								AND tc.constraint_schema = kcu.constraint_schema
								AND tc.table_name = kcu.table_name
								AND tc.constraint_name = kcu.constraint_name
						LEFT JOIN information_schema.referential_constraints rc
							ON tc.constraint_catalog = rc.constraint_catalog
								AND tc.constraint_schema = rc.constraint_schema
								AND tc.constraint_name = rc.constraint_name
						LEFT JOIN information_schema.constraint_column_usage ccu
							ON rc.unique_constraint_catalog = ccu.constraint_catalog
								AND rc.unique_constraint_schema = ccu.constraint_schema
								AND rc.unique_constraint_name = ccu.constraint_name
					WHERE tc.table_name = lower('#tableName#')
						and tc.constraint_type = 'FOREIGN KEY'
					GROUP BY tc.constraint_name
					HAVING count(kcu.column_name) = 1

				)
		</cfquery>

		<cfoutput query="rsFKs">
			<cfset structInsert(stFKMetaData, column_name, structNew())>
			<cfset thisFK = stFKMetaData[column_name]>
			<cfset thisFK.localColumn = column_name>
			<cfset thisFK.foreignTable = references_table>
			<cfset thisFK.foreignColumn = references_field>
		</cfoutput>

		<cfreturn stFKMetaData>

	</cffunction> <!--- getForeignKeyMetaData --->


	<cffunction name="translateDataType" returntype="string" access="private" output="yes">
		<cfargument name="nativeType" type="string" required="yes">

		<cfscript>
			switch (nativeType) {
				case "char" : return "char"; break;
				case "bigint" : return "bigint"; break;
				case "boolean" : return "bit"; break;
				case "bytea" : return "blob"; break;
				case "character" : return "varchar"; break;
				case "character varying" : return "varchar"; break;
				case "date" : return "date"; break;
				case "double precision" : return "float"; break;
				case "integer" : return "integer"; break;
				case "json" : return "varchar"; break;
				case "money" : return "decimal"; break;
				case "numeric" : return "decimal"; break;
				case "real" : return "float"; break;
				case "smallint" : return "integer"; break;
				case "text" : return "varchar"; break;
				case "time with time zone" : return "time"; break;
				case "time without time zone" : return "time"; break;
				case "timestamp with time zone" : return "timestamp"; break;
				case "timestamp without time zone" : return "timestamp"; break;
				case "uuid" : return "other"; break;
			}
		</cfscript>

		<!--- Execution should not reach this point. If it does, we've encountered an unhandled datatype. - leon 8/31/06 --->
		<cfthrow message="dbrow3_pgsql.translateDataType() doesn't understand the native type '#nativeType#'">

	</cffunction> <!--- translateDataType --->


	<cffunction name="translateDefault" returntype="string" access="private" output="yes">
		<cfargument name="defaultString" type="string" required="yes">
		<cfargument name="dataType" type="string" required="yes">

		<cfif not(len(arguments.defaultString))>
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
		</cfif>

	</cffunction>	<!--- translateDefault --->


	<cffunction name="useEscapedBackslashes" returnType="boolean" access="public" output="no"
			hint="Blackslashes can be used to escape single-quotes and do mischief
				in pgsql, so escape them for safety. Note that cfqueryparam should
				do this for us, but we can't use it for text due to the single-quote
				doubling problem.">
	 <cfreturn 1>
	</cffunction> <!--- useEscapedBackslashes --->


	<cffunction name="useQueryParamForText" returnType="boolean" access="public" output="no"
			hint="CF seems to double single-quotes when strings are passed in via cfqueryparam,
				regardless of the preserveSingleQuotes(). So, we don't use it.">
	 <cfreturn 0>
	</cffunction> <!--- useQueryParamForText --->
</cfcomponent>
