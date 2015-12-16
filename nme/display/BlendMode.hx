package nme.display;
#if (!flash)

enum BlendMode 
{
   NORMAL;
   LAYER;
   MULTIPLY;
   SCREEN;
   LIGHTEN;
   DARKEN;
   DIFFERENCE;
   ADD;
   SUBTRACT;
   INVERT;
   ALPHA;
   ERASE;
   OVERLAY;
   HARDLIGHT;
}

#else
typedef BlendMode = flash.display.BlendMode;
#end
