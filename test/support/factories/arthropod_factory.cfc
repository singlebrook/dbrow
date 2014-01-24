<cfcomponent>
<cfscript>

public component function create(String arthropod_name = "Honey Bee") {
  var obj = CreateObject('arthropod').new();
  obj.arthropod_name = arguments.arthropod_name;
  obj.store(getID = true);
  return obj;
}

</cfscript>
</cfcomponent>
