Analysis of Responsibilities within dbrow3.cfc
===========================

by Jared Beck
2012-04-28

Associations
--------------
- clearThisToManyData
- getForeignKeyCol
- getLinkingTableInfo - Returns a structure with information about the important columns in a linking table
- getManyRelatedArray
- getManyRelatedIDs
- getManyRelatedRS
- hasMany - Relationship name that we can use to retrieve the related elements later
- lookupColLinkingTo - Determines which column in a table refers to a specified column in a specified table
- setManyRelatedIDs

Callbacks
-----------
- afterDelete
- afterLoad
- afterStore
- beforeDelete
- beforeLoad
- beforeStore

Constructor
------------
- init
- initializeObject
- setDefaults

Controller
-----------
- checkRemoteMethodAuthorization
- saveForm - Accesses the form scope to populate and save this object. Form must include [theID] and goto

Database Adapter Configuration
------------------------------
- useEscapedBackslashes
- useIntForBool
- useQueryParamForText

Loading
-----------
- cacheTimeout
- cacheTimeoutDefault
- load
- loadBy
- loadByName
- queryToArray - Takes a query containing rows from theTable and returns an array of theObject objects

Logging
-----------
- elapsed
- logIt

Mass Assignment
----------------
- loadForm
- loadStruct

Math
----------
- listIntersection - Returns the case-sensitive intersection of two lists

Persistence
------------
- clear - Clears this object's properties so that it can be safely load()ed again with a new ID
- delete - Delete this object's data from the database
- getIsStored
- getTableName
- new - Sets up default values for this object (only theID by default). Used when creating a new row.
- store

Polymorphism
------------
- setTypeByID
- setTypeByImmutableName

Properties
-----------
- getCachedColumnMetaData
- getCachedForeignKeyMetaData
- getColDataType
- getIDColumn
- getNameColumn
- getNotNull
- getPropertyList
- getPropertyValue
- getProperty
- hasProperty
- setProperty

Rendering
------------
- drawPropertyValue *
- drawForm *
- drawFormEnd *
- drawFormField *
- drawFormErrorSummary
- drawFormStart
- drawStandardFormField *
- drawErrorField
- edit
- getLabel *
- getDefaultTabIndex *
- getTabIndexAttr *
- setField *
- setLabel *

\* These methods have been delegated to the `dbrow_renderer`

Tombstoning
-----------
- isDeleted
- usesTombstoning
- usesTombstoningTimestamp
- usesTombstoningUserID

Tracking Changes
----------------
- getChanges
- setOrigState

Validation
-----------
- addValidation
- getError
- getErrorArray
- getErrorStruct
- getValidationAttribs - Returns attributes to be used in form field tag. These attributes are processed by formvalidation.js
- newError
