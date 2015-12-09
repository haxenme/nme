package nme.html5;
import js.Browser;
import js.html.Element;
import nme.display.NativeHandle;

class DisplayObject
{
   static var idAlloc = 1;
   public static function nme_display_object_set_name(handle:NativeHandle, inName:String)
   {
      handle.className = inName;
   }

   public static function nme_display_object_get_id(handle:NativeHandle) : Int
   {
      var id = Std.parseInt(handle.id);
      if (id==null || id<1)
      {
         id = idAlloc++;
         handle.id = Std.string(id);
      }
      return id;
   }

   public static function nme_create_display_object_container( )
   {
      return Browser.document.createElement("div");
   }

   public static function nme_doc_add_child(parent:NativeHandle, child:NativeHandle)
   {
      parent.appendChild(child);
   }

   public static function nme_display_object_set_bg(handle:NativeHandle, inBg:Int)
   {
      var alpha = (inBg >> 24) & 0xff;
      if (alpha>128)
         handle.style.background = null;
      else
         handle.style.background = "#" + StringTools.hex(inBg & 0xffffff, 6);
   }

   public static function nme_display_object_get_graphics(handle:NativeHandle)
   {
      var gfx = Browser.document.createElementNS("http://www.w3.org/2000/svg", "svg");
      if (handle.hasChildNodes())
         handle.insertBefore( handle.firstChild, gfx );
      else
         handle.appendChild(gfx);
      return new Graphics(cast gfx);
   }
}
