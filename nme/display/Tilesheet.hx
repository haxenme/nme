package nme.display;
#if (cpp || neko)

import nme.geom.Matrix;
import nme.geom.Point;
import nme.geom.Rectangle;
import nme.Loader;

class Tilesheet 
{
   public static inline var TILE_SCALE = 0x0001;
   public static inline var TILE_ROTATION = 0x0002;
   public static inline var TILE_RGB = 0x0004;
   public static inline var TILE_ALPHA = 0x0008;
   public static inline var TILE_TRANS_2x2 = 0x0010;
   public static inline var TILE_BLEND_NORMAL = 0x00000000;
   public static inline var TILE_BLEND_ADD = 0x00010000;

   // TODO
   public static inline var TILE_BLEND_SCREEN = 0x00000000;
   public static inline var TILE_BLEND_MULTIPLY = 0x00000000;

   /** @private */ public var nmeBitmap:BitmapData;
   /** @private */ public var nmeHandle:Dynamic;
   public function new(inImage:BitmapData) 
   {
      nmeBitmap = inImage;
      nmeHandle = nme_tilesheet_create(inImage.nmeHandle);
   }

   public function addTileRect(rectangle:Rectangle, centerPoint:Point = null):Int 
   {
      return nme_tilesheet_add_rect(nmeHandle, rectangle, centerPoint);
   }

   public function drawTiles(graphics:Graphics, tileData:Array<Float>, smooth:Bool = false, flags:Int = 0):Void 
   {
      graphics.drawTiles(this, tileData, smooth, flags);
   }

   // Native Methods
   private static var nme_tilesheet_create = Loader.load("nme_tilesheet_create", 1);
   private static var nme_tilesheet_add_rect = Loader.load("nme_tilesheet_add_rect", 3);
}

#end
