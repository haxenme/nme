package nme.gl;
#if (!flash)

@:nativeProperty
class GLTexture extends GLObject 
{
   public function new(inVersion:Int, inId:Dynamic) 
   {
      super(inVersion, inId);
   }

   override private function getType():String 
   {
      return "Texture";
   }
}

#end
