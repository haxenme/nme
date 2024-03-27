package;

import openfl.display.FPS;
import openfl.display.Sprite;
#if nme
import openfl.display.Tilesheet;
#else
import openfl.display.Tile;
import openfl.display.Tilemap;
import openfl.display.Tileset;
#end
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.Assets;


class Main extends Sprite
{
   private var addingBunnies:Bool;
   private var bunnies:Array<Bunny>;
   private var fps:FPS;
   private var bunnyCount:TextField;
   private var gravity:Float;
   private var minX:Int;
   private var minY:Int;
   private var maxX:Int;
   private var maxY:Int;
   #if nme
   private var tilesheet:Tilesheet;
   private var drawList:nme.utils.Float32Buffer;
   #else
   private var tilemap:Tilemap;
   private var tileset:Tileset;
   #end


   public function new()
   {
      super();

      trace("--");
      for(ext in nme.gl.GL.getSupportedExtensions())
         if (ext.indexOf("draw_buffer")>=0 || ext.indexOf("frame")>=0)
            trace("  " + ext);
      trace("--");

      bunnies = new Array();
      minX = 0;
      maxX = 800;
      minY = 0;
      maxY = 600;
      gravity = 0.5;

      var bitmapData = Assets.getBitmapData("assets/wabbit_alpha.png");
      #if nme
      tilesheet = new Tilesheet(bitmapData);
      tilesheet.addTileRect(new nme.geom.Rectangle(0, 0, bitmapData.width, bitmapData.height));
      drawList = new nme.utils.Float32Buffer(200);
      nme.NativeResource.lock(drawList);
      #else
      tileset = new Tileset(bitmapData);
      tileset.addRect(bitmapData.rect);
      tilemap = new Tilemap(800, 600, tileset);
      addChild(tilemap);
      #end

      #if nme
      var dpi = nme.system.Capabilities.screenDPI;
      var dpiScale = Math.max(dpi/120,1);
      #else
      var dpiScale = 1.0;
      #end

      fps = new FPS();
      fps.background = true;
      fps.backgroundColor = 0xffffff;
      fps.scaleX = fps.scaleY = dpiScale;
      flash.Lib.current.addChild(fps);
      bunnyCount = new TextField();
      bunnyCount.text = "?";
      bunnyCount.y = 40*dpiScale;
      bunnyCount.background = true;
      bunnyCount.backgroundColor = 0xffffff;
      bunnyCount.autoSize = openfl.text.TextFieldAutoSize.LEFT;
      bunnyCount.scaleX = bunnyCount.scaleY = dpiScale;
      flash.Lib.current.addChild(bunnyCount);

      stage.addEventListener(MouseEvent.MOUSE_DOWN, stage_onMouseDown);
      stage.addEventListener(MouseEvent.MOUSE_UP, stage_onMouseUp);
      stage.addEventListener(Event.ENTER_FRAME, stage_onEnterFrame);
      stage.addEventListener(Event.RESIZE, function(_) setSize() );

      for(i in 0...100)
         addBunny();

      bunnyCount.text = "bunies:" + bunnies.length;
      #if nme
      drawList.resize(bunnies.length*2);
      #end

      setSize();
   }

   function setSize()
   {
      var scale = Math.min( stage.stageWidth/800, stage.stageHeight/600 );
      scaleX = scaleY = scale;
   }

   private function addBunny():Void
   {
      var bunny = new Bunny();
      bunny.x = 0;
      bunny.y = 0;
      bunny.speedX = Math.random() * 5;
      bunny.speedY = (Math.random() * 5) - 2.5;
      bunnies.push(bunny);
      #if !nme
      tilemap.addTile(bunny);
      #end
   }

   // Event Handlers
   private function stage_onEnterFrame(event:Event):Void
   {
      for(bunny in bunnies)
      {
         bunny.x += bunny.speedX;
         bunny.y += bunny.speedY;
         bunny.speedY += gravity;

         if(bunny.x > maxX)
         {
            bunny.speedX *= -1;
            bunny.x = maxX;
         }
         else if (bunny.x < minX)
         {
            bunny.speedX *= -1;
            bunny.x = minX;
         }

         if (bunny.y > maxY)
         {
            bunny.speedY *= -0.8;
            bunny.y = maxY;
            if (Math.random() > 0.5)
            {
               bunny.speedY -= 3 + Math.random() * 4;
            }
         }
         else if (bunny.y < minY)
         {
            bunny.speedY = 0;
            bunny.y = minY;
         }
      }

      if (addingBunnies)
      {
         for(i in 0...1000)
            addBunny();
         bunnyCount.text = "bunies:" + bunnies.length;
         #if nme
         drawList.resize(bunnies.length*2);
         #end
      }

      #if nme
      graphics.clear();
      var idx = 0;
      for(bunny in bunnies)
      {
         drawList.setF32q(idx++,bunny.x);
         drawList.setF32q(idx++,bunny.y);
      }
      tilesheet.drawTiles(graphics, drawList, false, Tilesheet.TILE_NO_ID);
      #end
   }

   private function stage_onMouseDown(event:MouseEvent):Void
   {
      addingBunnies = true;
   }

   private function stage_onMouseUp(event:MouseEvent):Void
   {
      addingBunnies = false;
      trace(bunnies.length + " bunnies");
   }
}
