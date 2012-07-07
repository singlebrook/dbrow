<cfscript>

testSuite = createObject("component","mxunit.framework.TestSuite").TestSuite();

unitTestCFCs = ['instantiation_test', 'load_test', 'label_test',
	'drawForm_test', 'drawFormField_test', 'drawPropertyValue_test',
	'drawStandardFormField_test', 'edit_test', 'formValidation_test'];

for(i=1; i <= ArrayLen(unitTestCFCs); i++) {
  testSuite.addAll("units.dbrow." & unitTestCFCs[i]);
}
results = testSuite.run();

</cfscript>
<cfoutput>#results.getResultsOutput('extjs')#</cfoutput>
