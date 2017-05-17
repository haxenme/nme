package nme.filters;
#if (!flash)

@:nativeProperty
class BitmapFilter 
{
   /** @private */ private var type:String;
   public function new(inType) 
   {
      type = inType;
   }

   public function clone():BitmapFilter 
   {
      throw("clone not implemented");
      return null;
   }
}

#else
typedef BitmapFilter = flash.filters.BitmapFilter;
#end
