package nme.gl;
#if (!flash)

@:nativeProperty
class GLProgram extends GLObject 
{
   public var shaders:Array<GLShader>;

   public function new(inVersion:Int, inId:Dynamic) 
   {
      super(inVersion, inId);
      shaders = new Array<GLShader>();
   }

   public function attach(s:GLShader):Void 
   {
      shaders.push(s);
   }

   public function getShaders():Array<GLShader> 
   {
      return shaders.copy();
   }

   override private function getType():String 
   {
      return "Program";
   }
}

#end
