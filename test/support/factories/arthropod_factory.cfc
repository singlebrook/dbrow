<cfcomponent>
<cfscript>

public component function create() {
  var obj = CreateObject('arthropod').new();
  obj.arthropod_name = "Honey Bee";
  obj.store(getID = true);
  return obj;
}

</cfscript>
</cfcomponent>
