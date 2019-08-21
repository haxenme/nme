#include <Graphics.h>
#include <stdio.h>
#include <Hardware.h>
#include <set>


#ifdef NME_POLY2TRI
#include "poly2tri/Poly2Tri.h"
#endif
#ifdef NME_CLIPPER
#include "clipper/clipper.hpp"
#endif

namespace nme
{

const double INSIDE_TOL = 1e-12;





struct TriSearch
{
   UserPoint next;
   UserPoint prev;
   UserPoint min;
   UserPoint max;
   UserPoint p;
   UserPoint v1;
   UserPoint v2;
   double    denom;
   bool      isFlat;
   bool      isConcave;

   TriSearch(const UserPoint &inP0, const UserPoint &inPrev, const UserPoint &inNext)
   {
      p = inP0;
      next = inNext;
      prev = inPrev;
      v1 = next - p;
      v2 = prev - p;

      denom = v1.Cross(v2);

      isConcave = denom<0;

      if (!isConcave)
      {
         isFlat = denom<INSIDE_TOL;  // flat triangle 

         if (!isFlat)
         {
            denom -= INSIDE_TOL;

            min = p;
            if (next.x<min.x) min.x=next.x;
            if (next.y<min.y) min.y=next.y;
            if (prev.x<min.x) min.x=prev.x;
            if (prev.y<min.y) min.y=prev.y;
            max = p;
            if (next.x>max.x) max.x=next.x;
            if (next.y>max.y) max.y=next.y;
            if (prev.x>max.x) max.x=prev.x;
            if (prev.y>max.y) max.y=prev.y;
         }
      }
   }

   inline bool pointInTri(UserPoint concave)
   {
      UserPoint v( concave - p );
      double a = v.Cross(v2);
      if (a>INSIDE_TOL && a<denom)
      {
         double b = v1.Cross(v);
         // Ear contains concave point?
         return (b>INSIDE_TOL && (a+b)<denom && (a+b)>INSIDE_TOL);
      }
      return false;
   }
};




struct EdgePoint
{
   UserPoint p;
   EdgePoint *prev;
   EdgePoint *next;
   bool      isConcave;

   void init(const UserPoint &inPoint,EdgePoint *inPrev, EdgePoint *inNext)
   {
      p = inPoint;
      next = inNext;
      prev = inPrev;
      isConcave = false;
   }

   bool isDegenerate()
   {
      return (prev->p - p).Cross(next->p - p) == 0.0;
   }

   void unlink()
   {
      prev->next = next;
      next->prev = prev;
   }


   float calcCross()
   {
      return (prev->p - p).Cross(next->p - p);
   }

   bool calcConcave()
   {
      return (prev->p - p).Cross(next->p - p) > 0.0;
   }
};


struct ConcaveSet
{
   typedef std::multiset<UserPoint> PointSet;
   PointSet points;

   void add(EdgePoint *edge)
   {
      edge->isConcave = true;
      points.insert(edge->p);
   }

   void remove(EdgePoint *edge)
   {
      edge->isConcave = false;
      points.erase(edge->p);
   }

   bool isEar(EdgePoint *edge)
   {
      if (points.empty())
         return true;

      if (edge->isConcave)
         return false;

      TriSearch test(edge->p, edge->prev->p, edge->next->p);
      if (test.isConcave)
         return false;
      if (test.isFlat)
         return true;

      // TODO - maybe some quadtree style structure
      PointSet::const_iterator p = points.lower_bound(test.min);
      PointSet::const_iterator last = points.upper_bound(test.max);
      for( ; p!=last; ++p )
      {
         UserPoint concave = *p;
         // Y-bounds should be good since they are sorted by Y
         if (concave.x<test.min.x || concave.x>test.max.x )
            continue;

         if (test.pointInTri(concave))
            return false;
      }

      return true;
   }
};


void OutlineToEars(EdgePoint *head, int size, Vertices &outTriangles)
{
   outTriangles.reserve( outTriangles.size() + (size-2)*3);

   ConcaveSet concaveSet;

   for(EdgePoint *p = head; ; )
   {
      float cross = p->calcCross();
      if (fabs(cross)<INSIDE_TOL && p->p.Dist2(p->next->p)<0.00001 )
      {
         // erase point
         p->unlink();
         if (p==head)
         {
            p = head = p->next;
            if (p == p->next)
               return;
         }
         else
         {
            p = p->next;
            if (p==head)
               break;
         }
      }
      else
      {
         if (cross>0)
         {
            p->isConcave = true;
            concaveSet.add(p);
         }
         p = p->next;
         if (p==head)
            break;
      }
   }

   EdgePoint *pi= head;
   EdgePoint *p_end = pi->prev;

   while( pi!=p_end && size>2)
   {
      if ( concaveSet.isEar(pi) )
      {
         // Have ear triangle - yay - clip it
         outTriangles.push_back(pi->prev->p);
         outTriangles.push_back(pi->p);
         outTriangles.push_back(pi->next->p);

         //printf("  ear : %f,%f %f,%f %f,%f\n", pi->prev->p.x, pi->prev->p.y,
         //       pi->p.x, pi->p.y,
         //       pi->next->p.x, pi->next->p.y );

         pi->unlink();
         size --;
         if (size<3)
            break;

         EdgePoint *next = pi->next;
         EdgePoint *prev = pi->prev;

         while(next->isDegenerate())
         {
            if (next->isConcave)
              concaveSet.remove(next);
            next->unlink();
            next = next->next;
            size--;
            if (size<3)
               break;
         }
         // Has it stopped being concave?
         bool nextConcave = next->calcConcave();
         if (next->isConcave && !nextConcave)
            concaveSet.remove(next); 
         // Has it stopped being concave?
         else if (!next->isConcave && nextConcave)
            concaveSet.add(next); 

         while(prev->isDegenerate())
         {
            if (prev->isConcave)
              concaveSet.remove(prev); 
            prev->unlink();
            prev = prev->prev;
            size--;
            if (size<3)
               break;
         }

         // Has it stopped being concave?
         bool prevConcave = prev->calcConcave();
         if (prev->isConcave && !prevConcave)
            concaveSet.remove(prev);
         else if (!prev->isConcave && prevConcave)
            concaveSet.add(prev);


         // Take a step back and try again...
         pi = prev;
         p_end = pi->prev;
      }
      else
         pi = pi->next;
   }
}



// --- External interface ----------


enum PIPResult { PIP_NO, PIP_YES, PIP_MAYBE };

PIPResult PointInPolygon(UserPoint p0, UserPoint *ioPtr,int inN)
{
   int crossing = 0;
   for(int i=0;i<inN;i++)
   {
      UserPoint p1 = ioPtr[i];
      UserPoint p2 = ioPtr[ (i+1)%inN ];
      // Should probably do something a bit better here...
      if (p1.y==p0.y || p2.y==p0.y)
         return PIP_MAYBE;

      if (p1.y<p0.y && p2.y>p0.y)
      {
         double cross = (p1-p0).Cross(p2-p0);
         if (cross==0)
            return PIP_MAYBE;
         if (cross>0)
            crossing++;
      }
      else if(p1.y>p0.y && p2.y<p0.y)
      {
         double cross = (p1-p0).Cross(p2-p0);
         if (cross==0)
            return PIP_MAYBE;
         if (cross<0)
            crossing++;
      }
   }
   return (crossing & 1) ? PIP_YES : PIP_NO;
}


/*

       ^ next          v next
       |               |
       |               |
       |               |
 outer +               + inner
       |               |
       |               |
       |               |
       ^ prev          v  next



       ^ next          v next
       |               |
       |               |
       |               |
 buf0  +----<----------+ inner
 outer +---->----------+ buf1  
       |               |
       |               |
       |               |
       ^ prev          v  next

*/




int LinkSubPolys(EdgePoint *inOuter,  EdgePoint *inInner, EdgePoint *inBuffer)
{
   int count = 0;

   // Holes are sorted left-to-right, and connected to the left, to avoid
   //  connecting holes with lines that might go through other holes
   //
   //  Find left-most inner(hole) point
   EdgePoint *bestIn = inInner;
   double leftX = bestIn->p.x;
   for(EdgePoint *in = inInner;  ; )
   {
      count++;
      if (in->p.x < leftX)
      {
         leftX = in->p.x;
         bestIn = in;
      }
      in = in->next;
      if (in==inInner) break;
   }
   double leftY = bestIn->p.y;

   // Now, shoot ray left to find outer intersection

   double closestX = -1e39;
   double bestAlpha = 0.0;
   EdgePoint *bestOut = 0;
   EdgePoint *e0 = inOuter;
   for(EdgePoint *e0 = inOuter;  ; )
   {
      if ( fabs(e0->p.y-leftY) < 0.0001 )
      {
         if (e0->p.x<=leftX && e0->p.x>closestX)
         {
            bestOut = e0;
            closestX = e0->p.x;
            bestAlpha = 0.0;
         }
      }
      else if ( ( (e0->p.y<leftY) && (e0->next->p.y>leftY) ) ||
                  (e0->p.y>leftY) && (e0->next->p.y<leftY) )
      {
         if (e0->p.x < leftX || e0->next->p.x<leftX)
         {
            double alpha = fabs( e0->p.y - leftY ) / fabs( e0->p.y - e0->next->p.y);
            double x = e0->p.x + (e0->next->p.x-e0->p.x) * alpha;
            if (x<=leftX && x>closestX)
            {
               closestX = x;
               bestOut = e0;
               bestAlpha = alpha;
            }
         }
      }

      e0 = e0->next;
      if (e0==inOuter)
         break;
   }

   if (!bestOut)
   {
      printf("Could not link hole\n");
      return 0;
   }

   if (bestAlpha>0.9999)
   {
      bestOut = bestOut->next;
      bestAlpha = 0;
   }
   else if (bestAlpha>0.0001)
   {
      // Insert node into outline
      EdgePoint *b = inBuffer + 2;
      b->init( UserPoint(closestX,bestOut->p.y + ( bestOut->next->p.y- bestOut->p.y) * bestAlpha),
                bestOut, bestOut->next );

      bestOut->next->prev = b;
      bestOut->next = b;

      bestOut = b;
      count ++;
   }
   else
      bestAlpha = 0;

   if (bestAlpha==0)
   {
      /* Hole links to outline at a common point...
      
      outer            inner
         ^ next       v prev
         |           /
         |         /
         |       /
 bestOut +     +  bestIn
         |       \
         |         \
         |           \
         ^ prev      v  next



      outer            inner
         ^ next   v prev
         |       /
         |     /
         |   /
 bestOut + /
 

           +  bestIn
         |  \
         |    \
         |      \
         ^ prev  v next

      */

      EdgePoint *prevBestOut = bestOut->prev;
      bestOut->prev = bestIn->prev;
      bestOut->prev->next = bestOut;

      bestIn->prev = prevBestOut;
      prevBestOut->next = bestIn;

      return count;
   }
   else
   {
      inBuffer[0] = *bestOut;
      inBuffer[1] = *bestIn;

      bestOut->next = inBuffer+1;
      inBuffer[1].prev = bestOut;
      inBuffer[1].next->prev = inBuffer + 1;

      bestIn->next = inBuffer;
      bestIn->prev->next = bestIn;
      inBuffer[0].prev = bestIn;
      inBuffer[0].next->prev = inBuffer;
   }

   return count+2;
}

struct SubInfo
{
   EdgePoint *first;
   EdgePoint  link[3];
   int        size;
   float      x0,x1;
   float      y0,y1;


   // Non-clipper method - first set the points, then sort and calculate reverse then link
   #ifndef NME_CLIPPER

   UserPoint *vertices;
   int        group;
   bool       is_internal;
   int        p0;
   

   void setPolygon( int inP0, int inSize, UserPoint *inVertices)
   {
      p0 = inP0;
      size = inSize;
      vertices = inVertices + p0;
      is_internal = false;

      x0 = x1 = vertices[0].x;
      y0 = y1 = vertices[0].y;
      for(int i=1;i<size;i++)
      {
         UserPoint &p = vertices[i];
         if (p.x < x0) x0 = p.x;
         if (p.x > x1) x1 = p.x;
         if (p.y < y0) y0 = p.y;
         if (p.y > y1) y1 = p.y;
      }
   }

   void linkPolygon(EdgePoint *edgeBuffer, UserPoint *inP, int inN,bool inReverse)
   {
      first = edgeBuffer + 0;
      for(int i=0;i<inN;i++)
      {
         int prev = (i+inN-1) % inN;
         int next = (i+1) % inN;
         if (inReverse)
            std::swap(prev,next);
         edgeBuffer[i].init(inP[i], &edgeBuffer[prev], &edgeBuffer[next]);
      }
   }


   bool operator <(const SubInfo &inOther) const
   {
      // Extents not overlap - call it even
      if (x1 <= inOther.x0 || x0>=inOther.x1 || y1 <= inOther.y0 || y0>=inOther.y1 )
         return false;

      bool allOtherInExtent = true;
      for(int i=0;i<inOther.size;i++)
         if (!contains(inOther.vertices[i]))
         {
            allOtherInExtent = false;
            break;
         }

      bool allInOtherExtent = true;
      for(int i=0;i<size;i++)
         if (!inOther.contains(vertices[i]))
         {
            allInOtherExtent = false;
            break;
         }
      if (allOtherInExtent != allInOtherExtent)
      {
         // This is less than (parent-to) other
         return allOtherInExtent;
      }

      // Extents overlap - even.  Possibly some situation here?
      //if (allInOtherExtent) printf("HUH?");

      return false;
   }

   bool contains(const UserPoint inP) const
   {
      return inP.x>=x0 && inP.x<=x1 && inP.y>=y0 && inP.y<=y1;
   }



   #else
   // Clipper method - Points are already sorted - just link....
   std::vector<EdgePoint> edgeBuffer;

   void linkPolygon(const ClipperLib::IntPoint *inP, int inN, UserPoint inBase, float unscale, bool inReverse=false)
   {
      edgeBuffer.resize(inN);
      size = inN;

      first =&edgeBuffer[0];
      for(int i=0;i<inN;i++)
      {
         int prev = (i+inN-1) % inN;
         int next = (i+1) % inN;
         if (inReverse)
            std::swap(prev,next);

         UserPoint p( inBase.x + inP[i].X*unscale, inBase.y+inP[i].Y*unscale );

         if (i==0)
         {
            x0 = x1 = p.x;
            y0 = y1 = p.y;
         }
         else
         {
            if (p.x < x0) x0 = p.x;
            if (p.x > x1) x1 = p.x;
            if (p.y < y0) y0 = p.y;
            if (p.y > y1) y1 = p.y;
         }

         edgeBuffer[i].init(p,&edgeBuffer[prev], &edgeBuffer[next]);
      }
   }

   #endif


};



static bool sortLeft(SubInfo *a, SubInfo *b)
{
    return a->x0 < b->x0;
}




void TriangulateSubPolys(SubInfo *outer, QuickVec<SubInfo *> &holes,  Vertices &outTriangles)
{
   int holeCount = holes.size();
   int size = outer->size;
   #ifdef NME_POLY2TRI
      int totalSize = outer->size;
      for(int i=0;i<holes.size();i++)
         totalSize += holes[i]->size;

      p2t::Poly2Tri *poly2Tri = p2t::Poly2Tri::create();

      std::vector< p2t::Point> pointBuffer(totalSize);
      EdgePoint *p = outer->first;
      int p0 = 0;
      for(int i=0;i<size;i++)
         pointBuffer[i].set( p[i].p.x, p[i].p.y );
      poly2Tri->AddSubPoly(&pointBuffer[0],size);
      p0 += size;

      for(int h=0;h<holeCount;h++)
      {
         SubInfo &poly = *holes[h];
         int size = poly.size;
         EdgePoint *p = poly.first;
         for(int i=0;i<size;i++)
            pointBuffer[p0+i].set( p[i].p.x, p[i].p.y );

         poly2Tri->AddSubPoly(&pointBuffer[p0],size);
         p0 += size;
      }

      const std::vector< p2t::Triangle* > &tris = poly2Tri->Triangulate();

      for(int i=0;i<tris.size();i++)
      {
         p2t::Triangle *tri = tris[i];
         outTriangles.push_back( *tri->GetPoint(0) );
         outTriangles.push_back( *tri->GetPoint(1) );
         outTriangles.push_back( *tri->GetPoint(2) );
      }

      delete poly2Tri;

   #else
      if (holeCount)
      {
         std::sort(holes.begin(), holes.end(), sortLeft);

         for(int h=0;h<holeCount;h++)
         {
            SubInfo &info = *holes[h];
            size += LinkSubPolys(outer->first,info.first, info.link);
         }
      }
      EdgePoint *p = outer->first;
      OutlineToEars(outer->first, size, outTriangles);
   #endif
}








#ifdef NME_CLIPPER

static void dump(const SubInfo &sub)
{
   const EdgePoint *p = sub.first;
   printf("g.moveTo(%f,%f);", p->p.x, p->p.y);
   for(int i=1;i<sub.size;i++)
   {
      p++;
      printf(" g.lineTo(%f,%f);", p->p.x, p->p.y);
   }
   p = sub.first;
   printf("g.lineTo(%f,%f);", p->p.x, p->p.y);
   printf("\n");
}

// Clipper Version
void ConvertOutlineToTriangles(Vertices &ioOutline,const QuickVec<int> &inSubPolys,WindingRule inWinding)
{
   Vertices triangles;

   int subs = inSubPolys.size();
   int n = ioOutline.size();
   if (subs<1 || n<1)
      return;

   float minX = ioOutline[0].x;
   float maxX = minX;
   float minY = ioOutline[0].y;
   float maxY = minY;
   for(int i=1;i<n;i++)
   {
      if (ioOutline[i].x < minX) minX = ioOutline[i].x;
      if (ioOutline[i].x > maxX) maxX = ioOutline[i].x;
      if (ioOutline[i].y < minY) minY = ioOutline[i].y;
      if (ioOutline[i].y > maxY) maxY = ioOutline[i].y;
   }
   float diffX = maxX-minX;
   float diffY = maxY-minY;
   if (diffX==0 || diffY==0) return;
   float diff = diffX > diffY ? diffX : diffY;
   float scale = (float)(0x40000000)/diff;
   float unscale = 1.0/scale;

   ClipperLib::Clipper clipper(ClipperLib::ioStrictlySimple);

   ClipperLib::Paths paths(subs);
   int prev = 0;
   for(int i=0;i<subs;i++)
   {
      ClipperLib::Path &path = paths[i];
      int s = inSubPolys[i] - prev;
      path.resize(s);
      for(int j=0;j<s;j++)
      {
         const UserPoint &p = ioOutline[j+prev];
         path[j] = ClipperLib::IntPoint( (p.x-minX)*scale, (p.y-minY)*scale );
         //printf(" %f,%f\n", p.x, p.y);
      }
      //printf("---\n");
   }

   try
   {
      clipper.AddPaths(paths, ClipperLib::ptSubject, true);
   }
   catch(...)
   {
      // Hmmm
      return;
   }

   // TODO - winding pftEvenOdd, pftNonZero
   ClipperLib::PolyTree solution;
   clipper.Execute(ClipperLib::ctUnion, solution, ClipperLib::pftEvenOdd, ClipperLib::pftEvenOdd);


   ClipperLib::PolyNode *poly = solution.GetFirst();
   QuickVec<SubInfo *> empty;
   while(poly)
   {
      const ClipperLib::Path &path = poly->Contour;
      float px = path[0].X;
      float py = path[0].Y;
      float area = 0.0;
      for(int i=1;i<path.size();i++)
      {
         float x = path[i].X;
         float y = path[i].Y;
         area += x*py - y*px;
         px = x;
         py = y;
      }
      float x = path[0].X;
      float y = path[0].Y;
      area += x*py - y*px;
      bool reverse = area>0;

      SubInfo outer;
      ClipperLib::PolyNodes &children = poly->Childs;
      int kids = children.size();
      outer.linkPolygon( &path[0], path.size(), UserPoint(minX,minY), unscale, reverse );
      //dump(outer);

      QuickVec<SubInfo> holes(kids);
      QuickVec<SubInfo *> holesPtr(kids);

      for(int c=0;c<kids;c++)
      {
         const ClipperLib::Path &path = children[c]->Contour;
         holes[c].linkPolygon( &path[0], path.size(), UserPoint(minX,minY), unscale, reverse );
         holesPtr[c] = &holes[c];
         //dump(holes[c]);
      }

      TriangulateSubPolys(&outer, holesPtr,  triangles);

      poly = poly->GetNext();
   }

   ioOutline.swap(triangles);
}

#else






// Non-clipper version

void ConvertOutlineToTriangles(Vertices &ioOutline,const QuickVec<int> &inSubPolys,WindingRule inWinding)
{
   #ifdef NME_INTERNAL_CLIPPING
   if (inSubPolys.size()<1)
      return;
   QuickVec<int> subPolys(inSubPolys);
   NmeClipOutline(ioOutline,subPolys,inWinding);
   #else
   const QuickVec<int> &subPolys(inSubPolys);
   #endif

   int subs = subPolys.size();
   if (subs<1)
      return;

   Vertices triangles;

   // Order polygons ...
   QuickVec<EdgePoint> edgeBuffer(ioOutline.size());

   QuickVec<SubInfo> subInfo(subs);
   int bigSubs = 0;
   int p0 = 0;
   for(int i=0;i<subs;i++)
   {
      int size = subPolys[i]-p0;
      if (size>2 && ioOutline[p0] == ioOutline[p0+size-1])
         size--;

      if (size>2)
         subInfo[bigSubs++].setPolygon(p0,size, &ioOutline[0]);
      p0 = subPolys[i];
   }
   subInfo.resize(subs=bigSubs);
   std::sort(subInfo.begin(), subInfo.end());



   int groupId = 0;
   int edgeBufferStart = 0;

   for(int sub=0;sub<subs;sub++)
   {
      SubInfo &info = subInfo[sub];

      UserPoint *p = &ioOutline[info.p0];
      double area = 0.0;
      for(int i=2;i<info.size;i++)
      {
         UserPoint v_prev = p[i-1] - p[0];
         UserPoint v_next = p[i] - p[0];
         area += v_prev.Cross(v_next);
      }
      bool reverse = area < 0;
      int  parent = -1;

      for(int prev=sub-1; prev>=0 && parent==-1; prev--)
      {
         if (subInfo[prev].contains(p[0]))
         {
            int prev_p0 = subInfo[prev].p0;
            int prev_size = subInfo[prev].size;
            int inside = PIP_MAYBE;
            for(int test_point = 0; test_point<info.size && inside==PIP_MAYBE; test_point++)
            {
               inside =  PointInPolygon( p[test_point], &ioOutline[prev_p0], prev_size);
               if (inside==PIP_YES)
                  parent = prev;
            }
         }
      }

      if (parent==-1 || subInfo[parent].is_internal )
      {
         info.group = groupId++;
         info.is_internal = false;
      }
      else
      {
         info.group = subInfo[parent].group;
         info.is_internal = true;
      }

      info.linkPolygon(&edgeBuffer[edgeBufferStart],p,info.size,reverse!=info.is_internal);

      edgeBufferStart += info.size;
   }


   for(int group=0;group<groupId;group++)
   {
      int first = -1;
      QuickVec<SubInfo *> holes;
      for(int sub=0;sub<subInfo.size();sub++)
      {
         SubInfo &info = subInfo[sub];
         if (info.group==group)
         {
            if (first<0)
            {
               first = sub;
            }
            else
            {
               holes.push_back(&info);
            }
         }
      }
      if (first>=0)
      {
         TriangulateSubPolys(&subInfo[first], holes, triangles);
      }
   }

   ioOutline.swap(triangles);
}
#endif

} // end namespace nme
