<cfsetting showdebugoutput="no">
<cfscript>

testSuite = createObject("component","mxunit.framework.TestSuite").TestSuite();

files = DirectoryList(ExpandPath('.') & '/units', true, 'path');

for (i = 1; i <= ArrayLen(files); i++) {
  if (files[i] contains "_test.cfc") {
    relative_file = ReReplace(files[i], '^.*/units', 'units');
    relative_file_no_ext = ReReplace(relative_file, '.cfc$', '');
    component = Replace(relative_file_no_ext, '/', '.', 'all');
    // This needs to be a component path like ''
    testSuite.addAll(component);
  }
}

results = testSuite.run();

</cfscript>
<cfoutput>#results.getResultsOutput('extjs')#</cfoutput>
