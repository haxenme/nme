#ifndef EXTRAS_H
#define EXTRAS_H

#include <SDL.h>
#include <vector>

#define SPG_ALPHA_BLEND      0x0001
#define SPG_HIGH_QUALITY     0x0002

#define SPG_EDGE_MASK        0x00f0
#define SPG_EDGE_CLAMP       0x0000
#define SPG_EDGE_REPEAT      0x0010
#define SPG_EDGE_UNCHECKED   0x0020
#define SPG_EDGE_REPEAT_POW2 0x0030

#define SPG_END_NONE         0x0000
#define SPG_END_ROUND        0x0100
#define SPG_END_SQUARE       0x0200
#define SPG_END_MASK         0x0300
#define SPG_END_SHIFT        8

#define SPG_CORNER_ROUND     0x0000
#define SPG_CORNER_MITER     0x1000
#define SPG_CORNER_BEVEL     0x2000
#define SPG_CORNER_MASK      0x3000
#define SPG_CORNER_SHIFT     12

#define SPG_PIXEL_HINTING    0x4000

#define SPG_GRADIENT_FOCAL0  0x8000

#define SPG_BMP_LINEAR       0x10000

#include "Points.h"



typedef std::vector<int> IntVec;

struct PolyLine
{
   IntVec          mPointIndex;
   double          mThickness;
   unsigned int    mJoints;
   unsigned int    mCaps;
   unsigned int    mPixelHinting;
   double          mMiterLimit;
};


class PolygonRenderer
{
public:
   virtual ~PolygonRenderer() {}
   virtual void Render(SDL_Surface *outDest,
                         Sint16 inOffsetX=0,Sint16 inOffsetY=0)=0;
   virtual bool HitTest(int inX,int inY)=0;

   static PolygonRenderer *CreateSolidRenderer(int inN,
                              const PointF16 *inPoints,
                              Sint32 inYMin, Sint32 inYMax,
                              Uint32 inFlags,
                              int inColour, double inAlpha,
                              const PolyLine *inLines = 0);


   static PolygonRenderer *CreateGradientRenderer(int inN,
                              const PointF16 *inPoints,
                              Sint32 inYMin, Sint32 inYMax,
                              Uint32 inFlags,
                              class Gradient *inGradient,
                              const PolyLine *inLines = 0);

   static PolygonRenderer *CreateBitmapRenderer(int inN,
                              const PointF16 *inPoints,
                              Sint32 inYMin, Sint32 inYMax,
                              Uint32 inFlags,
                              const class Matrix &inMapper,
                              SDL_Surface *inSource,
                              const PolyLine *inLines=0);
};



#endif
