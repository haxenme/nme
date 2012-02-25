package nme.display;
#if js

import nme.display.IGraphicsData;
import nme.display.IGraphicsFill;
import Html5Dom;

class GraphicsGradientFill implements IGraphicsData, implements IGraphicsFill
{
	public var alphas : Array<Float>;
	public var colors : Array<UInt>;
	public var focalPointRatio : Float;
	public var interpolationMethod : InterpolationMethod;
	public var matrix : flash.geom.Matrix;
	public var ratios : Array<Float>;
	public var spreadMethod : SpreadMethod;
	public var type : GradientType;
	public var jeashGraphicsDataType(default,null):GraphicsDataType;
	public var jeashGraphicsFillType(default,null):GraphicsFillType;
	public function new(?type : GradientType, ?colors : Array<UInt>, ?alphas : Array<Float>, ?ratios : Array<Float>, ?matrix : flash.geom.Matrix, ?spreadMethod : SpreadMethod, ?interpolationMethod : InterpolationMethod, focalPointRatio : Float = 0) {
		this.type = type;
		this.colors = colors;
		this.alphas = alphas;
		this.ratios = ratios;
		this.matrix = matrix;
		this.spreadMethod = spreadMethod;
		this.interpolationMethod = interpolationMethod;
		this.focalPointRatio = focalPointRatio;
		this.jeashGraphicsDataType = GRADIENT;
		this.jeashGraphicsFillType = GRADIENT_FILL;
	}
}

#end