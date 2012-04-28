<cfcomponent extends="dbrow.test.units.abstract_testcase">
<cfscript> // <script type="text/javascript">

  public void function can_instantiate() {
    obj = CreateObject('arthropod');
    assertFalse(obj.isInited);
    assertFalse(obj.isInitialized);
    assertFalse(obj.isStored);
  }

  public void function can_initialize() {
    obj = CreateObject('arthropod').init();
    assertTrue(obj.isInited);
    assertTrue(obj.isInitialized);
    assertFalse(obj.isStored);
  }

</cfscript> <!--- </script> --->
</cfcomponent>
