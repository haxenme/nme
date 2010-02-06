#include <Graphics.h>

namespace nme
{

// --- GraphicsPath ------------------------------------------

void GraphicsPath::curveTo(float controlX, float controlY, float anchorX, float anchorY)
{
	command.push_back(pcCurveTo);
	data.push_back(controlX);
	data.push_back(controlY);
	data.push_back(anchorX);
	data.push_back(anchorY);
}

void GraphicsPath::arcTo(float controlX, float controlY, float anchorX, float anchorY)
{
	command.push_back(pcArcTo);
	data.push_back(controlX);
	data.push_back(controlY);
	data.push_back(anchorX);
	data.push_back(anchorY);
}


void GraphicsPath::lineTo(float x, float y)
{
	command.push_back(pcLineTo);
	data.push_back(x);
	data.push_back(y);
}

void GraphicsPath::moveTo(float x, float y)
{
	command.push_back(pcMoveTo);
	data.push_back(x);
	data.push_back(y);
}

void GraphicsPath::wideLineTo(float x, float y)
{
	command.push_back(pcWideLineTo);
	data.push_back(x);
	data.push_back(y);
	data.push_back(x);
	data.push_back(y);
}

void GraphicsPath::wideMoveTo(float x, float y)
{
	command.push_back(pcWideMoveTo);
	data.push_back(x);
	data.push_back(y);
	data.push_back(x);
	data.push_back(y);
}

} // end namespace nme

