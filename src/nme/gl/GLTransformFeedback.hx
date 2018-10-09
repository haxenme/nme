package nme.gl;
#if (!flash)

@:nativeProperty
class GLTransformFeedback extends GLObject 
{
   public function new(inVersion:Int, inId:Dynamic) 
   {
      super(inVersion, inId);
   }

   override function getType():String 
   {
      return "GLTransformFeedback";
   }
}

#end

