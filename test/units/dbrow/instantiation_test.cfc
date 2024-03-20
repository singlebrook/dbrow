<cfcomponent extends="dbrow.test.units.abstract_testcase">
<cfscript>

public void function test_can_instantiate() {
	obj = CreateObject('arthropod');
	assertFalse(obj.isInited);
	assertFalse(obj.isInitialized);
	assertFalse(obj.isStored);
}

public void function test_can_initialize() {
	obj = CreateObject('arthropod').init();
	assertTrue(obj.isInited);
	assertTrue(obj.isInitialized);
	assertFalse(obj.isStored);
}

</cfscript>
</cfcomponent>
