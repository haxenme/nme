package nme.gl;
#if (cpp || neko)

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
