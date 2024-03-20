<cfcomponent extends="dbrow.test.units.abstract_testcase">
<cfscript>

public void function test_store() {
	var newCITextTest = CreateObject('testCIText').new();
	newCITextTest.test_citext = 'FooBar Blat';
	assert(newCITextTest.store());
}

</cfscript>
</cfcomponent>
