<cfscript>

testSuite = createObject("component","mxunit.framework.TestSuite").TestSuite();

files = DirectoryList(ExpandPath('.') & '/units', true, 'path');

for (i = 1; i <= ArrayLen(files); i++) {
  if (files[i] contains "_test.cfc") {
    relative_file = ReReplace(files[i], '^.*/units', 'units');
    relative_file_no_ext = ReReplace(relative_file, '.cfc$', '');
    dottedComponentPath = Replace(relative_file_no_ext, '/', '.', 'all');
    testSuite.addAll(dottedComponentPath);
  }
}

results = testSuite.run();

WriteOutput(results.getResultsOutput('extjs'));
</cfscript>
