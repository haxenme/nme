package nme.geom;

class GeomTools
{
   inline public static function centerX(rect:Rectangle) return rect.x + rect.width*0.5;
   inline public static function centerY(rect:Rectangle) return rect.y + rect.height*0.5;
}
