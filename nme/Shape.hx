package nme;


class Shape extends nme.Graphics
{
   public var matrix:Matrix;

   public function new()
   {
      super();
      matrix = new Matrix();
   }

   public function draw()
   {
      render(matrix);
   }
}
