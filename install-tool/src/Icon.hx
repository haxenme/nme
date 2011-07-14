
class Icon
{
   public var name(default,null):String;
   var width:Null<Int>;
   var height:Null<Int>;

   public function new(inName:String, inWidth:String, inHeight:String)
   {
      name = inName;
      width = inWidth=="" ? null : Std.parseInt(inWidth);
      height = inHeight=="" ? null : Std.parseInt(inHeight);
   }
   public function isSize(inWidth:Int, inHeight:Int)
   {
      return width==inWidth && height==inHeight;
   }
   public function matches(inWidth:Int, inHeight:Int)
   {
      return (width==inWidth || width==null) && (height==inHeight || height==null);
   }
}

