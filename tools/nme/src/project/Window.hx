
class Window
{
   public var width:Int;
   public var height:Int;
   public var background:Int;
   public var parameters:String;
   public var fps:Int;
   public var hardware:Bool;
   public var resizable:Bool;
   public var borderless:Bool;
   public var vsync:Bool;
   public var fullscreen:Bool;
   public var antialiasing:Int;
   public var orientation:Orientation;
   public var allowShaders:Bool;
   public var requireShaders:Bool;
   public var depthBuffer:Bool;
   public var stencilBuffer:Bool;
   public var alphaBuffer:Bool;
   public var ui:String;
   public var singleInstance:Bool;
   public var scaleMode:ScaleMode;
   public var glDebug:Bool;

   public function new()
   {
      width = 800;
      height = 600;
      parameters = "{}";
      background = 0xFFFFFF;
      fps = 30;
      hardware = true;
      resizable = true;
      borderless = false;
      orientation = Orientation.AUTO;
      vsync = false;
      fullscreen = false;
      antialiasing = 0;
      allowShaders = true;
      requireShaders = false;
      depthBuffer = false;
      stencilBuffer = false;
      alphaBuffer = false;
      ui = "";
      singleInstance = true;
      glDebug = false;
      scaleMode = ScaleNative;
   }
}
