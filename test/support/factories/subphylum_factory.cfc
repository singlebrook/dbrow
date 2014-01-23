<cfcomponent>
<cfscript>

public component function create(subphylum_name = "") {
  var obj = CreateObject('subphylum').new();

  if (arguments.subphylum_name == "")
    arguments.subphylum_name = random_subphylum_name();

  obj.subphylum_name = arguments.subphylum_name;
  obj.store(getID = true);
  return obj;
}


private string function random_subphylum_name() {
  var names = ['Trilobitomorpha', 'Chelicerata', 'Myriapoda',
    'Crustacea', 'Hexapoda'];
  var ix = RandRange(1, ArrayLen(names));
  return names[ix];
}

</cfscript>
</cfcomponent>
