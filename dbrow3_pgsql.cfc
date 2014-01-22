<cfcomponent name="dbrow3_pgsql"
	extends="dbrow3">

	<cffunction name="caseSensitiveComparisons" returntype="boolean" output="no" access="public"
			hint="Specifies whether the RDBMS uses case-sensitive comparisons for IN, LIKE, and =.
				If an adapter returns a true value, dbrow will do extra work to make comparisons
				case-insensitive.">
		<cfreturn true>
	</cffunction>

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
		<cfquery name="rsFKs" datasource="#this.datasource#" cachedwithin="#this.timeLong#">
			select a1.attname as column_name, c2.relname as references_table, a2.attname as references_field

			/* The catalog pg_constraint stores check, primary key, unique, foreign
			key, and exclusion constraints on tables. */
			from pg_constraint t

			/* pg_attribute stores information about table columns.  The join's
			on-clause (specifically the `ANY()`) supports compound FKCs, however
			see the note below about why compound FKCs are omitted. -Jared 2013-10-18 */
			inner join pg_attribute a1
				on a1.attnum = ANY(t.conkey) /* conkey - constrained columns */
				and a1.attrelid = t.conrelid

			inner join pg_attribute a2
				on a2.attnum = ANY(t.confkey) /* confkey - referenced columns */
				and a2.attrelid = t.confrelid

			/* conrelid - The table this constraint is on */
			inner join pg_class c1 on c1.oid = t.conrelid

			/* confrelid - the referenced table */
			inner join pg_class c2 on c2.oid = t.confrelid

			where c1.relname = lower(<cfqueryparam value="#arguments.tableName#" cfsqltype="cf_sql_varchar">)
				and t.contype = 'f' /* f = foreign key constraint */

				/* To preserve backwards compatability, omit FKCs with "system
				names" like $1, $2.  In the future, we should consider including
				these. -Jared 2013-10-18 */
				and t.conname !~ '^[$]'

				/* Omit compound FKCs.  This is primarily to preserve backwards
				compatability.  Secondarily, I suspect that dbrow does not support
				compound FKCs. -Jared 2013-10-18 */
				and array_length(t.conkey, 1) = 1
				and array_length(t.confkey, 1) = 1
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
				case "json" : return "json"; break;
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
