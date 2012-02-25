package nme.display;
#if (cpp || neko)


class Shape extends DisplayObject
{
	
	public function new()
	{
		super(DisplayObject.nme_create_display_object(), "Shape");
	}
	
}


#elseif js

import nme.display.Graphics;
import nme.display.InteractiveObject;
import nme.geom.Matrix;
import nme.geom.Point;
import nme.Lib;

class Shape extends DisplayObject {
	var jeashGraphics:Graphics;

	public var graphics(jeashGetGraphics,null):Graphics;

	public function new() {
		Lib.canvas;
		jeashGraphics = new Graphics();
		if(jeashGraphics!=null)
			jeashGraphics.owner = this;
		super();
		name = "Shape " + DisplayObject.mNameID++;
	}

	override function jeashGetGraphics() return jeashGraphics
	override public function jeashGetObjectUnderPoint(point:Point):DisplayObject return null
}

#else
typedef Shape = flash.display.Shape;
#end