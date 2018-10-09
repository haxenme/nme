package nme.gl;
#if (!flash)

@:nativeProperty
class GLObject 
{
   public var id:Dynamic;
   public var invalidated(get, null):Bool;
   public var valid(get, null):Bool;

   private var version:Int;

   private function new(inVersion:Int, inId:Dynamic) 
   {
      version = inVersion;
      id = inId;
   }

   private function getType():String 
   {
      return "GLObject";
   }

   public function invalidate():Void 
   {
      id = null;
   }

   public function isValid():Bool 
   {
      return id != null && version == GL.version;
   }

   public function isInvalid():Bool 
   {
      return !isValid();
   }

   public function toString():String 
   {
      return getType() + "(" + nme_gl_resource_id(id) + ")";
   }

   // Getters & Setters
   private function get_invalidated():Bool 
   {
      return isInvalid();
   }

   private function get_valid():Bool 
   {
      return isValid();
   }


   private static var nme_gl_resource_id = GL.load("nme_gl_resource_id", 1);

}

#end
