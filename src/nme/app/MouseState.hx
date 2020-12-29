package nme.app;

class MouseState
{
   public var x:Int;
   public var y:Int;
   public var buttons:Int;

   public function new()
   {
      x = y = buttons = 0;
   }
   public function getButton(but:Int) : Bool
   {
      return buttons & (1<<but)  != 0; 
   }

   public function toString() return 'MouseState($x,$y:$buttons)';
}
