<cfcomponent extends="mxunit.framework.TestCase">
<cfscript>

public void function beforeTests() {
	arthropod_factory = CreateObject('support.factories.arthropod_factory');
}


private string function normalizeWhitespace(required string str) {
	return REReplace(str, '\s{2,}', ' ', 'all');
}

</cfscript>
</cfcomponent>
