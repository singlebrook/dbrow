<cfcomponent extends="dbrow.test.units.abstract_testcase">
<cfscript> // <script type="text/javascript">

  public void function can_label() {
    obj = CreateObject('arthropod');
    
    /* Assuming that a label for arthropod_name has been set in
    arthropod.cfc .. -Jared 4/28/12 */
    assertEquals('Creepy crawly', obj.getLabel('arthropod_name'));

    /* Assuming that a label for arthropodID has NOT been set in
    arthropod.cfc .. -Jared 4/28/12 */
    assertEquals('arthropodID', obj.getLabel('arthropodID'));
  }

</cfscript> <!--- </script> --->
</cfcomponent>
