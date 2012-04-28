<cfparam name="URL.output" default="extjs">
<cfscript>
  testSuite = createObject("component","mxunit.framework.TestSuite").TestSuite();
  testSuite.addAll("units.instantiation_test");
  testSuite.addAll("units.load_test");
  results = testSuite.run();
</cfscript>
<cfoutput>#results.getResultsOutput(URL.output)#</cfoutput>
