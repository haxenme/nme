package nme.preloader;

import nme.display.Sprite;
import nme.events.Event;

@:nativeProperty
class Basic extends Sprite
{
   private var outline:Sprite;
   private var progress:Sprite;
   var preWidth:Float;
   var preHeight:Float;
   var backgroundColor:Int;
   
   
   public function new()
   {
      super();
      nme.Lib.current.addChild(this);

      preWidth = getWidth() > 0 ? getWidth() : nme.Lib.current.stage.stageHeight;
      preHeight = getHeight() > 0 ? getHeight() : nme.Lib.current.stage.stageHeight;
      backgroundColor = getBackgroundColor();

      var r = backgroundColor >> 16 & 0xFF;
      var g = backgroundColor >> 8  & 0xFF;
      var b = backgroundColor & 0xFF;
      var perceivedLuminosity = (0.299 * r + 0.587 * g + 0.114 * b);
      var color = 0x000000;

      if (perceivedLuminosity < 70)
         color = 0xFFFFFF;

      var x = 30;
      var height = 9;
      var y = preHeight / 2 - height / 2;
      var width = preWidth - x * 2;
      var padding = 3;

      outline = new Sprite();
      var gfx = outline.graphics;
      gfx.lineStyle(1, color, 0.15, true);
      gfx.drawRoundRect(0, 0, width, height, padding * 2, padding * 2);
      outline.x = x;
      outline.y = y;
      addChild(outline);

      progress = new Sprite();
      progress.graphics.beginFill(color, 0.35);
      progress.graphics.drawRect(0, 0, width - padding * 2, height - padding * 2);
      progress.x = x + padding;
      progress.y = y + padding;
      addChild(progress);
      onUpdate(0,nme.Lib.current.loaderInfo.bytesTotal);

      addEventListener( Event.ENTER_FRAME, doEnter );
   }

   #if script
   public function getBackgroundColor():Int return ScriptMain.winBackground;
   public function getWidth():Float return ScriptMain.winWidth;
   public function getHeight():Float return ScriptMain.winHeight;
   #else
   public function getBackgroundColor():Int return ApplicationMain.winBackground;
   public function getWidth():Float return ApplicationMain.winWidth;
   public function getHeight():Float return ApplicationMain.winHeight;
   #end

   public function doEnter(_) { onEnter(); }

   public function onLoaded()
   {
      if (parent!=null)
         parent.removeChild(this);
      removeEventListener( Event.ENTER_FRAME, doEnter );
      dispatchEvent(new Event (Event.COMPLETE));
      #if script
      ScriptMain.onLoaded();
      #else
      ApplicationMain.onLoaded();
      #end
   }

   function onEnter()
   {
      var loaded = nme.Lib.current.loaderInfo.bytesLoaded;
      var total = nme.Lib.current.loaderInfo.bytesTotal;


      onUpdate(loaded,total);

      if (loaded >= total)
         onLoaded();
   }

   public function onInit()
	{
		
	}


   function onUpdate(bytesLoaded:Int, bytesTotal:Int)
   {
      var percentLoaded = bytesLoaded / bytesTotal;
      if (percentLoaded > 1)
         percentLoaded == 1;

      progress.scaleX = percentLoaded;
   }
}

