<cfscript> // <script type="text/javascript">

testSuite = createObject("component","mxunit.framework.TestSuite").TestSuite();

unitTestCFCs = ['instantiation_test', 'load_test', 'label_test',
	'drawPropertyValue_test'];

for(i=1; i <= ArrayLen(unitTestCFCs); i++) {
  testSuite.addAll("units.dbrow." & unitTestCFCs[i]);
}
results = testSuite.run();

</cfscript>
<cfoutput>#results.getResultsOutput('extjs')#</cfoutput>
