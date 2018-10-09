package nme.display;
#if (!flash)

enum StageAlign 
{
   TOP_RIGHT;
   TOP_LEFT;
   TOP;
   RIGHT;
   LEFT;
   BOTTOM_RIGHT;
   BOTTOM_LEFT;
   BOTTOM;
   CENTRE;
   GAME;
}

#else
typedef StageAlign = flash.display.StageAlign;
#end
