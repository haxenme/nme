#ifndef INCLUDED_HARDWARE_IMPL_H
#define INCLUDED_HARDWARE_IMPL_H
#pragma once

#include <Hardware.h>
#include <Surface.h>

namespace nme
{

enum
{
   PROG_TEXTURE =           0x0001,
   PROG_ALPHA_TEXTURE =     0x0002,
   PROG_COLOUR_PER_VERTEX = 0x0004,
   PROG_NORMAL_DATA =       0x0008,
   PROG_RADIAL =            0x0010,
   PROG_RADIAL_FOCUS =      0x0020,
   PROG_TINT =              0x0040,
   PROG_COLOUR_OFFSET =     0x0080,
   PROG_4D_INPUT      =     0x0100,
   PROG_PREM_ALPHA    =     0x0200,

   PROG_COUNT =             0x0400,
};

inline unsigned int getProgId( const DrawElement &element, const ColorTransform *ctrans)
{
   unsigned int progId = 0;
   if ((element.mFlags & DRAW_HAS_TEX) && element.mSurface)
   {
      if (IsPremultipliedAlpha(element.mSurface->Format()))
         progId |= PROG_PREM_ALPHA;
      progId |= PROG_TEXTURE;
      if (element.mSurface->Format()==pfAlpha)
         progId |= PROG_ALPHA_TEXTURE;
   }

   if (element.mFlags & DRAW_HAS_COLOUR)
      progId |= PROG_COLOUR_PER_VERTEX;

   if (element.mFlags & DRAW_HAS_PERSPECTIVE)
      progId |= PROG_4D_INPUT;

   if (element.mFlags & DRAW_HAS_NORMAL)
      progId |= PROG_NORMAL_DATA;

   if (element.mFlags & DRAW_RADIAL)
   {
      progId |= PROG_RADIAL;
      if (element.mRadialPos!=0)
         progId |= PROG_RADIAL_FOCUS;
   }

   if (ctrans || element.mColour != 0xffffffff)
   {
      progId |= PROG_TINT;
      if (ctrans && ctrans->HasOffset())
         progId |= PROG_COLOUR_OFFSET;
   }

   return progId;
}



}

#endif
