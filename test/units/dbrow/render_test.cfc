<cfcomponent extends="dbrow.test.units.abstract_testcase">
<cfscript> // <script type="text/javascript">

  public void function can_label() {
    obj = CreateObject('arthropod');
    
    /* Assuming that a certain label has been set in
    arthropod.cfc .. -Jared 4/28/12 */
    assertEquals('Creepy crawly', obj.getLabel('arthropod_name'));
  }

</cfscript> <!--- </script> --->
</cfcomponent>
