package nme;

import nme.Manager;

class GameBase
{
   public var manager : Manager;
   var mShowFPS:Bool;
   var mFrameCount:Int;
   var mT0:Float;

   public function new( width : Int, height : Int, title : String, fullscreen : Bool, icon : String, ?opengl:Null<Bool>, ?hardware:Null<Bool> )
   {
      manager = new nme.Manager(width,height,title,fullscreen,icon,opengl,true,hardware);
      manager.tryQuitFunction = onQuit;
      manager.addClickCallback(onClick);
      manager.addMouseCallback(onMouse);
      manager.addUpdateCallback(onUpdate);
      manager.addUpdateCallback(UpdateFPS);
      manager.addRenderCallback(onRender);
      manager.addRenderCallback(RenderFPS);
      manager.addKeyCallback(onKey);
      mShowFPS = true;
      mFrameCount = 0;
      mT0 = haxe.Timer.stamp();
   }

   public function onQuit() : Bool
   {
      return true;
   }

   public function onClick(inEvent:MouseEvent) : Void
   {
   }

   public function onMouse(inEvent:MouseEvent) : Void
   {
   }

   public function onKey(inEvent:KeyEvent) : Void
   {
   }

   public function RenderFPS()
   {
      if (mShowFPS )
      {
         var t =  haxe.Timer.stamp() - mT0;
         if (t>0)
         {
            Manager.graphics.lineStyle(0x000000,1);
            var fps = mFrameCount/t;
            fps = Math.round( fps*100 ) * 0.01;
            var text = Std.string(fps);
            Manager.graphics.moveTo(10,10);
            Manager.graphics.text(text,12,null,0xffffff);
         }
      }
   }

   public function UpdateFPS(inDT:Float)
   {
      mFrameCount ++;
   }

   public function onUpdate(inDT:Float)
   {
   }

   public function onRender()
   {
   }

   public function run()
   {
      manager.mainLoop();
   }

}
