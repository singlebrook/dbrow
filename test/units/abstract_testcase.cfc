<cfcomponent extends="mxunit.framework.TestCase">
<cfscript>

private string function normalizeWhitespace(required string str) {
	return REReplace(str, '\s{2,}', ' ', 'all');
}

</cfscript>
</cfcomponent>
