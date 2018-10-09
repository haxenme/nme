package nme.gl;
#if (!flash)

@:nativeProperty
class GLShader extends GLObject 
{
   public function new(inVersion:Int, inId:Dynamic) 
   {
      super(inVersion, inId);
   }

   override private function getType():String 
   {
      return "Shader";
   }
}

#end
