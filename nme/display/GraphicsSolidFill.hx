#if flash


package nme.display;


@:native ("flash.display.GraphicsSolidFill")
@:final extern class GraphicsSolidFill implements IGraphicsData, implements IGraphicsFill {
	var alpha : Float;
	var color : UInt;
	function new(color : UInt = 0, alpha : Float = 1) : Void;
}


#else


package nme.display;

class GraphicsSolidFill extends IGraphicsData
{

   public function new(color:Int = 0, alpha:Float = 1.0)
	{
	   super( nme_graphics_solid_fill_create(color,alpha) );
	}

   static var nme_graphics_solid_fill_create = nme.Loader.load("nme_graphics_solid_fill_create",2);
}



#end