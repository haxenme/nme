package nme.native;

import cpp.UInt8;

@:structAccess
@:native("nme::ARGB")
extern class ARGB
{
   var b:UInt8;
   var g:UInt8;
   var r:UInt8;
   var a:UInt8;
}

