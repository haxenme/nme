#include <hx/CFFI.h>
#include "nme.h"

int __force_joystick=0;

DEFINE_KIND( k_joystick );


value nme_joystick_count()
{
   return alloc_int( SDL_NumJoysticks() );
}

value nme_joystick_name(value inID)
{
   return alloc_string( SDL_JoystickName( val_int(inID) ) );
}

void joystick_close(value inValue)
{
   SDL_Joystick *stick = (SDL_Joystick *)val_to_kind(inValue,k_joystick);
   SDL_JoystickClose(stick);
}

value nme_joystick_open(value inID)
{
   SDL_Joystick *stick = SDL_JoystickOpen(val_int(inID));
   if (stick==0)
      return alloc_null();
 
   value v = alloc_abstract( k_joystick, stick );
   val_gc( v, joystick_close );
   return v;
}

value nme_joystick_axes(value inValue)
{
   SDL_Joystick *stick = (SDL_Joystick *)val_to_kind(inValue,k_joystick);
   return alloc_int( SDL_JoystickNumAxes(stick) );
}


value nme_joystick_hats(value inValue)
{
   SDL_Joystick *stick = (SDL_Joystick *)val_to_kind(inValue,k_joystick);
   return alloc_int( SDL_JoystickNumHats(stick) );
}

value nme_joystick_balls(value inValue)
{
   SDL_Joystick *stick = (SDL_Joystick *)val_to_kind(inValue,k_joystick);
   return alloc_int( SDL_JoystickNumBalls(stick) );
}

value nme_joystick_buttons(value inValue)
{
   SDL_Joystick *stick = (SDL_Joystick *)val_to_kind(inValue,k_joystick);
   return alloc_int( SDL_JoystickNumButtons(stick) );
}


value nme_joystick_axis(value inValue,value inWhich)
{
   SDL_Joystick *stick = (SDL_Joystick *)val_to_kind(inValue,k_joystick);
   return alloc_float( SDL_JoystickGetAxis(stick,val_int(inWhich)) );
}


value nme_joystick_button(value inValue,value inWhich)
{
   SDL_Joystick *stick = (SDL_Joystick *)val_to_kind(inValue,k_joystick);
   return alloc_bool( SDL_JoystickGetButton(stick,val_int(inWhich)) );
}


DEFINE_PRIM(nme_joystick_count, 0);
DEFINE_PRIM(nme_joystick_name, 1);
DEFINE_PRIM(nme_joystick_open, 1);
DEFINE_PRIM(nme_joystick_axes, 1);
DEFINE_PRIM(nme_joystick_hats, 1);
DEFINE_PRIM(nme_joystick_balls, 1);
DEFINE_PRIM(nme_joystick_buttons, 1);

DEFINE_PRIM(nme_joystick_axis, 2);
DEFINE_PRIM(nme_joystick_button, 2);


