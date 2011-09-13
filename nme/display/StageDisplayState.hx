package nme.display;
#if cpp || neko


enum StageDisplayState
{
   NORMAL;
   FULL_SCREEN;
   FULL_SCREEN_INTERACTIVE;
}


#else
typedef StageDisplayState = flash.display.StageDisplayState;
#end