package nme;

@:cppFileCode('extern "C" void nme_register_prims();')
#if new_link
@:build(nme.macros.BuildXml.importRelative("../../project/Build.xml"))
#else
@:buildXml("
<target id='haxe'>
  <lib name='${haxelib:nme}/lib/${BINDIR}/libnme${LIBEXTRA}${LIBEXT}'/>
</target>
<include name='${haxelib:nme}/lib/NmeLink.xml'/>
")
#end
@:keep class StaticNme
{
   static function __init__()
   {
     untyped __cpp__("nme_register_prims();");
   }
}


