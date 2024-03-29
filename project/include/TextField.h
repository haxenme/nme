#ifndef NME_TEXT_FIELD_H
#define NME_TEXT_FIELD_H

#include "Utils.h"
#include "Graphics.h"
#include <nme/QuickVec.h>
#include "Font.h"
#include "Display.h"

class TiXmlNode;

namespace nme
{

class TextField : public DisplayObject
{
private:
   AntiAliasType antiAliasType;
   AutoSizeMode  autoSize;
   bool        background;
   int         backgroundColor;
   bool        border;
   int         borderColor;

   TextFormat  *defaultTextFormat;
   bool        displayAsPassword;
   bool        embedFonts;
   GridFitType gridFitType;
   int         maxChars;
   bool        mouseWheelEnabled;
   bool        condenseWhite;
   bool        multiline;
   //WString   restrict;

   bool        selectable;
   float       sharpness;
   int         textColor;
   float       thickness;
   float       lineSpaceScale;
   bool        useRichTextClipboard;
   bool        wordWrap;
   bool        isInput;

   int         mSelectMin;
   int         mSelectMax;
   bool        alwaysShowSelection;
   int         scrollH;
   int         scrollV;
   int         maxScrollH;
   int         maxScrollV;
   int         caretIndex;

    // Local coordinates
   double      explicitWidth;
   double      textWidth;
   double      textHeight;


   CharGroups  mCharGroups;


   // Render state
   bool          screenGrid;
   AntiAliasType fontAaType;
   double        fontScale;
   double        fontToLocal;
   double        fieldWidth;
   double        fieldHeight;

   bool        mLinesDirty;
   bool        mGfxDirty;
   bool        mFontsDirty;
   bool        mTilesDirty;
   bool        mCaretDirty;
   bool        mHasCaret;
   double      mBlink0;

   Lines       mLines;
   Graphics    *mCaretGfx;
   Graphics    *mHighlightGfx;
   Graphics    *mTiles;
   int         mLastCaretHeight;
   int         mLastUpDownX;
   UserPoint   mLastSubpixelOffset;

   int         mSelectDownChar;
   int         mSelectKeyDown;

   QuickVec<UserPoint> mCharPos;


public:
   TextField(bool inInitRef=false);

   bool IsInteractive() const { return true; }
   NmeObjectType getObjectType() { return notTextField; }

   void appendText(WString inString);
   Rect getCharBoundaries(int inCharIndex);
   int getCharIndexAtPoint(double x, double y);
   int getFirstCharInParagraph(int inCharIndex);
   int getLineIndexAtPoint(double x,double y);
   int getLineIndexOfChar(int inCharIndex);
   int getLineLength(int inLineIndex);
   void getLinePositions(int inLineId0, double *outResult, int inCount);
   WString getLineText();
   int getParagraphLength(int inCharIndex);
   TextFormat *getTextFormat(int inFirstChar=-1, int inEndChar=-1);
   bool isFontCompatible(const WString &inFont, const WString &inStyle);
   void replaceSelectedText(const WString &inText);
   void replaceText(int inBeginIndex, int inEndIndex, const WString &inText);
   void setSelection(int inFirst, int inLast);
   void setTextFormat(TextFormat *inFormat,int inFirstChar=-1, int inLastChar = -1);
   bool getSelectable() { return selectable; }
   void setSelectable(bool inSelectable) { selectable = inSelectable; }
   void setTextColor(int inColor);
   int  getTextColor() { return textColor; }
   bool isLineVisible(int inLine) const;
   bool getIsInput() { return isInput; }
   void setIsInput(bool inIsInput);
   AutoSizeMode getAutoSize() { return autoSize; }
   void  setAutoSize(int inAutoSize);
   void modifyLocalMatrix(Matrix &ioMatrix);
   void setAntiAliasType(int inVal);
   int getAntiAliasType() const { return (int)antiAliasType; }
   void setLineSpaceScale(double inVal);
   inline float getLineSpaceScale() const { return lineSpaceScale; }


   int   getCaretIndex() { return caretIndex; }
   int   getMaxScrollH() { Layout(); return maxScrollH; }
   int   getMaxScrollV() { Layout(); return maxScrollV; }
   int   getBottomScrollV();
   int   getScrollH() { return scrollH; }
   void  setScrollH(int inScrollH);
   int   getScrollV() { return scrollV; }
   void  setScrollV(int inScrollV);
   void  setScrollVClearSel(int inScrollV,bool inClearSel);
   int   getNumLines() { Layout(); return mLines.size(); }
   int   getSelectionBeginIndex();
   int   getSelectionEndIndex();
   int   getLineFromChar(int inChar) const;

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
   int   getMaxChars() const { return maxChars; }
   void  setMaxChars(int inMaxChars) { maxChars = inMaxChars; }
   bool  getDisplayAsPassword() const { return displayAsPassword; }
   void  setDisplayAsPassword(bool inValue) { displayAsPassword = inValue; }
   bool  getEmbedFonts() const { return embedFonts; }
   void  setEmbedFonts(bool inValue) { embedFonts = inValue; }
   bool  getMouseWheelEnabled() { return mouseWheelEnabled; }

   int   getLineOffset(int inLine);
   WString getLineText(int inLine);
   void  toScreenGrid(UserPoint &ioPoint,const Matrix &inMatrix);
   void  highlightRect(double x0, double y1, double w, double h);
   TextLineMetrics *getLineMetrics(int inLine);

   double getWidth();
   void setWidth(double inWidth);
   double getHeight();
   void setHeight(double inHeight);

   WString getHTMLText();
   void setHTMLText(const WString &inString);
   WString getText();
   void setText(const WString &inString);

   int   getLength() const;
   double   getTextHeight();
   double   getTextWidth();


   void Render( const RenderTarget &inTarget, const RenderState &inState );

   void GetExtent(const Transform &inTrans, Extent2DF &outExt,bool inForBitmap,bool inIncludeStroke);
   Cursor GetCursor();
   bool WantsFocus() { return isInput && mouseEnabled; }
   bool CaptureDown(Event &inEvent);
   void Drag(Event &inEvent);
   void EndDrag(Event &inEvent);
   void OnKey(Event &inEvent);
   void OnScrollWheel(int inDirection);
   void onTextUpdate(const std::string &inText, int inPos0, int inPos1);
   void onTextSelect(int inPos0, int inPos1);
   void DeleteSelection();
   void ClearSelection();
   void CopySelection();
   void PasteSelection();
   void DeleteChars(int inFirst,int inEnd);
   void InsertString(const WString &ioString);
   void SetSelectionInternal(int inFirst, int inLast);
   void ShowCaret(bool inFromDrag=false);
   bool FinishEditOnEnter();
   void AddCharacter(int inCharCode);

   bool CaretOn();
   bool IsCacheDirty();
   void SyncSelection();
   void Focus();
   void setCaretIndex(int inIndex);


   void decodeStream(ObjectStreamIn &inStream);
   void encodeStream(ObjectStreamOut &inStream);

protected:
   ~TextField();

private:
   TextField(const TextField &);
   void operator=(const TextField &);
   void Layout(const Matrix &inMatrix, const RenderTarget *inTarget);
   void Layout() { Layout(GetFullMatrix(true), nullptr); }

   void Clear();
   void AddNode(const TiXmlNode *inNode, TextFormat *inFormat, int &ioCharCount);

   enum StringState { ssNone, ssText, ssHTML };
   StringState mStringState;
   WString mUserString;

   void SplitGroup(int inGroup,int inPos);

   void BuildBackground();

   int  PointToChar(UserPoint inPoint) const;
   int  GroupFromChar(int inChar) const;
   double  EndOfCharX(int inChar,int inLine) const;
   double  EndOfLineX(int inLine) const;
   UserPoint GetScrollPos() const;
   UserPoint GetCursorPos() const;

   void OnChange();

};

} // end namespace nme


#endif
