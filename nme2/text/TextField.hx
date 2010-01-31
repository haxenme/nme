package nme2.text;

class TextField extends nme2.display.DisplayObject
{
   public var text(getText,setText):String;

   public function new( )
   {
      var handle = nme_text_field_create( );
      super(handle);
   }
   
   public function getText() : String { return nme_text_field_get_text(nmeHandle); }
   public function setText(inText:String ) : String
   {
      nme_text_field_set_text(nmeHandle,inText);
      return inText;
   }

   static var nme_text_field_create = neko.Lib.load("nme2","nme_text_field_create",0);
   static var nme_text_field_get_text = neko.Lib.load("nme2","nme_text_field_get_text",1);
   static var nme_text_field_set_text = neko.Lib.load("nme2","nme_text_field_set_text",2);
}
