package nme;

@:cppFileCode( 'extern "C" void nme_register_prims();')
@:buildXml("
<target id='haxe'>
  <lib name='${haxelib:nme}/lib/${BINDIR}/libnme${LIBEXTRA}${LIBEXT}'/>
</target>
<include name='${haxelib:nme}/lib/OsLink.xml'/>
")
@:keep class StaticNme
{
   static function __init__()
   {
     untyped __cpp__("nme_register_prims();");
   }
}


