package nme.display;


class Shape extends Graphics
{
   public var matrix:nme.geom.Matrix;

   public function new()
   {
      super();
      matrix = new nme.geom.Matrix();
   }

   public function draw()
   {
      render(matrix);
   }
}
