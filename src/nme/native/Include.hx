package nme.native;

@:buildXml("
   <files id='haxe'>
      <compilerflag value='-I${haxelib:nme}/include'/>
      <compilerflag value='-I${haxelib:nme}/../include'/>
      <compilerflag value='-DHX_UNDEFINE_H'/>
   </files>
")
@:keep
class Include {  }
