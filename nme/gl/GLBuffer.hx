package nme.gl;
#if (cpp || neko)

@:nativeProperty
class GLBuffer extends GLObject 
{
   public function new(inVersion:Int, inId:Dynamic) 
   {
      super(inVersion, inId);
   }

   override function getType():String 
   {
      return "Buffer";
   }
}

#end
