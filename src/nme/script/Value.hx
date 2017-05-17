package nme.script;

enum Value
{
   VMap(name:String);
   VValue(value:Dynamic);
   VMember(instance:Dynamic,fieldName:String);
}

