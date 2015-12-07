package nme.display3D;
#if (!flash)

enum Context3DStencilAction 
{
   DECREMENT_SATURATE;
   DECREMENT_WRAP;
   INCREMENT_SATURATE;
   INCREMENT_WRAP;
   INVERT;
   KEEP;
   SET;
   ZERO;
}

#else
typedef Context3DStencilAction = flash.display3D.Context3DStencilAction;
#end
