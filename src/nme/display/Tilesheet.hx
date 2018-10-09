package nme.display;

import nme.geom.*;
import nme.Loader;
import nme.NativeHandle;

@:nativeProperty
class Tilesheet 
{
   public static inline var TILE_SCALE        = 0x0001;
   public static inline var TILE_ROTATION     = 0x0002;
   public static inline var TILE_RGB          = 0x0004;
   public static inline var TILE_ALPHA        = 0x0008;
   public static inline var TILE_TRANS_2x2    = 0x0010;
   public static inline var TILE_RECT         = 0x0020;
   public static inline var TILE_ORIGIN       = 0x0040;
   public static inline var TILE_NO_ID        = 0x0080;
   public static inline var TILE_BLEND_NORMAL = 0x00000000;
   public static inline var TILE_BLEND_ADD = 0x00010000;

   // TODO
   public static inline var TILE_BLEND_SCREEN = 0x00000000;
   public static inline var TILE_BLEND_MULTIPLY = 0x00000000;
   public static inline var TILE_BLEND_SUBTRACT = 0x00000000;


   public var nmeBitmap:BitmapData;
   public var tileCount(default,null):Int;

   #if !flash

   public var nmeHandle:NativeHandle;

   public function new(inImage:BitmapData, ?rects:Array<Rectangle>) 
   {
      tileCount = 0;
      nmeBitmap = inImage;
      nmeHandle = nme_tilesheet_create(inImage.nmeHandle);
      if (rects!=null)
         for(rect in rects)
            addTileRect(rect);
   }

   public function addTileRect(rectangle:Rectangle, centerPoint:Point = null):Int 
   {
      tileCount++;
      return nme_tilesheet_add_rect(nmeHandle, rectangle, centerPoint);
   }

   

   public function getTileRect(index:Int, ?result:Rectangle):Rectangle
   {
      if (result == null)
      {
        result =  new Rectangle();
      }
      nme_tilesheet_get_rect(nmeHandle, index, result);
      return result;
   }

   public function drawTiles(graphics:Graphics, tileData:nme.utils.Floats3264, smooth:Bool = false, flags:Int = 0, count:Int=-1):Void 
   {
      graphics.drawTiles(this, tileData, smooth, flags, count);
   }

   // Native Methods
   private static var nme_tilesheet_create = Loader.load("nme_tilesheet_create", 1);
   private static var nme_tilesheet_add_rect = Loader.load("nme_tilesheet_add_rect", 3);
   private static var nme_tilesheet_get_rect = Loader.load("nme_tilesheet_get_rect", 3);

   #else

   var tiles:Array<Rectangle>;
   var centres:Array<Point>;


   public function new(inImage:BitmapData) 
   {
      nmeBitmap = inImage;
      tiles = [];
      centres = [];
   }

   public function addTileRect(rectangle:Rectangle, centerPoint:Point = null):Int 
   {
      tileCount++;
      var result = tiles.length;
      tiles.push(rectangle);
      centres.push(centerPoint);
      return result;
   }
   
   public function getTileRect(index:Int):Rectangle
   {
       return tiles[index];
   }
    

   public function drawTiles(graphics:Graphics, tileData:Array<Float>, smooth:Bool = false, flags:Int = 0, count:Int=-1):Void 
   {
      //TODO
      //graphics.drawTiles(this, tileData, smooth, flags, count);
   }


   #end

   inline public function getRect(index:Int):Rectangle return getTileRect(index);

   inline public function addRect(rectangle:Rectangle) return addTileRect(rectangle);

}

