package nme.format.swf;

import nme.display.GraphicsLike;
import nme.geom.Matrix;

class ScaledFont  implements nme.text.Font
{
   var mFont : nme.format.swf.Font;
   var mMatrix : Matrix;
   var mHeight: Int;
   var mScale : Float;
   var mAscent : Float;

   public function new(inFont:nme.format.swf.Font,inHeight : Int)
   {
      mFont = inFont;
      mHeight = inHeight;
      mScale = inHeight / 1024.0;
      mMatrix = new Matrix();
      mMatrix.scale(mScale,mScale);
      mAscent = GetAscent();
   }

   public function GetName():String { return mFont.GetName(); }
   public function GetHeight():Int { return mHeight; }
   public function CanRenderSolid():Bool { return false; }
   public function CanRenderOutline():Bool { return true; }

   public function Render(inGfx:GraphicsLike,inChar:Int,inX:Int,inY:Int,inOutline:Bool):Int
   {
      mMatrix.tx = inX;
      mMatrix.ty = inY + mAscent;
      return Std.int( mFont.RenderChar(inGfx,inChar,mMatrix) * mScale);
   }

   public function GetAdvance(inChar:Int):Int { return Std.int(mFont.GetAdvance(inChar) * mScale); }
   public function GetAscent() : Int  { return Std.int(mFont.GetAscent() * mScale); }
   public function GetDescent() : Int { return Std.int(mFont.GetDescent() * mScale); }
   public function GetLeading() : Int { return Std.int(mFont.GetLeading() * mScale); }


}
