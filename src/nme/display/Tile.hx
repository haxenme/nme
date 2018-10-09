package nme.display;

class Tile
{
   public var id(default,set):Int;
   public var x(default,set):Float;
   public var y(default,set):Float;
   public var nmeOwner:Tilemap;

   public function new(inId:Int, inX:Float = 0, inY:Float = 0)
   {
      id = inId;
      x = inX;
      y = inY;
   }
   function set_x(inX:Float) : Float
   {
      x = inX;
      if (nmeOwner!=null)
         nmeOwner.dirtyFlags |= Tilemap.DIRTY_BASE;
      return inX;
   }
   function set_y(inY:Float) : Float
   {
      y = inY;
      if (nmeOwner!=null)
         nmeOwner.dirtyFlags |= Tilemap.DIRTY_BASE;
      return inY;
   }
   function set_id(inId:Int) : Int
   {
      id = inId;
      if (nmeOwner!=null)
         nmeOwner.dirtyFlags |= Tilemap.DIRTY_BASE;
      return inId;
   }

}

