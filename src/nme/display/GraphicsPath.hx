package nme.display;
#if (!flash)

import nme.PrimeLoader;

@:nativeProperty
class GraphicsPath extends IGraphicsData 
{
   public var commands(get, set):Array<Int>;
   public var data(get, set):Array<Float>;

   public function new(?commands:Array<Int>, ?data:Array<Float>, winding:String = GraphicsPathWinding.EVEN_ODD) 
   {
      super(nme_graphics_path_create(commands, data, winding == GraphicsPathWinding.EVEN_ODD));
   }

   public function curveTo(controlX:Float, controlY:Float, anchorX:Float, anchorY:Float):Void 
   {
      nme_graphics_path_curve_to(nmeHandle, controlX, controlY, anchorX, anchorY);
   }

   public function cubicTo(cx0:Float, cy0:Float, cx1:Float, cy1:Float, x:Float, y:Float):Void 
   {
      nme_graphics_path_cubic_to(nmeHandle, cx0,cy0,cx1,cy1,x,y);
   }

   public function lineTo(x:Float, y:Float):Void 
   {
      nme_graphics_path_line_to(nmeHandle, x, y);
   }

   public function moveTo(x:Float, y:Float):Void 
   {
      nme_graphics_path_move_to(nmeHandle, x, y);
   }

   public function wideLineTo(x:Float, y:Float):Void 
   {
      nme_graphics_path_wline_to(nmeHandle, x, y);
   }

   public function wideMoveTo(x:Float, y:Float):Void 
   {
      nme_graphics_path_wmove_to(nmeHandle, x, y);
   }

   // Getters & Setters
   private function get_commands():Array<Int> 
   {
      var result = new Array<Int>();
      nme_graphics_path_get_commands(nmeHandle, result);
      return result;
   }

   private function set_commands(inCommands:Array<Int>):Array<Int> 
   {
      nme_graphics_path_set_commands(nmeHandle, inCommands);
      return inCommands;
   }

   private function get_data():Array<Float> 
   {
      var result = new Array<Float>();      
      nme_graphics_path_get_data(nmeHandle, result);
      return result;
   }

   private function set_data(inData:Array<Float>):Array<Float> 
   {
      nme_graphics_path_set_data(nmeHandle, inData);   
      return inData;
   }

   // Native Methods
   private static var nme_graphics_path_create = PrimeLoader.load("nme_graphics_path_create", "oobo");
   private static var nme_graphics_path_curve_to = PrimeLoader.load("nme_graphics_path_curve_to", "oddddv");
   private static var nme_graphics_path_cubic_to = PrimeLoader.load("nme_graphics_path_cubic_to", "oddddddv");
   private static var nme_graphics_path_line_to = PrimeLoader.load("nme_graphics_path_line_to", "oddv");
   private static var nme_graphics_path_move_to = PrimeLoader.load("nme_graphics_path_move_to", "oddv");
   private static var nme_graphics_path_wline_to = PrimeLoader.load("nme_graphics_path_wline_to", "oddv");
   private static var nme_graphics_path_wmove_to = PrimeLoader.load("nme_graphics_path_wmove_to", "oddv");
   private static var nme_graphics_path_get_commands = PrimeLoader.load("nme_graphics_path_get_commands", "oov");
   private static var nme_graphics_path_set_commands = PrimeLoader.load("nme_graphics_path_set_commands", "oov");
   private static var nme_graphics_path_get_data = PrimeLoader.load("nme_graphics_path_get_data", "oov");
   private static var nme_graphics_path_set_data = PrimeLoader.load("nme_graphics_path_set_data", "oov");
}

#else
typedef GraphicsPath = flash.display.GraphicsPath;
#end
