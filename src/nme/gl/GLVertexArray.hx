package nme.gl;
#if (gles3 && !flash)

@:nativeProperty
class GLVertexArray extends GLObject 
{
   public function new(inVersion:Int, inId:Dynamic) 
   {
      super(inVersion, inId);
   }

   override function getType():String 
   {
      return "VertexArray";
   }
}

#end
