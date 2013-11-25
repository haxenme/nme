package nme.gl;
#if (cpp || neko)

class GLRenderbuffer extends GLObject 
{
   public function new(inVersion:Int, inId:Dynamic) 
   {
      super(inVersion, inId);
   }

   override private function getType():String 
   {
      return "Renderbuffer";
   }
}

#end