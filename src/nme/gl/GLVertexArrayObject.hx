package nme.gl;
#if (!flash)

@:nativeProperty
class GLVertexArrayObject extends GLObject 
{
   public function new(inVersion:Int, inId:Dynamic) 
   {
      super(inVersion, inId);
   }

   override function getType():String 
   {
      return "GLVertexArrayObject";
   }
}

#end
