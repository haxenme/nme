package nme.gl;
#if (cpp || neko)

class GLFramebuffer extends GLObject 
{
   public function new(inVersion:Int, inId:Dynamic) 
   {
      super(inVersion, inId);
   }

   override function getType():String 
   {
      return "Framebuffer";
   }
}

#end