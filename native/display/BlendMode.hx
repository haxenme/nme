package native.display;
#if (cpp || neko)

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

#end