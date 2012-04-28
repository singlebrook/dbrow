<cfparam name="URL.output" default="extjs">
<cfscript>
  testSuite = createObject("component","mxunit.framework.TestSuite").TestSuite();
  testSuite.addAll("units.dbrow.instantiation_test");
  testSuite.addAll("units.dbrow.load_test");
  results = testSuite.run();
</cfscript>
<cfoutput>#results.getResultsOutput(URL.output)#</cfoutput>
