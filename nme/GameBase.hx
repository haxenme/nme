package nme;

import nme.Manager;

class GameBase
{
   public var manager : Manager;

	public function new( width : Int, height : Int, title : String, fullscreen : Bool, icon : String, ?opengl:Null<Bool> )
   {
      manager = new nme.Manager(width,height,title,fullscreen,icon,opengl);
      manager.tryQuitFunction = onQuit;
      manager.addClickCallback(onClick);
      manager.addMouseCallback(onMouse);
      manager.addUpdateCallback(onUpdate);
      manager.addRenderCallback(onRender);
      manager.addKeyCallback(onKey);
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

   public function onUpdate()
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
