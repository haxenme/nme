package nme.debug;


import haxe.Timer;
import nme.events.Event;
import nme.text.TextField;
import nme.text.TextFormat;
import nme.text.TextFieldAutoSize;


@:nativeProperty
class DisplayStats extends TextField
{
    public var currentFPS(get,never):Float;

    private static inline var m_updateTime:Float = 0.5; //sec
    private static inline var m_precisionDecimals:Int = 1;
    private static inline var m_smoothing:Float = 0.9; //lerp with previous fps
    private static inline var m_spikeRangeInFPS:Float = 1.0; //force update if spike
    private var m_timeToChange:Float;
    private var m_isNormalFormat:Bool;
    private var m_currentTime:Float;
    private var m_currentFPS:Float;
    private var m_oldFPS:Float;
    private var m_initFrameRate:Float;
    private var m_normalTextFormat:TextFormat;
    private var m_warnTextFormat:TextFormat;

    private var m_glVerts:Int;
    private var m_glCalls:Int;
    
    public function new(inX:Float = 10.0, inY:Float = 10.0, inCol:Int = 0x000000, inWarningCol:Int = 0xFF0000)
    {    
        super();
        
        x = inX;
        y = inY;
        selectable = false;
        mouseEnabled = false;
        
        m_normalTextFormat = new TextFormat("_sans", 12, inCol);
        m_warnTextFormat = new TextFormat("_sans", 12, inWarningCol);
        defaultTextFormat = m_normalTextFormat;
        m_isNormalFormat = true;
        m_initFrameRate = Lib.stage.frameRate; //nme.app.Application.initFrameRate;
        m_timeToChange = m_updateTime;
        
        text = "";
        autoSize = TextFieldAutoSize.LEFT;
        
        addEventListener(Event.ENTER_FRAME, onEnter);
    }
    

    function get_currentFPS() : Float
    {
      return m_currentFPS;
    }
    
    
    // Event Handlers
    private function onEnter(_)
    {
        if (visible)
        {
            var currentTime = haxe.Timer.stamp();
            var dt = (currentTime-m_currentTime);
            if(dt > 0.0)
            {
                m_currentFPS = 1.0 / dt;
                m_currentFPS = m_currentFPS * m_smoothing + m_oldFPS * (1.0-m_smoothing);
                if(m_precisionDecimals==0)
                {
                    m_currentFPS = Math.round( m_currentFPS );
                }
                else
                {
                    m_currentFPS = Math.round( m_currentFPS * Math.pow(10, m_precisionDecimals) ) / Math.pow(10, m_precisionDecimals);
                }
            }
            m_currentTime = currentTime;

            m_timeToChange-= dt;
            var spike:Bool = (m_currentFPS < m_oldFPS-m_spikeRangeInFPS);
            if (m_timeToChange < 0 || spike)
            {
                m_timeToChange = m_updateTime;

                if ( m_currentFPS != m_oldFPS )
                {
                    //change color if necessary
                    if ( m_currentFPS < m_initFrameRate && m_isNormalFormat )
                    {
                        m_isNormalFormat = false;
                        defaultTextFormat = m_warnTextFormat;
                    }
                    else if ( m_currentFPS >= m_initFrameRate && !m_isNormalFormat )
                    {
                        m_isNormalFormat = true;
                        defaultTextFormat = m_normalTextFormat;
                    }
                    var showDt = Math.round( dt * Math.pow(10, 3) ) / Math.pow(10, 3);

                    #if NME_DISPLAY_STATS
                    m_glVerts = getGLVerts();
                    m_glCalls = getGLCalls();
                    text = "GL verts: "+m_glVerts+
                           "\nGL calls: "+m_glCalls+"\n"+
                           m_currentFPS + (m_currentFPS==Math.floor(m_currentFPS)?".0  /  ":"  /  ") + showDt;
                    #else
                    text = "Use -DNME_DISPLAY_STATS -clean to show GL information\n"+
                           m_currentFPS + (m_currentFPS==Math.floor(m_currentFPS)?".0  /  ":"  /  ") + showDt;
                    #end
                }
                m_oldFPS = m_currentFPS;
            }
        }
    }

#if NME_DISPLAY_STATS
    public static dynamic function getGLVerts():Int 
    {
       return nme_displaystats_get_glverts();
    }

    public static dynamic function getGLCalls():Int 
    {
       return nme_displaystats_get_glcalls();
    }

   private static var nme_displaystats_get_glverts = Loader.load("nme_displaystats_get_glverts", 0);
   private static var nme_displaystats_get_glcalls = Loader.load("nme_displaystats_get_glcalls", 0);
#end
}
