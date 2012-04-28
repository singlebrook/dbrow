# DBRow 3.1 Technical Documentation

by Jared Beck and Leon Miller-Out of [Singlebrook Technology](http://www.singlebrook.com)

## Contents



1. Introduction
    1. Overview
    1. Requirements
    1. Features
1. Usage
    1. Data Definition (Tables)
    1. ColdFusion Components (CFCs)
    1. When tables do not follow naming conventions
    1. Soft Deletion (Tombstoning)
1. Appendix
    1. History
    1. Features that need documentation



# Introduction

## Overview

DBRow and DBSet constitute an Object-Relational-Mapping (ORM) system for
ColdFusion MX. The original goal was to promote the DRY principle (Do not Repeat
Yourself) by using the structure of database tables to automatically populate
objects with properties and data. It was later discovered to be an
implementation of the Active Record design pattern.

### Creating a new record

	<cfset w = CreateObject('component', 'widget')>
	<cfset w.new()>
	<cfset w.widget_name = "Rocket">

	<cfset w.year_invented = "282">

	<cfset w.inventor = "Emperor Carinus">

	<cfset w.store(getID = 1)> 
	<cfoutput>The primary key of the new record is #w.widgetid#</cfoutput>

### Updating a record

	<cfset w = CreateObject('component', 'widget')>
	<cfset w.load(url.widgetID)>
	<cfset w.widget_name = form.widget_name>
	<cfset w.store()>

### Deleting a record

	<cfset w = CreateObject('component', 'widget')>
	<cfset w.load(url.widgetID)>
	<cfset w.delete()>

Dbrow also supports soft-deletion (tombstoning) if the underlying table has a
'deleted' column.  See below for more details.

## Requirements

### Server software

<table cellpadding="0" cellspacing="0">
	<thead>
		<th>DBRow Version</th>
		<th>ColdFusion Versions</th>
		<th>RDBMSs</th>
	</thead>
	<tbody>
		<tr>
			<td>3.1</td>
			<td>8+</td>
			<td>MSSQL,PostgreSQL,MySQL</td>
		</tr>
		<tr>
			<td>3.0</td>
			<td>6.1+</td>
			<td>MSSQL,PostgreSQL,MySQL</td>
		</tr>
		<tr>
			<td>2</td>
			<td>6.1+</td>
			<td>MSSQL,PostgreSQL,MySQL</td>
		</tr>
		<tr>
			<td>1</td>
			<td>6.1+</td>
			<td>None in particular</td>
		</tr>
	</tbody>
</table>

### Application setup

The application must have the following variables set:
- request.timeLong - a timespan, usually set to createTimeSpan(0,2,0,0). Used for caching purposes.
- request.timeNone - a timespan set to createTimeSpan(0,0,0,0). Used for caching purposes.

The application may have the following variables set to reduce configuration code required in model and set objects' pseudoconstructors:
- application.datasource - the name of a ColdFusion datasource pointing to the database where the objects are persisted.
- application.objectMap - a ColdFusion mapping (in dot-delimited format) that points to the folder where the dbrow objects live. If you want to organize your dbrow objects into sub-folders, use dbrow3mapper.
- application.dbrow3mapper
- application.dbrow3cache


## Features

- Automatic CRUD (Create, Read, Update, Delete) methods. These are provided by the store(), load(), store(), and delete() methods respectively.
	- Stub methods provide hooks for attaching custom code pre- and post- all CRUD operations. (e.g. beforeStore(), afterLoad())
- Remotely-accessible List/Edit views (including New and Delete functions) allow for the rapid development of a basic administration area with a minimum of .cfm files.
- Automatic analysis of foreign key constraints provides support for 1-to-1 and 1-to-many relationships, including rendering of lists of related items in Edit view. Many-to-many relationships are also supported, but must be manually defined, and do not yet have an automatically-generated GUI.
- Custom form fields can be created with setField(). Custom fields can include the standard fields with drawStandardFormField().
- Data validation
	- Data is automatically validated before store().
	- Custom validation rules can be added with addValidation().
	- Client-side validation is handled by formvalidation.js (svn+ssh://svn.singlebrook.com/svn/_shared/trunk/_js/formval/formvalidation.js).
			See that file for usage instructions. dbrow3.getValidationAttribs(propertyName) will give you the necessary attributes to put in your input tag.
	- Server-side validation uses database metadata (datatypes, NOT NULL, etc) and custom rules
		- getErrorArray() returns an array of validation errors. If you want a struct, use getErrorStruct().
		- getError(arErrors, propertyName) gives you the error message for a specific property.



# Usage

## Data Definition

Create the database and the tables that will support your application.  Follow dbrow naming conventions for table and column names (see below).

`CREATE TABLE tblWidget ( widgetid [whatever auto-increment your RDMS wants] primary key, widget_name text, year_invented integer, inventor text );` 

### Naming Conventions

Follow these naming conventions to reduce object pseudoconstructor configuration.

- Table name: tbl#theObject#
- Primary key: #theObject#ID
- Object name: #theObject#_name
- Datasource: #application.datasource#

## ColdFusion Components

### Model object

Create a CFC that extends one of the RDBMS-specific versions. Instances of this object represent one row in your table.

	<cfcomponent name="widget" extends="com.singlebrook.dbrow3_1.dbrow3_mysql">
		<cfset theObject = "widget">
		<!--- Additional configuration here if necessary (see Configuration Options) --->
	</cfcomponent>

#### Configuration Options

##### Variables

These optional variables may be set in the model object's pseudoconstructor.

__theID__ - Specifies the primary key column. Default is "#theObject#ID".

__theTable__ - Specifies the name of the table in the database. Default is "tbl#theObject#".

__theDatasource__ - Specifies the ColdFusion datasource that points to the database. Default is #application.datasource#.

__theFieldsToSkip__ - Comma-separated list of columns that will not be inserted/updated when an instance is store()ed. This should include the 
primary key column if it is an auto-incrementing field. Default is the empty string.

__theNameField__ - Specifies which column will be used as an instance's name. Used in various places, but notably in loadByName(). Default is
"#theObject#_name".

__hiddenFieldList__ - Comma-separated list of columns that will not be displayed when drawForm() is called.

__theObjectMap__ - Specifies a ColdFusion mapping (in dot-delimited format) that points to the folder where the dbrow objects live. Default is
"#application.objectMap#".

__binaryFieldList__ - Comma-separated list of columns that hold binary data. This should be deprecated in favor of inspecting the column metadata.


##### Methods

These methods may be called in the model object's pseudoconstructor to control the behavior of the listing and form drawing methods.

__setLabel(column, label)__ - Overrides the default label for a column. Default labels are constructed by replacing underscores in the
column name with spaces, then capitalizing the first letter of each word.

__setField(column, fieldHTML)__ - Overrides the default form field for a column. Default form fields are based on column metadata (type
and length) and foreign keys.

### Set object

Create a CFC that extends dbset3. This object will be used to search for and load up multiple objects as a recordset or array.

	<cfcomponent name="widget_set" extends="com.singlebrook.dbrow3_1.dbset3">

		<cfset theObject = "widget">
		<!--- Additional configuration here if necessary (see Set Configuration Options) --->
		<cfset this.init()>
	</cfcomponent>

#### Configuration Options

##### Variables

These optional variables may be set in the set object's pseudoconstructor.

__Coming Soon__


## When tables do not follow naming conventions

When the table does not follow naming conventions, extra configuration is necessary in the object pseudoconstructor. E.g.:

	CREATE TABLE noncoventional (

		noncoventional-primarykey integer,

		noncoventional-name text

	);

	<cfcomponent name="widget" extends="com.singlebrook.dbrow3_1.dbrow3_mysql">

		<cfscript>

			theObject = "noncoventional";

			theID = "noncoventional-primarykey";

			theTable = "noncoventional";

			theDatasource = "myCFDatasource";

			theNameField = "noncoventional-name";

		</cfscript>

	</cfcomponent>


## Soft Deletion (Tombstoning)

> "Your app deleted my record!"

We often implement soft deletion to help troubleshoot and recover from
accidental record deletion by app users.

If the table has a 'deleted' column, dbrow3.delete() will set deleted = true
instead of actually deleting the record.  The name of the 'deleted' column
is not configurable.

Attempts to load() a soft-deleted record will throw
com.singlebrook.dbrow3.LoadDeletedRecordException.  If you have a good
reason to load() a soft-deleted record, then use load()'s includeDeleted argument.



# Appendix

## History

### V1
dbrow - Given a datasource and table name, handles CRUD (Create, Read, Update, Delete) functionality, automatically generating object properties based on database columns.

dbset - Very little built-in functionality other than generic getAll() method.

### V2
dbrow2 - Major new features include:

- Property datatypes and bound variables in SQL queries. This necessitates the addition of RDBMS-specific adapters that map RDBMS native datatypes to ColdFusion datatypes and query the database for the necessary metadata.
- Automatic analysis of 1-to-many relationships
- Form-drawing capability, including automatic generation of dropdowns of related items for fields with foreign key constraints
- Support for client-side form validation via formvalidation.js

dbset2 - Begins to encapsulate more useful functionality. Major new features include:

- List view with configurable fields. Links to dbrow2's edit view for editing items.

New related Singleton objects that improve performance and flexibility of dbrow2 and dbset2. 

- dbrow2mapper - Maps object names to table names, etc.
- dbrow2cache - Caches metadata information to speed up object instantiation.

### V3

dbrow3 - Major new features include:

- Automatic tombstoning of objects (instead of outright deletion)
- Support for many-to-many relationships (currently in code only, not yet supported in form fields).
- Server-side data validation based on database properties and custom rules
- Updates to dbrow3mapper to understand types
	
dbset3 - Additions include:

- More filtering options in getAll()
- Tombstoning support to hide tombstoned items by default.

## Features that need documentation

- Form and field drawing
- Configuration options for dbset objects
- Associations
- Usage of _set objects
- Data validation (server and client-side)
- dbrow3mapper
- dbrow3cache
- Object "type" system