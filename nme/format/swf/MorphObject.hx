package nme.format.swf;

class MorphObject extends flash.display.Sprite
{
   var mData:MorphShape;

   public function new(inData:MorphShape)
   {
      super();
      mData = inData;
   }


   public function SetRatio(inRatio:Int)
   {
      // TODO: this could be cached in child objects.
      var gfx = graphics;
      gfx.clear();
      var f = inRatio/65536.0;
      return mData.Render(gfx,f);
   }




}
