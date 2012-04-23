package format.swf.data;


#if !nme
import flash.filters.BevelFilter;
import flash.filters.BitmapFilterType;
import flash.filters.ColorMatrixFilter;
import flash.filters.ConvolutionFilter;
import flash.filters.GradientBevelFilter;
import flash.filters.GradientGlowFilter;
#end

import flash.filters.BitmapFilter;
import flash.filters.BlurFilter;
import flash.filters.DropShadowFilter;
import flash.filters.GlowFilter;
import format.swf.data.SWFStream;


class Filters {
	
	
	public static function readFilters (stream:SWFStream):Array <BitmapFilter> {
		
		var count = stream.readByte();
		var filters = new Array <BitmapFilter> ();
		
		for (i in 0...count) {
			
			var filterID = stream.readByte ();
			
			filters.push (
				
				switch (filterID) {
					case 0 : createDropShadowFilter (stream);
					case 1 : createBlurFilter (stream);
					case 2 : createGlowFilter (stream);
					case 3 : createBevelFilter (stream);
					case 4 : createGradientGlowFilter (stream);
					case 5 : createConvolutionFilter (stream);
					case 6 : createColorMatrixFilter (stream);
					case 7 : createGradientBevelFilter (stream);
					default: throw "Unknown filter : " + filterID + "  " + i + "/" + count; 
				}
				
			);
			
		}
		
		return filters;
		
	}
	
	
	private static function createBevelFilter (stream:SWFStream):BitmapFilter {
		
		var shadowColor = stream.readRGB ();
		var shadowAlpha = stream.readByte () / 255.0;
		
		var highlightColor = stream.readRGB ();
		var highlightAlpha = stream.readByte () / 255.0;
		
		var blurX = stream.readFixed ();
		var blurY = stream.readFixed ();
		var angle = stream.readFixed ();
		var distance = stream.readFixed ();
		
		var strength = stream.readFixed8 ();
		
		var innerShadow = stream.readBool ();
		var knockout = stream.readBool ();
		var compositeSource = stream.readBool ();
		var onTop = stream.readBool ();
		
		var passes = stream.readBits (4);
		
		#if !nme
		
		var type = BitmapFilterType.OUTER;
		
		if (innerShadow) {
			
			if (onTop) {
				
				type = BitmapFilterType.FULL;
				
			} else {
				
				type.BitmapFilterType.INNER;
				
			}
			
		}
		
		return new BevelFilter (distance, angle, highlightColor, highlightAlpha, shadowColor, shadowAlpha, blurX, blurY, strength, passes, type, knockout);
		
		#end
		
		return null;
		
	}
	
	
	private static function createBlurFilter (stream:SWFStream):BitmapFilter {
		
		var blurX = stream.readFixed ();
		var blurY = stream.readFixed ();
		
		var passes = stream.readBits (5);
		var reserved = stream.readBits (3);
		
		return new BlurFilter (blurX, blurY, passes);
		
	}
	
	
	private static function createColorMatrixFilter (stream:SWFStream):BitmapFilter {
		
		var matrix = new Array <Float> ();
		
		for (i in 0...20) {
			
			matrix.push (stream.readFloat ());
			
		}
		
		#if !nme
		
		return new ColorMatrixFilter (matrix);
		
		#end
		
		return null;
		
	}
	
	
	private static function createConvolutionFilter (stream:SWFStream):BitmapFilter {
		
		var width = stream.readByte ();
		var height = stream.readByte ();
		
		var divisor = stream.readFloat ();
		var bias = stream.readFloat ();
		
		var matrix = new Array <Float> ();
		
		for (i in 0...width*height) {
			
			matrix[i] = stream.readFloat ();
			
		}
		
		var defaultColor = stream.readRGB ();
		var defaultAlpha = stream.readByte () / 255.0;
		
		var reserved = stream.readBits (6);
		
		var clamp = stream.readBool ();
		var preserveAlpha = stream.readBool ();
		
		#if !nme
		
		return new ConvolutionFilter (width, height, matrix, divisor, bias, preserveAlpha, clamp, defaultColor, defaultAlpha);
		
		#end
		
		return null;
		
	}
	
	
	private static function createDropShadowFilter (stream:SWFStream):BitmapFilter {
		
		var color = stream.readRGB ();
		var alpha = stream.readByte () / 255.0;
		
		var blurX = stream.readFixed ();
		var blurY = stream.readFixed ();
		var angle = stream.readFixed () * (180 / Math.PI);
		var distance = stream.readFixed ();
		
		var strength = stream.readFixed8 ();
		
		var innerShadow = stream.readBool ();
		var knockout = stream.readBool ();
		var compositeSource = stream.readBool ();
		
		var passes = stream.readBits (5);
		
		return new DropShadowFilter (distance, angle, color, alpha, blurX, blurY, strength, passes, innerShadow, knockout);
		
	}
	
	
	private static function createGlowFilter (stream:SWFStream):BitmapFilter {
		
		var color = stream.readRGB ();
		var alpha = stream.readByte () / 255.0;
		
		var blurX = stream.readFixed ();
		var blurY = stream.readFixed ();
		
		var strength = stream.readFixed8 ();
		
		var innerGlow = stream.readBool ();
		var knockout = stream.readBool ();
		var compositeSource = stream.readBool ();
		
		var passes = stream.readBits (5);
		
		return new GlowFilter (color, alpha, blurX, blurY, strength, passes, innerGlow, knockout);
		
	}
	
	
	private static function createGradientBevelFilter (stream:SWFStream):BitmapFilter {
		
		var numColors = stream.readByte ();
		
		var gradientColors = new Array <Int> ();
		var gradientAlpha = new Array <Float> ();
		var gradientRatio = new Array <Int> ();
		
		for (i in 0...numColors) {
			
			gradientColors.push (stream.readRGB ());
			gradientAlpha.push (stream.readByte () / 255.0);
			gradientRatio.push (stream.readByte ());
			
		}
		
		var blurX = stream.readFixed ();
		var blurY = stream.readFixed ();
		var angle = stream.readFixed ();
		var distance = stream.readFixed ();
		
		var strength = stream.readFixed8 ();
		
		var innerShadow = stream.readBool ();
		var knockout = stream.readBool ();
		var compositeSource = stream.readBool ();
		
		var onTop = stream.readBool ();
		
		var passes = stream.readBits (4);
		
		#if !nme
		
		var type = BitmapFilterType.OUTER;
		
		if (innerShadow) {
			
			if (onTop) {
				
				type = BitmapFilterType.FULL;
				
			} else {
				
				type.BitmapFilterType.INNER;
				
			}
			
		}
		
		return new GradientBevelFilter (distance, angle, gradientColors, gradientAlpha, gradientRatio, blurX, blurY, strength, passes, type, knockout);
		
		#end
		
		return null;
		
	}
	
	
	private static function createGradientGlowFilter (stream:SWFStream):BitmapFilter {
		
		var numColors = stream.readByte ();
		
		var gradientColors = new Array <Int> ();
		var gradientAlpha = new Array <Float> ();
		var gradientRatio = new Array <Int> ();
		
		for (i in 0...numColors) {
			
			gradientColors.push (stream.readRGB ());
			gradientAlpha.push (stream.readByte () / 255.0);
			gradientRatio.push (stream.readByte ());
			
		}
		
		var blurX = stream.readFixed ();
		var blurY = stream.readFixed ();
		var angle = stream.readFixed ();
		var distance = stream.readFixed ();
		
		var strength = stream.readFixed8 ();
		
		var innerShadow = stream.readBool ();
		var knockout = stream.readBool ();
		var compositeSource = stream.readBool ();
		
		var onTop = stream.readBool ();
		
		var passes = stream.readBits (4);
		
		#if !nme
		
		var type = BitmapFilterType.OUTER;
		
		if (innerShadow) {
			
			if (onTop) {
				
				type = BitmapFilterType.FULL;
				
			} else {
				
				type.BitmapFilterType.INNER;
				
			}
			
		}
		
		return new GradientGlowFilter (distance, angle, gradientColors, gradientAlpha, gradientRatio, blurX, blurY, strength, passes, type, knockout);
		
		#end
		
		return null;
		
	}
	
	
}