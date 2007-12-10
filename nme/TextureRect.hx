package nme;


class TextureRect
{
   var __texture : Void;

   public function new()
   {
      __texture = null;
   }

   public function SetText(inFont:String,inPointSize:Int,
                           inColour:Int, inText:String)
   {
      __texture = nme_create_text_texture(untyped inFont.__s,inPointSize,inColour,untyped inText.__s);
   }

   public function Quad()
   {
      if (__texture!=null) nme_texture_quad(__texture);
   }


   static var nme_create_text_texture = neko.Lib.load("nme","nme_create_text_texture",4);
   static var nme_texture_quad = neko.Lib.load("nme","nme_texture_quad",1);

}

