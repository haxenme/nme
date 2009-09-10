#ifndef TEXT_FIELD_H
#define TEXT_FIELD_H

#include "Graphics.h"
#include "QuickVec.h"
#include "Font.h"

enum TextFieldType { tftDynamic, tftInput };


class TextField
{
public:
	TextField();
	~TextField();

	void appendText(std::wstring inString);
	Rect getCharBoundaries(int inCharIndex);
	int getCharIndexAtPoint(double x, double y);
	int getFirstCharInParagraph(int inCharIndex);
	int getLineIndexAtPoint(double x,double y);
	int getLineIndexOfChar(int inCharIndex);
	int getLineLength(int inLineIndex);
	const TextLineMetrics &getLineMetrics(int inLineIndex);
	int getLineOffset(int inLineIndex);
	std::wstring getLineText();
	int getParagraphLength(int inCharIndex);
	TextFormat *getTextFormat(int inFirstChar=-1, int inEndChar=-1);
	bool isFontCompatible(const std::wstring &inFont, const std::wstring &inStyle);
	void replaceSelectedText(const std::wstring &inText);
	void replaceText(int inBeginIndex, int inEndIndex, const std::wstring &inText);
	int  setSelection(int inFirst, int inLast);
	void setTextFormat(const TextFormat *inFormat,int inFirstChar=-1, int inLastChar = -1);



	std::wstring getHTMLText();
	void setHTMLText(const std::wstring &inString);
	std::wstring getText();
	void setText(const std::wstring &inString);

	int   getBottomScrollV();
	int   getCaretIndex();
	int   getLength();
	int   getMaxScrollH();
	int   getMaxScrollV();
	int   getNumLines();
	int   getSelectionBeginIndex();
	int   getSelectionEndIndex();
	int   getTextHeight();
	int   getTextWidth();

	bool  alwaysShowSelection;
	AntiAliasType antiAliasType;
	AutoSizeMode autoSize;
	bool  background;
	ARGB  backgroundColor;
	bool  border;
	ARGB  borderColor;
	bool  condenseWhite;

	TextFormat *defaultTextFormat;
	bool  displayAsPassword;
	GridFitType gridFitType;
	int  maxChars;
	bool mouseWheelEnabled;
	bool multiline;
	std::wstring restrict;
	int  scrollH;
	int  scrollV;
	bool selectable;
	float sharpness;
	struct StyleSheet *styleSheet;
	ARGB textColor;
	float  thickness;
	TextFieldType type;
	bool useRichTextClipboard;
	bool  wordWrap;

	bool Render( const RenderTarget &inTarget, const RenderState &inState );

	// Display-object like properties
   Rect mRect;

	// For drawing background...
	Graphics mGfx;
	

private:
	TextField(const TextField &);
	void operator=(const TextField &);
	void Layout();

	void Clear();
	void AddNode(const class TiXmlNode *inNode, TextFormat *inFormat, int &ioCharCount,int inLineSkips);

	enum StringState { ssNone, ssText, ssHTML };
	StringState mStringState;
	std::wstring mUserString;

	bool mLinesDirty;
	bool mGfxDirty;

	CharGroups mCharGroups;
	Lines mLines;
};

#endif
