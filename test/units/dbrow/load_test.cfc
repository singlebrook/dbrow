<cfcomponent extends="dbrow.test.units.abstract_testcase">
<cfscript>

  public void function can_load() {
    var factory = CreateObject('support.factories.arthropod_factory');
    var createdObj = factory.create();
    obj = CreateObject('arthropod').load(createdObj.arthropodID);
    assertTrue(obj.isStored);
    assertEquals(createdObj.arthropod_name, obj.arthropod_name);
    assertEquals(createdObj.arthropodID, obj.arthropodID);
  }

</cfscript>
</cfcomponent>
