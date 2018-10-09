package nme.utils;


abstract Floats3264(Dynamic)
{
   public inline function new(d:Dynamic) this = d;
   @:to inline function toDynamic() return this;
   @:from inline static function fromArrayFloat( f:Array<Float> )
        return new Floats3264(f);
   @:from inline static function fromArrayFloat32Buffer( f:Float32Buffer )
        return new Floats3264(f);
   #if cpp
   @:from inline static function fromArray32Float( f:Array<cpp.Float32> )
        return new Floats3264(f);
   #end
}

#if cpp
typedef SmallFloats = Array< cpp.Float32 >;
#else
typedef SmallFloats = Array< Float >;
#end


