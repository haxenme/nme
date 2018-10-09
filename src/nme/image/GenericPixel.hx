package nme.image;

typedef GenericPixel =
{
   public var pixelFormat(default,never):Int;

   public function getLuma() : Int;
   public function getAlpha() : Int;
   public function getRAlpha() : Int;
   public function getGAlpha() : Int;
   public function getBAlpha() : Int;
   public function getR() : Int;
   public function getG() : Int;
   public function getB() : Int;

   public function setR(val:Int):Void;
   public function setG(val:Int):Void;
   public function setB(val:Int):Void;
   public function setRAlpha(val:Int):Void;
   public function setGAlpha(val:Int):Void;
   public function setBAlpha(val:Int):Void;
   public function setAlpha(val:Int):Void;
   public function setLuma(val:Int):Void;
}

