package nme.display;
#if (!flash)

@:nativeProperty
class Shape extends DisplayObject 
{
   public function new() 
   {
      super(DisplayObject.nme_create_display_object(), "Shape");
   }
}

#else
typedef Shape = flash.display.Shape;
#end
