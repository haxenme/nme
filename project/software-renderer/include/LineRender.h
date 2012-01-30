#ifndef LINE_RENDER_H
#define LINE_RENDER_H


#include "PolygonRender.h"


#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif


namespace nme
{

	class LineRender : public PolygonRender
	{
	public:
		
		typedef void (LineRender::*ItFunc)(const UserPoint &inP0, const UserPoint &inP1);
		ItFunc ItLine;
		double mDTheta;
		GraphicsStroke *mStroke;
		
		LineRender(const GraphicsJob &inJob, const GraphicsPath &inPath);
		void BuildExtent(const UserPoint &inP0, const UserPoint &inP1);
		void AddLinePart(UserPoint p0, UserPoint p1, UserPoint p2, UserPoint p3);
		void IterateCircle(const UserPoint &inP0, const UserPoint &inPerp, double inTheta,const UserPoint &inPerp2 );
		inline void AddJoint(const UserPoint &p0, const UserPoint &perp1, const UserPoint &perp2);
		inline void EndCap(UserPoint p0, UserPoint perp);
		double GetPerpLen(const Matrix &m);
		int Iterate(IterateMode inMode,const Matrix &m);
		void AlignOrthogonal();
		
	};
	
	
}


#endif
