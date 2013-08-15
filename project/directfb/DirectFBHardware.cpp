#include <Graphics.h>
#include <Surface.h>


namespace nme
{


void BuildHardwareJob(const GraphicsJob &inJob, const GraphicsPath &inPath, HardwareData &ioData, HardwareContext &inHardware)
{
   
}


// --- HardwareArrays ---------------------------------------------------------------------

HardwareArrays::HardwareArrays(Surface *inSurface,unsigned int inFlags)
{
   mFlags = inFlags;
   mSurface = inSurface;
   if (inSurface)
      inSurface->IncRef();
}

HardwareArrays::~HardwareArrays()
{
   if (mSurface)
      mSurface->DecRef();
}

bool HardwareArrays::ColourMatch(bool inWantColour)
{
   if (mVertices.empty())
      return true;
   return mColours.empty() != inWantColour;
}



// --- HardwareData ---------------------------------------------------------------------
HardwareData::~HardwareData()
{
   mCalls.DeleteAll();
}

HardwareArrays &HardwareData::GetArrays(Surface *inSurface,bool inWithColour,unsigned int inFlags)
{
   if (mCalls.empty() || mCalls.last()->mSurface != inSurface ||
           !mCalls.last()->ColourMatch(inWithColour) ||
           mCalls.last()->mFlags != inFlags )
   {
       HardwareArrays *arrays = new HardwareArrays(inSurface,inFlags);
       mCalls.push_back(arrays);
   }

   return *mCalls.last();
}



// --- Texture -----------------------------
void Texture::Dirty(const Rect &inRect)
{
   if (!mDirtyRect.HasPixels())
      mDirtyRect = inRect;
   else
      mDirtyRect = mDirtyRect.Union(inRect);
}

// --- HardwareContext -----------------------------


// Cache line thickness transforms...
static Matrix sLastMatrix;
double sLineScaleV = -1;
double sLineScaleH = -1;
double sLineScaleNormal = -1;


bool HardwareContext::Hits(const RenderState &inState, const HardwareCalls &inCalls )
{
   if (inState.mClipRect.w!=1 || inState.mClipRect.h!=1)
      return false;

   UserPoint screen(inState.mClipRect.x, inState.mClipRect.y);
   UserPoint pos = inState.mTransform.mMatrix->ApplyInverse(screen);

   if (sLastMatrix!=*inState.mTransform.mMatrix)
   {
      sLastMatrix=*inState.mTransform.mMatrix;
      sLineScaleV = -1;
      sLineScaleH = -1;
      sLineScaleNormal = -1;
   }


    for(int c=0;c<inCalls.size();c++)
   {
      HardwareArrays &arrays = *inCalls[c];
      Vertices &vert = arrays.mVertices;

      // TODO: include extent in HardwareArrays

      DrawElements &elements = arrays.mElements;
      for(int e=0;e<elements.size();e++)
      {
         DrawElement draw = elements[e];

         if (draw.mPrimType == ptLineStrip)
         {
            if ( draw.mCount < 2 || draw.mWidth==0)
               continue;

            double width = 1;
            Matrix &m = sLastMatrix;
            switch(draw.mScaleMode)
            {
               case ssmNone: width = draw.mWidth; break;
               case ssmNormal:
               case ssmOpenGL:
                  if (sLineScaleNormal<0)
                     sLineScaleNormal =
                        sqrt( 0.5*( m.m00*m.m00 + m.m01*m.m01 +
                                    m.m10*m.m10 + m.m11*m.m11 ) );
                  width = draw.mWidth*sLineScaleNormal;
                  break;
               case ssmVertical:
                  if (sLineScaleV<0)
                     sLineScaleV =
                        sqrt( m.m00*m.m00 + m.m01*m.m01 );
                  width = draw.mWidth*sLineScaleV;
                  break;

               case ssmHorizontal:
                  if (sLineScaleH<0)
                     sLineScaleH =
                        sqrt( m.m10*m.m10 + m.m11*m.m11 );
                  width = draw.mWidth*sLineScaleH;
                  break;
            }

            double x0 = pos.x - width;
            double x1 = pos.x + width;
            double y0 = pos.y - width;
            double y1 = pos.y + width;
            double w2 = width*width;

            UserPoint *v = &vert[ draw.mFirst ];
            UserPoint p0 = *v;

            int prev = 0;
            if (p0.x<x0) prev |= 0x01;
            if (p0.x>x1) prev |= 0x02;
            if (p0.y<y0) prev |= 0x04;
            if (p0.y>y1) prev |= 0x08;
            if (prev==0 && pos.Dist2(p0)<=w2)
               return true;
            for(int i=1;i<draw.mCount;i++)
            {
               UserPoint p = v[i];
               int flags = 0;
               if (p.x<x0) flags |= 0x01;
               if (p.x>x1) flags |= 0x02;
               if (p.y<y0) flags |= 0x04;
               if (p.y>y1) flags |= 0x08;
               if (flags==0 && pos.Dist2(p)<=w2)
                  return true;
               if ( !(flags & prev) )
               {
                  // Line *may* pass though the point...
                  UserPoint vec = p-p0;
                  double len = sqrt(vec.x*vec.x + vec.y*vec.y);
                  if (len>0)
                  {
                     double a = vec.Dot(pos-p0)/len;
                     if (a>0 && a<1)
                     {
                        if ( (p0 + vec*a).Dist2(pos) < w2 )
                           return true;
                     }
                  }
               }
               prev = flags;
               p0 = p;
            }
         }
         else if (draw.mPrimType == ptTriangleFan)
         {
            if (draw.mCount<3)
               continue;
            UserPoint *v = &vert[ draw.mFirst ];
            UserPoint p0 = *v;
            int count_left = 0;
            for(int i=1;i<=draw.mCount;i++)
            {
               UserPoint p = v[i%draw.mCount];
               if ( (p.y<pos.y) != (p0.y<pos.y) )
               {
                  // Crosses, but to the left?
                  double ratio = (pos.y-p0.y)/(p.y-p0.y);
                  double x = p0.x + (p.x-p0.x) * ratio;
                  if (x<pos.x)
                     count_left++;
               }
               p0 = p;
            }
            if (count_left & 1)
               return true;
         }
         else if (draw.mPrimType == ptTriangles)
         {
            if (draw.mCount<3)
               continue;
            UserPoint *v = &vert[ draw.mFirst ];
			
			   int numTriangles = draw.mCount / 3;
			
            for(int i=0;i<numTriangles;i++)
            {
               UserPoint base = *v++;
               bool bgx = pos.x>base.x;
               if ( bgx!=(pos.x>v[0].x) || bgx!=(pos.x>v[1].x) )
               {
                  bool bgy = pos.y>base.y;
                  if ( bgy!=(pos.y>v[0].y) || bgy!=(pos.y>v[1].y) )
                  {
                     UserPoint v0 = v[0] - base;
                     UserPoint v1 = v[1] - base;
                     UserPoint v2 = pos - base;
                     double dot00 = v0.Dot(v0);
                     double dot01 = v0.Dot(v1);
                     double dot02 = v0.Dot(v2);
                     double dot11 = v1.Dot(v1);
                     double dot12 = v1.Dot(v2);

                     // Compute barycentric coordinates
                     double denom = (dot00 * dot11 - dot01 * dot01);
                     if (denom!=0)
                     {
                        denom = 1 / denom;
                        double u = (dot11 * dot02 - dot01 * dot12) * denom;
                        if (u>=0)
                        {
                           double v = (dot00 * dot12 - dot01 * dot02) * denom;

                           // Check if point is in triangle
                           if ( (v >= 0) && (u + v < 1) )
                              return true;
                        }
                     }
                  }
               }
               v+=2;
            }
         }
      }
   }

   return false;
}



} // end namespace nme

