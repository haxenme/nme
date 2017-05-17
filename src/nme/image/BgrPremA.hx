package nme.image;
import nme.native.Include;

import cpp.UInt8;

@:structAccess
@:native("nme::BGRPremA")
@:include("nme/Pixel.h")
extern class BgrPremA
{
   public var pixelFormat(default,never):Int;

   public var b:UInt8;
   public var g:UInt8;
   public var r:UInt8;
   public var a:UInt8;

   public var ival:Int;

   public function getAlpha():Int;
   public function getRAlpha():Int;
   public function getGAlpha():Int;
   public function getBAlpha():Int;
   public function getR():Int;
   public function getG():Int;
   public function getB():Int;
   public function getLuma():Int;

   public function setR(val:Int):Void;
   public function setG(val:Int):Void;
   public function setB(val:Int):Void;
   public function setRAlpha(val:Int):Void;
   public function setGAlpha(val:Int):Void;
   public function setBAlpha(val:Int):Void;
   public function setAlpha(val:Int):Void;
   public function setLuma(val:Int):Void;

}



