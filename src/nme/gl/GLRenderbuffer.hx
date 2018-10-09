package nme.gl;
#if (!flash)

@:nativeProperty
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
