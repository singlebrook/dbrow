<cfcomponent extends="mxunit.framework.TestCase">
<cfscript>

public void function setUp() {
  new Query(sql = "delete from tblArthropod", datasource = application.datasource).execute();
  new Query(sql = "delete from tblSubphylum", datasource = application.datasource).execute();
}

public void function beforeTests() {
  arthropod_factory = CreateObject('support.factories.arthropod_factory');
	subphylum_factory = CreateObject('support.factories.subphylum_factory');
}


private string function normalizeWhitespace(required string str) {
	return REReplace(str, '\s{2,}', ' ', 'all');
}

</cfscript>
</cfcomponent>
