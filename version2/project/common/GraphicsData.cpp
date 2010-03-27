#include <Graphics.h>

namespace nme
{

// --- GraphicsPath ------------------------------------------

void GraphicsPath::initPosition(const UserPoint &inPoint)
{
   commands.push_back(pcBeginAt);
   data.push_back(inPoint.x);
   data.push_back(inPoint.y);
}

void GraphicsPath::clear()
{
   commands.resize(0);
   data.resize(0);
}



void GraphicsPath::curveTo(float controlX, float controlY, float anchorX, float anchorY)
{
	commands.push_back(pcCurveTo);
	data.push_back(controlX);
	data.push_back(controlY);
	data.push_back(anchorX);
	data.push_back(anchorY);
}

void GraphicsPath::arcTo(float controlX, float controlY, float anchorX, float anchorY)
{
	commands.push_back(pcArcTo);
	data.push_back(controlX);
	data.push_back(controlY);
	data.push_back(anchorX);
	data.push_back(anchorY);
}


void GraphicsPath::lineTo(float x, float y)
{
	commands.push_back(pcLineTo);
	data.push_back(x);
	data.push_back(y);
}

void GraphicsPath::moveTo(float x, float y)
{
	commands.push_back(pcMoveTo);
	data.push_back(x);
	data.push_back(y);
}

void GraphicsPath::wideLineTo(float x, float y)
{
	commands.push_back(pcLineTo);
	data.push_back(x);
	data.push_back(y);
}

void GraphicsPath::wideMoveTo(float x, float y)
{
	commands.push_back(pcMoveTo);
	data.push_back(x);
	data.push_back(y);
}

void GraphicsPath::tile(float x, float y, const Rect &inTileRect)
{
	commands.push_back(pcTile);
	data.push_back(x);
	data.push_back(y);
	data.push_back(inTileRect.x);
	data.push_back(inTileRect.y);
	data.push_back(inTileRect.w);
	data.push_back(inTileRect.h);
}



} // end namespace nme

