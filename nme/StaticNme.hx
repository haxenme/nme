package nme;

@:cppFileCode( 'extern "C" void nme_register_prims();')
#if new_link
@:buildXml("
<set name='NME_STATIC_LINK' value='1' />
<import name='${haxelib:nme}/project/Build.xml'/>
<target id='haxe'>
  <merge id='nme-target'/>
</target>
")
#else
@:buildXml("
<target id='haxe'>
  <lib name='${haxelib:nme}/lib/${BINDIR}/libnme{MSVC_VER}${LIBEXTRA}${LIBEXT}'/>
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


