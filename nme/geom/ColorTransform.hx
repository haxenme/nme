package nme.geom;

class ColorTransform
{
   public var redMultiplier:Float;
   public var greenMultiplier:Float;
   public var blueMultiplier:Float;
   public var alphaMultiplier:Float;
   public var redOffset:Float;
   public var greenOffset:Float;
   public var blueOffset:Float;
   public var alphaOffset:Float;

   public function new(inRedMultiplier:Float = 1.0,
                       inGreenMultiplier:Float = 1.0,
                       inBlueMultiplier:Float = 1.0,
                       inAlphaMultiplier:Float = 1.0,
                       inRedOffset:Float = 0.0,
                       inGreenOffset:Float = 0.0,
                       inBlueOffset:Float = 0.0,
                       inAlphaOffset:Float = 0.0)
   {
      redMultiplier = inRedMultiplier;
      greenMultiplier = inGreenMultiplier;
      blueMultiplier = inBlueMultiplier;
      alphaMultiplier = inAlphaMultiplier;
      redOffset = inRedOffset;
      greenOffset = inGreenOffset;
      blueOffset = inBlueOffset;
      alphaOffset = inAlphaOffset;
   }

}
