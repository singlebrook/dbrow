<cfcomponent extends="dbrow.test.units.abstract_testcase">
<cfscript>

public void function test_can_load() {
	var createdObj = arthropod_factory.create();
	obj = CreateObject('arthropod').load(createdObj.arthropodID);
	assertTrue(obj.isStored);
	assertEquals(createdObj.arthropod_name, obj.arthropod_name);
	assertEquals(createdObj.arthropodID, obj.arthropodID);
}

</cfscript>
</cfcomponent>
