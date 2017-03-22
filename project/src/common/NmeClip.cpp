#include <Graphics.h>
#include <stdio.h>
#include <Hardware.h>
#include <set>


namespace nme
{

struct PolyEdge;
struct PolyNode;

//#define VERIFY

struct PolyNode : public UserPoint
{
   union
   {
      PolyNode *fused;
      PolyEdge **edges;
   };
   short      edgeCount;
   bool       done;

   void set(const UserPoint &inP)
   {
      x = inP.x;
      y = inP.y;
      fused = 0;
      edges = 0;
      edgeCount = 0;
      done = false;
   }
   inline bool operator<(const PolyNode &other) const
   {
      if (other.y==y)
         return x < other.x;
      return y<other.y;
   }

   void addEdge(PolyEdge *inEdge)
   {
      edges[edgeCount++] = inEdge;
   }

   PolyEdge *getOtherEdge(PolyEdge *inEdge)
   {
      if (edgeCount!=2)
         return 0;
      return edges[ edges[0]==inEdge ? 1 : 0 ];
   }

   PolyEdge *previousEdge(PolyEdge *edge)
   {
      for(int e=0;e<edgeCount;e++)
         if (edges[e]==edge)
            return edges[ (e+edgeCount-1) % edgeCount ];
      printf("Node missing previous edge?\n");
      return 0;
   }

   void removeEdge(PolyEdge *edge)
   {
      for(int e=0;e<edgeCount;e++)
      {
         if (edges[e]==edge)
         {
            for(int src=e+1; src<edgeCount; src++)
               edges[src-1]=edges[src];
            edgeCount--;
            return;
         }
      }
      printf("Node missing edge?\n");
   }


   void consume(PolyNode *inOther)
   {
      inOther->fused = this;
      edgeCount += inOther->edgeCount;
      inOther->edgeCount = 0;
   }
};

/*
   Edges always go from lesser node to bigger node
   If this differs from the given order, windDelta will be -1


                 +n1
                ^
               / rightWind = winding count on this side of the line
   leftWind   /  
             /               ----> cast ray to the right and count crossings
            /   ------------/       rays go infinitesimally above horizontal
           +n0                      and therefore make it easy to work out what happens
                                    to points on the same y-coordinate.

*/


struct PolyEdge
{
   PolyNode   *node[2];
   short       rightWind;
   short       leftWind;
   signed char windDelta;
   bool        done;


   void set(PolyNode *inN0, PolyNode *inN1)
   {
      leftWind = rightWind = 0;
      done = false;
      if (*inN1 < *inN0)
      {
         windDelta = -1;
         node[0] = inN1;
         node[1] = inN0;
      }
      else
      {
         windDelta = 1;
         node[0] = inN0;
         node[1] = inN1;
      }
      inN0->edgeCount++;
      inN1->edgeCount++;
   }

   // Used when splitting
   void set(PolyNode *inN0, PolyNode *inN1,int inWindDelta)
   {
      node[0] = inN0;
      node[1] = inN1;
      windDelta = inWindDelta;
      if (windDelta==0)
         printf("BAD WINDELTA!\n");
      leftWind = rightWind = 0;
      done = false;
   }


   bool isAbove(PolyNode *inNode)
   {
      return node[0]==inNode;
   }


   PolyNode *otherNode(PolyNode *inNode)
   {
      return node[node[0]==inNode ? 1 : 0];
   }

   int otherNodeId(PolyNode *inNode)
   {
      return node[0]==inNode ? 1 : 0;
   }


   bool isInterior(bool inOddEven)
   {
      if (inOddEven)
         return (leftWind & 0x01) == (rightWind & 0x01);
      else
         return (leftWind!=0) == (rightWind!=0);
   }
};





static bool edgePtrCmp(PolyEdge *e0, PolyEdge *e1)
{
   return *(e0->node[0]) < *(e1->node[0]);
}


static bool nodePtrCmp(PolyNode *n0, PolyNode *n1)
{
   return *(n0) < *(n1);
}

/*
  I think of shapes with y-axis pointing up.
  This is not actaully the case, but the logic is still the same if we are consistent.

  Order the axis going clockwise, with the negative x-axis being least, and just below it the most

        o1|o2     octants for faster sorting
          |  
     o0  \|/  o3
     -----+-----
     o7  /|\ o4
          | 
        o6|o5

*/

int getEdgeOctant(PolyNode *inNode, PolyEdge *inEdge)
{
      int end = inEdge->node[0]==inNode ? 0 : 1;
      UserPoint vec = *inEdge->node[!end] - *inEdge->node[end];
      int octant = 0;

      if (vec.y>=0)
      {
         if (vec.x<0)
            octant = vec.x<-vec.y ? 0 : 1;
         else
            octant = vec.y>vec.x ? 2 : 3;
      }
      else
      {
         if (vec.x>0)
            octant = vec.x>-vec.y ? 4 : 5;
         else
            octant = vec.x>vec.y ? 6 : 7;
      }

   return octant;
}

double getEdgeAngle(PolyNode *inNode, PolyEdge *inEdge,bool inPrint=false)
{
   int end = inEdge->node[0]==inNode ? 0 : 1;
   UserPoint vec = *inEdge->node[!end] - *inEdge->node[end];
   if (inPrint)
      printf(" %f,%f\n", vec.x, vec.y);
   return -atan2(vec.y, vec.x);
}




struct SortEdge
{
   PolyEdge *edge;
   UserPoint vec;
   int       octant;

   void set(PolyNode *inNode, PolyEdge *inEdge)
   {
      edge = inEdge;
      int end = edge->node[0]==inNode ? 0 : 1;
      vec = *edge->node[!end] - *edge->node[end];

      if (vec.y>=0)
      {
         if (vec.x<0)
            octant = vec.x<-vec.y ? 0 : 1;
         else
            octant = vec.y>vec.x ? 2 : 3;
      }
      else
      {
         if (vec.x>0)
            octant = vec.x>-vec.y ? 4 : 5;
         else
            octant = vec.x>vec.y ? 6 : 7;
      }
   }

   bool operator<(const SortEdge &inOther) const
   {
      if (octant!=inOther.octant)
         return octant<inOther.octant;
      return vec.Cross(inOther.vec) < 0;
   }

};

#define NME_FUSE_DIST  1e-5
#define NME_FUSE_DIST2 1e-10
#define NME_FUSE_ALPHA  1e-4

struct NmeClip
{
   typedef QuickVec<PolyEdge> EdgeBuffer;
   typedef QuickVec<PolyNode> NodeBuffer;

   bool            oddEven;

   NodeBuffer      mainNodeBuffer;
   QuickVec<NodeBuffer *> extraNodeBuffers;
   int             nodePos;
   NodeBuffer      *nodeAllocBuffer;

   EdgeBuffer         mainEdgeBuffer;
   QuickVec<EdgeBuffer *> extraEdgeBuffers;
   EdgeBuffer         *edgeAllocBuffer;
   int                edgePos;


   QuickVec<PolyNode *> allNodes;
   QuickVec<PolyEdge *> allEdges;
   QuickVec<PolyEdge *> nodeEdges;
   QuickVec<PolyNode *> nodeStack;
   QuickVec<SortEdge>   edgeSortBuf;

   NmeClip(const Vertices &ioOutline,const QuickVec<int> &inSubPolys, bool inOddEven)
   {
      oddEven = inOddEven;
      int n = ioOutline.size();

      mainNodeBuffer.resize(n*2);
      nodeAllocBuffer = &mainNodeBuffer;
      nodePos = 0;

      mainEdgeBuffer.resize(n*2);
      edgeAllocBuffer = &mainEdgeBuffer;
      edgePos = 0;

      for(int i=0;i<n;i++)
         mainNodeBuffer[nodePos++].set(ioOutline[i]);

      int start = 0;
      for(int s=0;s<inSubPolys.size();s++)
      {
         int end = inSubPolys[s];
         int len = end-start;
         int prev = end-1;
         int nodePos0 = nodePos;
         for(int i=start;i<end;i++)
         {
            if (mainNodeBuffer[i]!=mainNodeBuffer[prev])
               mainEdgeBuffer[edgePos++].set(&mainNodeBuffer[prev], &mainNodeBuffer[i]);
            prev = i;
         }
         start = end;
      }
      //printf("Added %d nodes, %d edges\n", nodePos, edgePos);

      allNodes.resize(nodePos);
      for(int i=0;i<nodePos;i++)
         allNodes[i]=&mainNodeBuffer[i];
      bool anyFused = fuseNodes(allNodes);

      allEdges.resize( edgePos );
      for(int e=0;e<edgePos;e++)
      {
         PolyEdge *edge = allEdges[e] = &mainEdgeBuffer[e];
         if (anyFused)
         {
            while(edge->node[0]->fused)
            {
               edge->node[0] = edge->node[0]->fused;
            }
            while(edge->node[1]->fused)
            {
               edge->node[1] = edge->node[1]->fused;
            }
         }
      }

      intersectEdges();

      setNodeEdges();

      sortEdges();

      calculateWindings();

      removeInteriorEdges();
   }
   ~NmeClip()
   {
      extraEdgeBuffers.DeleteAll();
      extraNodeBuffers.DeleteAll();
   }

   PolyEdge *allocEdge()
   {
      if (edgePos >= edgeAllocBuffer->size())
      {
         EdgeBuffer *buffer = new EdgeBuffer( mainEdgeBuffer.size()/2 );
         extraEdgeBuffers.push_back(buffer);
         edgeAllocBuffer = buffer;
         edgePos = 0;
      }

      return &(*edgeAllocBuffer)[edgePos++];
   }


   PolyNode *allocNode()
   {
      if (nodePos >= nodeAllocBuffer->size())
      {
         NodeBuffer *buffer = new NodeBuffer( mainNodeBuffer.size()/2 );
         extraNodeBuffers.push_back(buffer);
         nodeAllocBuffer = buffer;
         nodePos = 0;
      }

      return &(*nodeAllocBuffer)[nodePos++];
   }

   void verifyEdges()
   {
      for(int e=1; e<allEdges.size();e++)
         if (edgePtrCmp(allEdges[e],allEdges[e-1]))
         {
            *(int *)0=0;
            printf("BAD EDGE!\n");
         }
   }

   void verifyNodes()
   {
      for(int n=1; n<allNodes.size();n++)
         if (nodePtrCmp(allNodes[n],allNodes[n-1]))
            printf("BAD NODE!\n");
   }

   bool fuseNodes(QuickVec<PolyNode *> &nodes)
   {
      bool anyFused = false;
      std::sort( nodes.begin(), nodes.end(), nodePtrCmp );

      for(int outer=0; outer<nodes.size(); outer++)
      {
         for(int inner=outer+1; inner<nodes.size(); /* */ )
         {
            if (nodes[inner]->y > nodes[outer]->y+NME_FUSE_DIST)
               break;

            if ( nodes[inner]->Dist2( *nodes[outer] )<NME_FUSE_DIST2)
            {
               //printf("Fuse!\n");
               nodes[outer]->consume(nodes[inner]);
               anyFused = true;
               nodes.EraseAt(inner);
            }
            else
               inner++;
         }
      }
      return anyFused;
   }

   void insertEdge(PolyEdge *e, int inMin)
   {
      int min=inMin;
      int max = allEdges.size();
      while(max>min+1)
      {
         int mid = (min+max)>>1;
         if (edgePtrCmp(e,allEdges[mid]))
            max = mid;
         else
            min = mid;
      }
      allEdges.InsertAt(min+1,e);
      #ifdef VERIFY
      verifyEdges();
      #endif

   }

   PolyNode *insertNode(UserPoint p)
   {
      // Find node less-than or equal to p.
      //  p is an interpolation, so will not be first or last
      int min = 0;
      int max = allNodes.size();
      while(max>min+1)
      {
         int mid = (min+max)>>1;
         if (p<*allNodes[mid])
            max = mid;
         else
            min = mid;
      }
      // check around min of close match...
      for(int i=min; i>=0; i--)
      {
         PolyNode *node = allNodes[i];
         if (fabs(node->y-p.y)>NME_FUSE_DIST)
            break;
         if (node->Dist2(p)<NME_FUSE_DIST2)
            return node;
      }
      for(int i=min+1; i<allNodes.size(); i++)
      {
         PolyNode *node = allNodes[i];
         if (fabs(node->y-p.y)>NME_FUSE_DIST)
            break;
         if (node->Dist2(p)<NME_FUSE_DIST2)
            return node;
      }

      // No match found so insert after min...
      PolyNode *node = allocNode();
      node->set(p);
      allNodes.InsertAt(min+1,node);
      return node;
   }

   void intersectEdges()
   {
      std::sort( allEdges.begin(), allEdges.end(), edgePtrCmp );
      #ifdef VERIFY
      verifyEdges();
      #endif

      //printf("intersect %d\n", allEdges.size());
      for(int outer=0; outer<allEdges.size(); outer++)
      {
         PolyEdge *edgeO = allEdges[outer];
         PolyNode *no0 = edgeO->node[0];
         PolyNode *no1 = edgeO->node[1];
         UserPoint o0 = *no0;
         UserPoint o1 = *no1;
         UserPoint oDiff = o1-o0;
         double norm2 = oDiff.Norm2();

         for(int inner=outer+1; inner<allEdges.size(); inner++)
         {
            PolyEdge *edgeI = allEdges[inner];
            PolyNode *ni0 = edgeI->node[0];
            UserPoint i0 = *ni0;
            if (i0 > o1)
               break;
            PolyNode *ni1 = edgeI->node[1];
            UserPoint i1 = *ni1;

            if (o1==i0 || o1==i1 || o0==i0 || o0==i1)
            {
               // TODO - check overlap
               continue;
            }

            float minOx = std::min( o0.x, o1.x );
            float maxOx = std::max( o0.x, o1.x );
            float minIx = std::min( i0.x, i1.x );
            float maxIx = std::max( i0.x, i1.x );
            if (maxIx < minOx || minIx>maxOx)
               continue;
            UserPoint iDiff = i1-i0;
            double cross = oDiff.Cross(iDiff);
            if ( fabs(cross) < NME_FUSE_DIST )
            {
               // Parallel - are they co-linear?
               double perp = oDiff.Cross(i0-o0);
               if ( fabs(perp)<NME_FUSE_DIST2*norm2)
               {
                  // Colinear...
                  // Do they overlap?
                  double a0 = (i0-o0).Dot(oDiff)/norm2;
                  double a1 = (i1-o0).Dot(oDiff)/norm2;
                  if ( (a0<=0 && a1<=0) || (a0>=1 && a1>=1) )
                  {
                     // non-overlap
                  }
                  else
                  {
                     printf("TODO - overlap colinear\n");
                  }
               }
               continue;
            }
            UserPoint baseDiff = i0-o0;
            double alpha = baseDiff.Cross(iDiff)/cross;

            if (alpha>-NME_FUSE_ALPHA && alpha<(1+NME_FUSE_ALPHA) )
            {
               double beta = baseDiff.Cross(oDiff)/cross;
               if (beta>-NME_FUSE_ALPHA && beta<(1+NME_FUSE_ALPHA) )
               {
                  //printf("  intersect %f,%f\n", alpha, beta);

                  bool insertOn0 = alpha>NME_FUSE_ALPHA && alpha < (1-NME_FUSE_ALPHA);
                  bool insertOn1 = beta>NME_FUSE_ALPHA && beta < (1-NME_FUSE_ALPHA);

                  if (insertOn0 && insertOn1)
                  {
                     UserPoint insert = o0 + oDiff*alpha;
                     // printf(" AT %f,%f\n", insert.x, insert.y );
                     PolyNode *node = insertNode(insert);
                     node->edgeCount += 4;

                     // printf("Allcate edge %d...\n", edgePos);
                     PolyEdge *newEdge0 = allocEdge();
                     newEdge0->set(node, no1, edgeO->windDelta);
                     edgeO->node[1] = node;

                     PolyEdge *newEdge1 = allocEdge();
                     newEdge1->set(node, ni1, edgeI->windDelta);
                     edgeI->node[1] = node;

                     insertEdge(newEdge0,outer);
                     insertEdge(newEdge1,outer);

                     no1 = node;
                     o1 = *no1;
                     oDiff = o1-o0;
                     norm2 = oDiff.Norm2();
                  }
                  else if (insertOn0)
                  {
                     PolyNode *node = edgeI->node[ beta>0.5 ];
                     edgeO->node[1] = node;
                     node->edgeCount += 2;

                     PolyEdge *newEdge0 = allocEdge();
                     newEdge0->set(node, no1, edgeO->windDelta);
                     insertEdge(newEdge0,outer);

                     no1 = node;
                     o1 = *no1;
                     oDiff = o1-o0;
                     norm2 = oDiff.Norm2();
                  }
                  else if (insertOn1)
                  {
                     PolyNode *node = edgeO->node[ alpha>0.5 ];
                     edgeI->node[1] = node;
                     node->edgeCount += 2;

                     PolyEdge *newEdge1 = allocEdge();
                     newEdge1->set(node, ni1, edgeI->windDelta);
                     insertEdge(newEdge1,outer);
                  }
                  else
                  {
                     printf("TODO - join nodes\n");
                  }


                  #ifdef VERIFY
                  verifyNodes();
                  #endif
               }
            }
         }
      }
   }

   void propagateWinding()
   {
      while(nodeStack.size())
      {
         PolyNode *node = nodeStack.qpop();

         int n = node->edgeCount;
         // Find first known edge...
         int e0 = -1;
         for(int e=0;e<n;e++)
            if ( node->edges[e]->done )
            {
               e0 = e;
               break;
            }
         if (e0<0)
            continue;

         int prev = e0;
         for(int e=1;e<n;e++)
         {
            int epos = (e0+e)%n;
            PolyEdge *target = node->edges[epos];
            if (!target->done)
            {
               PolyEdge *src = node->edges[prev];
               /* Transfer winding to adjacent edge ...

                 src (prev, known)
                   \
                    \  w
                     \  \
                      \   w
                       +------- target  (epos)

               */
               bool srcUp = src->isAbove(node);
               int w = srcUp ? src->rightWind : src->leftWind;
               bool targetUp = target->isAbove(node);

               if (targetUp)
               {
                  target->leftWind = w;
                  target->rightWind = w-target->windDelta;
               }
               else
               {
                  target->rightWind = w;
                  target->leftWind = w+target->windDelta;
               }
               target->done = true;
               PolyNode *tend = target->otherNode(node);
               if (!tend->done)
               {
                  tend->done = true;
                  nodeStack.push_back(tend);
               }
            }
            prev = epos;
         }
      }

      // printf("pushEdgeInfo %p : %p\n", edge, edge->node[inNode] );
      /*
       n=2 speedup ...
      if (edge->node[inNode]->edgeCount==2)
      {
         PolyEdge *next = edge->node[inNode]->getOtherEdge(edge);
         if (next->done)
            return;
         bool flipSide =  (next->windDelta!=edge->windDelta);
         int otherNode = next->otherNodeId(edge->node[inNode]);
         #ifdef VERIFY
         // printf("Pushing info from %p to %p\n", edge, next);
         // printf(" from %d -> %d\n", edge->leftIn, edge->rightIn );
         // printf(" winding %d -> %d\n", edge->windDelta, next->windDelta );
         // printf(" node %d -> %d\n", inNode, otherNode );
         #endif
         next->leftIn = flipSide ? edge->rightIn : edge->leftIn;
         next->rightIn = flipSide ? edge->leftIn : edge->rightIn;
         next->done = true;
         pushEdgeInfo(next,otherNode);
      }
      */
   }


   void printGeom()
   {
      #ifndef VERIFY
      for(int e=0;e<allEdges.size();e++)
      {
         PolyEdge *edge = allEdges[e];
         printf("Edge %p   %p -> %p  (%d)\n", edge, edge->node[0], edge->node[1], edge->windDelta);
         printf("     %f,%f -> %f,%f\n", edge->node[0]->x, edge->node[0]->y,
                                         edge->node[1]->x, edge->node[1]->y );
      }
      for(int n=0;n<allNodes.size();n++)
      {
         PolyNode *node = allNodes[n];
         printf("Node %p : %f, %f\n", node, node->x, node->y );
         for(int e=0; e<node->edgeCount; e++)
            printf("  %d] %p\n", e, node->edges[e]);
      }
      #endif
   }


   void calculateWindings()
   {
      //printGeom();

      for(int outer=0; outer<allEdges.size(); outer++)
      {
         PolyEdge *edgeO = allEdges[outer];
         #ifndef VERIFY
         if (edgeO->done)
            continue;
         #endif

         int winding = 0;
         PolyNode *no0 = edgeO->node[0];
         PolyNode *no1 = edgeO->node[1];
         UserPoint o0 = *no0;
         UserPoint o1 = *no1;
         UserPoint ray = (o0+o1)*0.5;

         //printf("Edge %p %f,%f -> %f,%f\n", edgeO, o0.x, o0.y, o1.x, o1.y);
         //printf(" ray %f,%f\n", ray.x, ray.y );
         for(int inner=0; inner<allEdges.size(); inner++)
         {
            if (inner==outer)
               continue;

            PolyEdge *edgeI = allEdges[inner];
            UserPoint i0 = *edgeI->node[0];
            if (i0 > ray)
               break;

            UserPoint i1 = *edgeI->node[1];
            if (i0<ray && !(i1<ray))
            {
               #ifdef VERIFY
               if (i0.y==i1.y)
               {
                  printf("BAD ray/point ordering\n");
                  printf(" i: %f,%f -> %f,%f\n", i0.x, i0.y, i1.x, i1.y);
                  printf(" o: %f,%f -> %f,%f\n", o0.x, o0.y, o1.x, o1.y);
                  printf(" ray: %f,%f\n", ray.x, ray.y );
               }
               #endif
               float x = i0.x + (i1.x-i0.x)*(ray.y-i0.y)/(i1.y-i0.y);
               if (x>ray.x)
               {
                  winding += edgeI->windDelta;
                  // printf("   %f : %d (%d)\n", x, edgeI->windDelta, winding);
               }
            }
         }
         // printf("right winding total = %d\n", winding );

         #ifdef VERIFY
         // Check consistency between tracing and ray-casting
         if (edgeO->done)
         {
            short right = winding;
            short left = winding + edgeO->windDelta;
            if (right!=edgeO->rightWind || left!=edgeO->leftWind)
            {
               printf("BAD TRACING\n");
               printf("Edge %p should be, r=%d l=%d, is %d,%d \n", edgeO, right, left,
                      edgeO->rightWind, edgeO->leftWind );
            }
            continue;
         }
         #endif

         edgeO->rightWind =  winding;
         edgeO->leftWind = winding + edgeO->windDelta;
         edgeO->done = true;

         edgeO->node[0]->done = true;
         nodeStack.push_back( edgeO->node[0] );
         propagateWinding();
      }
   }


   void setNodeEdges()
   {
      nodeEdges.resize(allEdges.size()*2);
      int nodeEdgePos = 0;

      for(int n=0;n<allNodes.size();n++)
      {
         PolyNode *node = allNodes[n];
         int count = node->edgeCount;
         node->edges = &nodeEdges[nodeEdgePos];
         node->edgeCount = 0;
         nodeEdgePos += count;
      }
      #ifdef VERIFY
      if (nodeEdgePos!=nodeEdges.size())
         printf("BAD EDGE COUNT\n");
      #endif

      for(int e=0;e<allEdges.size();e++)
      {
         PolyEdge *edge = allEdges[e];
         edge->node[0]->addEdge(edge);
         edge->node[1]->addEdge(edge);
      }
   }

   void sortEdges()
   {
      for(int n=0;n<allNodes.size();n++)
      {
         PolyNode *node = allNodes[n];
         // Check redundant wen count==2
         //  - except when the initial direction is needed, handled later
         if (node->edgeCount>2)
            sortNodeEdge(node);
      }
   }

   void sortNodeEdge(PolyNode *node)
   {
      // TODO - remove redundant edges
      int count = node->edgeCount;
      PolyEdge **edges = node->edges;
        edgeSortBuf.resize(count);
      for(int i=0;i<count;i++)
           edgeSortBuf[i].set(node,edges[i]);
      std::sort(  edgeSortBuf.begin(),   edgeSortBuf.end());
      for(int i=0;i<count;i++)
         edges[i] =   edgeSortBuf[i].edge;

      #ifdef VERIFY
      for(int i=1;i<count;i++)
      {
         double theta0 = getEdgeAngle( node, edges[i-1]);
         double theta1 = getEdgeAngle( node, edges[i]);
         if (theta1<theta0)
         {
            printf("BAD sort angle %f %f\n", theta0, theta1);
            getEdgeAngle( node, edges[i-1], true);
            getEdgeAngle( node, edges[i], true);
            printf("               %d %d\n", getEdgeOctant( node, edges[i-1]), getEdgeOctant( node, edges[i]) );
         }
      }
      #endif
   }

   void removeInteriorEdges()
   {
      for(int e=0;e<allEdges.size(); /* */ )
      {
         PolyEdge *edge = allEdges[e];
         if (edge->isInterior(oddEven))
         {
            edge->node[0]->removeEdge(edge);
            edge->node[1]->removeEdge(edge);
            // Destroys edge order...
            allEdges.qremoveAt(e);
         }
         else
            e++;
      }
   }

   void extractOutline(Vertices &outOutline,QuickVec<int> &outSubPolys)
   {
      //printf("Nodes %d\n", allNodes.size() );
      //printf("Edges %d\n", allEdges.size() );
      for(int i=0;i<allNodes.size();i++)
      {
         PolyNode *node = allNodes[i];
         if (node->edgeCount>0)
         {
            if (node->edgeCount==2)
               sortNodeEdge(node);

            // trace from 'node' in the direction of the first edge..
            PolyEdge *edge = node->edges[0];
            if (edge->node[0]!=node)
               printf("Bad node order?\n");

            PolyNode *start = allNodes[i];
            while(true)
            {
               //printf(" %f,%f\n", node->x, node->y);
               outOutline.push_back(*node);
               /*
                 Always go right, which means taking the previous(anti-clockwise) edge,

                       |
                  ---->+--
                       |
                       v

               */
               PolyNode *next = edge->otherNode(node);
               PolyEdge *nextEdge = next->previousEdge(edge);
               node->removeEdge(edge);
               next->removeEdge(edge);
               //if (node->edgeCount>1) break;
               node = next;
               edge = nextEdge;
               if (node==start || nextEdge==0)
                  break;
               #ifdef VERIFY
               if (node->Dist2(*start)<NME_FUSE_DIST2)
                  printf("TOO CLOSE\n");
               #endif
            }

            outSubPolys.push_back( outOutline.size() );
         }
      }
   }

};

void VerifyOutputline(UserPoint *points, int count)
{
   UserPoint prev = points[count-1];
   for(int i=0;i<count;i++)
   {
      UserPoint p = points[i];
      UserPoint dp = p-prev;
      for(int j=i+1;j<count;j++)
      {
         UserPoint t0 = points[j-1];
         UserPoint t1 = points[j];
         UserPoint dt = t1-t0;

         // intersect = prev + alpha dp = t0 + beta dt
         double denom = dp.Cross(dt);
         if (denom!=0)
         {
            double alpha = (t0-prev).Cross(dt)/denom;
            double beta  = (prev-t0).Cross(dt)/denom;
            if (alpha>0 && alpha<1 && beta>0 && beta<1)
            {
               printf("Crossing %f %f\n", alpha, beta);
            }
         }
      }
   }
}


void NmeClipOutline(Vertices &ioOutline,QuickVec<int> &ioSubPolys, WindingRule inWinding)
{
   NmeClip clip(ioOutline, ioSubPolys, inWinding==wrOddEven);

   ioOutline.resize(0);
   ioSubPolys.resize(0);
   #ifdef VERIFY
   clip.verifyNodes();
   #endif

   clip.extractOutline(ioOutline, ioSubPolys);

   #ifdef VERIFY
   int start = 0;
   for(int i=0;i<ioSubPolys.size();i++)
   {
      VerifyOutputline( &ioOutline[start], ioSubPolys[i]-start );
      start += ioSubPolys.size();
   }
   #endif
}


}
