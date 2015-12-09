package nme.html5;
import js.Browser;
import js.html.Element;
import nme.display.NativeHandle;

class DisplayObject
{
   static var idAlloc = 1;

   var element:Element;
   var xTrans:String;
   var yTrans:String;

   public function new(inElement:Element)
   {
      element = inElement;
      xTrans = "";
      yTrans = "";
   }


   public static function nme_display_object_set_name(handle:NativeHandle, inName:String)
   {
      handle.element.title = inName;
   }

   public function updateTransform()
   {
      element.style.transform = xTrans + yTrans;
   }

   public static function nme_display_object_set_x(handle:NativeHandle,inX:Float)
   {
      handle.xTrans = 'translateX(${inX}px)';
      handle.updateTransform();
   }

   public static function nme_display_object_set_y(handle:NativeHandle,inY:Float)
   {
      handle.yTrans = ' translateY(${inY}px)';
      handle.updateTransform();
   }

   public static function nme_display_object_get_id(handle:NativeHandle) : Int
   {
      var id = Std.parseInt(handle.element.id);
      if (id==null || id<1)
      {
         id = idAlloc++;
         handle.element.id = Std.string(id);
      }
      return id;
   }

   public static function nme_create_display_object_container( )
   {
      var element = Browser.document.createElement("div");
      return new DisplayObject(element);
   }

   public static function nme_doc_add_child(parent:NativeHandle, child:NativeHandle)
   {
      parent.element.appendChild(child.element);
   }

   public static function nme_display_object_set_bg(handle:NativeHandle, inBg:Int)
   {
      var alpha = (inBg >> 24) & 0xff;
      if (alpha>128)
         handle.element.style.background = null;
      else
         handle.element.style.background = "#" + StringTools.hex(inBg & 0xffffff, 6);
   }

   public static function nme_display_object_get_graphics(handle:NativeHandle)
   {
      var gfx = Browser.document.createElementNS("http://www.w3.org/2000/svg", "svg");
      if (handle.element.hasChildNodes())
         handle.element.insertBefore( handle.element.firstChild, gfx );
      else
         handle.element.appendChild(gfx);
      return new Graphics(cast gfx);
   }
}
