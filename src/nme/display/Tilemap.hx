package nme.display;

import nme.events.*;
import nme.utils.Float32Buffer;

class Tilemap extends Shape
{
   public static inline var DIRTY_BASE = 0x0000001;
   public var smoothing:Bool;
   public var dirtyFlags:Int;
   public var tiles:Array<Tile>;

   var attribFlags:Int;
   var nmeWidth:Int;
   var nmeHeight:Int;
   var drawList:Float32Buffer;
   var tilesheet:Tilesheet;

   public function new(inWidth:Int, inHeight:Int, inTilesheet:Tilesheet = null, inSmoothing:Bool = true)
   {
      super();
      dirtyFlags = attribFlags = 0;
      tilesheet = inTilesheet;
      nmeWidth = inWidth;
      nmeHeight = inHeight;
      smoothing = inSmoothing;
      tiles = [];
      addEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
   }

   public function addTile(tile:Tile) : Tile
   {
      if (tile.nmeOwner!=null)
         tile.nmeOwner.removeTile(tile);
      tile.nmeOwner = this;
      // Todo - others?
      dirtyFlags |= DIRTY_BASE;
      tiles.push(tile);

      return tile;
   }
   public function removeTile(tile:Tile) : Tile
   {
      tiles.remove(tile);
      tile.nmeOwner = null;
      return tile;
   }


   function onAddedToStage(_)
   {
      removeEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
      addEventListener( Event.REMOVED_FROM_STAGE, onRemovedFromStage );
      nme.Lib.current.stage.addPrerenderListener( onPrerender );
      drawList = new Float32Buffer(16,true);
      nme.NativeResource.lock(drawList);
   }
   function onRemovedFromStage(_)
   {
      removeEventListener( Event.REMOVED_FROM_STAGE, onRemovedFromStage );
      addEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
      nme.Lib.current.stage.removePrerenderListener( onPrerender );
      nme.NativeResource.unlock(drawList);
      //nme.NativeResource.disposeHandler(drawList);
      drawList = null;
   }


   function rebuild()
   {
      var gfx = graphics;
      gfx.clear();
      var n = tiles.length;
      if (n>0)
      {
         var attribCount = 2;
         var flags = 0;

         var hasId =  tilesheet.tileCount>1;
         if (hasId)
            attribCount++;
         else
            flags |= Tilesheet.TILE_NO_ID;

         drawList.resize( n * attribCount );
         var idx = 0;
         for(tile in tiles)
         {
            drawList.setF32q(idx++, tile.x);
            drawList.setF32q(idx++, tile.y);
            if (hasId)
               drawList.setF32q(idx++, tile.id);
         }

         tilesheet.drawTiles(gfx, drawList, smoothing, flags );
      }
   }

   function onPrerender()
   {
      if (dirtyFlags!=0)
      {
         attribFlags |= dirtyFlags & (~DIRTY_BASE);
         dirtyFlags = 0;
         rebuild();
      }
   }

}

