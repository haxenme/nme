package nme.display;


class Shape extends Graphics
{
   public var matrix:nme.geom.Matrix;
   public var extent(DoGetExtent,null):nme.geom.Rectangle;

   public function new()
   {
      super();
      matrix = new nme.geom.Matrix();
   }

   public function DoGetExtent() : nme.geom.Rectangle
   {
      return GetExtent(matrix);
   }



   public function draw()
   {
      render(matrix);
   }
}
