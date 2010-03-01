#ifndef NME_TEXT_FIELD_H
#define NME_TEXT_FIELD_H

#include "Graphics.h"
#include "QuickVec.h"
#include "Font.h"
#include "Display.h"

class TiXmlNode;

namespace nme
{



class TextField : public DisplayObject
{
public:
   TextField(bool inInitRef=false);

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
   bool getSelectable() { return selectable; }
   void setSelectable(bool inSelectable) { selectable = inSelectable; }
   void setTextColor(int inColor);
   int  getTextColor() { return textColor; }
   bool getIsInput() { return isInput; }
   void setIsInput(bool inIsInput);
   AutoSizeMode getAutoSize() { return autoSize; }
   void  setAutoSize(int inAutoSize);

   int   getCaretIndex() { return caretIndex; }
   int   getMaxScrollH() { return maxScrollH; }
   int   getMaxScrollV() { return maxScrollV; }
   int   getBottomScrollV();
   int   getScrollH() { return scrollH; }
   void  setScrollH(int inScrollH);
   int   getScrollV() { return scrollV; }
   void  setScrollV(int inScrollV);
   int   getNumLines() { return mLines.size(); }
   int   getSelectionBeginIndex();
   int   getSelectionEndIndex();

   const TextFormat *getDefaultTextFormat();
   void setDefaultTextFormat(TextFormat *inFormat);

   bool  getBackground() const { return background; }
   void  setBackground(bool inBackground);
   int   getBackgroundColor() const { return backgroundColor; }
   void  setBackgroundColor(int inBackgroundColor);
   bool  getBorder() const { return border; }
   void  setBorder(bool inBorder);
   int   getBorderColor() const { return borderColor; }
   void  setBorderColor(int inBorderColor);
   bool  getMultiline() const { return multiline; }
   void  setMultiline(bool inMultiline);
   bool  getWordWrap() const { return wordWrap; }
   void  setWordWrap(bool inWordWrap);


   double getWidth();
   void setWidth(double inWidth);
   double getHeight();
   void setHeight(double inHeight);

   std::wstring getHTMLText();
   void setHTMLText(const std::wstring &inString);
   std::wstring getText();
   void setText(const std::wstring &inString);

   int   getLength();
   int   getTextHeight();
   int   getTextWidth();

   bool  alwaysShowSelection;
   AntiAliasType antiAliasType;
   AutoSizeMode autoSize;
   bool  background;
   int   backgroundColor;
   bool  border;
   int   borderColor;
   bool  condenseWhite;

   TextFormat *defaultTextFormat;
   bool  displayAsPassword;
   bool  embedFonts;
   GridFitType gridFitType;
   int  maxChars;
   bool mouseWheelEnabled;
   bool multiline;
   std::wstring restrict;
   bool selectable;
   float sharpness;
   struct StyleSheet *styleSheet;
   int textColor;
   float  thickness;
   bool useRichTextClipboard;
   bool  wordWrap;
   bool  isInput;

   int  scrollH;
   int  scrollV;
   int  maxScrollH;
   int  maxScrollV;
   int  caretIndex;

   void Render( const RenderTarget &inTarget, const RenderState &inState );

   // Display-object like properties
   Rect mRect;

   void GetExtent(const Transform &inTrans, Extent2DF &outExt,bool inForBitmap);
   Cursor GetCursor() { return selectable ? curTextSelect : curPointer; }
   bool WantsFocus() { return isInput && mouseEnabled; }
   void Focus();
   void Unfocus();
   bool CaptureDown(Event &inEvent);
   void Drag(Event &inEvent);
   void EndDrag(Event &inEvent);
   void OnKey(Event &inEvent);
   void DeleteSelection();
   void InsertString(const std::wstring &inString);



protected:
   ~TextField();

private:
   TextField(const TextField &);
   void operator=(const TextField &);
   void Layout();

   void Clear();
   void AddNode(const TiXmlNode *inNode, TextFormat *inFormat, int &ioCharCount,
      int inLineSkips, bool inBeginParagraph);
   void UpdateFonts(const Transform &inTransform);

   enum StringState { ssNone, ssText, ssHTML };
   StringState mStringState;
   std::wstring mUserString;

   int  PointToChar(int inX,int inY);
   int  LineFromChar(int inChar);
   int  GroupFromChar(int inChar);
   int  EndOfCharX(int inChar,int inLine);
   int  EndOfLineX(int inLine);

   bool mLinesDirty;
   bool mGfxDirty;
   bool mFontsDirty;
   double mLastUpdateScale;
   GlyphRotation mLastUpdateRotation;

   CharGroups mCharGroups;
   Lines mLines;
   QuickVec<ImagePoint> mCharPos;

   int mSelectMin;
   int mSelectMax;
   int mSelectDownChar;
};

} // end namespace nme


#endif
