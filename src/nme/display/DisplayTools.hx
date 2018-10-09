package nme.display;

class DisplayTools
{
   inline public static function ellipse(gfx:Graphics, cx:Float, cy:Float, radX:Float, radY:Float)
      gfx.drawEllipse(cx-radX, cy-radY, radX*2, radY*2 );
}
