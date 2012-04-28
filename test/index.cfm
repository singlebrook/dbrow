<cfparam name="URL.output" default="extjs">
<cfscript>
 testSuite = createObject("component","mxunit.framework.TestSuite").TestSuite();
 testSuite.addAll("instantiation_test");
 results = testSuite.run();
</cfscript>  
<cfoutput>#results.getResultsOutput(URL.output)#</cfoutput>  
