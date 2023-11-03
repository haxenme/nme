package nme;

@:cppFileCode('extern "C" int nme_register_prims();')
#if !nmelink
@:build(nme.macros.BuildXml.importRelative("../../../project/ToolkitBuild.xml"))
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
      #if (cpp && !cppia)
      untyped __cpp__("nme_register_prims();");
      #end
   }
}


