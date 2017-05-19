package nme.debug;

import haxe.Timer;
import nme.events.Event;
import nme.text.TextField;
import nme.text.TextFormat;
import nme.text.TextFieldAutoSize;
import openfl.system.System;

@:nativeProperty
class DisplayStats extends TextField
{
    public var currentFPS(get,never):Float;

    private static inline var m_updateTime:Float = 0.5; //sec
    private static inline var m_precisionDecimals:Int = 1;
    private static inline var m_smoothing:Float = 0.1; //lerp with previous
    private static inline var m_spikeRangeInSec:Float = 0.00166; //force update if spike
    private static inline var MB_CONVERSION:Float = 9.53674316e-5;
    private var m_timeToChange:Float;
    private var m_isNormalFormat:Bool;
    private var m_currentTime:Float;
    private var m_currentFPS:Float;
    private var m_showFPS:Float;
    private var m_initFrameRate:Float;
    private var m_normalTextFormat:TextFormat;
    private var m_warnTextFormat:TextFormat;
    private var m_showDt:Float;
    private var m_glVerts:Int;
    private var m_glCalls:Int;
    private var m_dt:Float;
    private var m_fpsPrecisionDecimalsPow:Float;
    private var m_memPeak:Float;
    
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
        m_initFrameRate = Lib.stage.frameRate;
        m_timeToChange = m_updateTime;
        
        text = "";
        autoSize = TextFieldAutoSize.LEFT;

        m_currentTime = haxe.Timer.stamp();
        m_dt = 1.0/m_initFrameRate;
        m_fpsPrecisionDecimalsPow = Math.pow(10, m_precisionDecimals);
        
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
            var dt:Float = (currentTime-m_currentTime);
            var spike:Bool = false;
            if(dt>0.1)
            {
                //reinitialize if dt is too big
                dt = 1.0/m_initFrameRate;
            }
            else
            {
                spike = (dt < m_dt-m_spikeRangeInSec);
                if(spike)
                {
                    dt = dt*(1.0-m_smoothing)+m_dt * m_smoothing; 
                }
                else
                {
                    dt = dt*m_smoothing+m_dt * (1.0-m_smoothing); 
                }
            }
            m_dt = dt;
            m_currentTime = currentTime;
            var fps:Float = 1.0 / dt;
            var showFPS:Float;
            if(m_precisionDecimals==0)
            {
                showFPS = Math.round( fps );
            }
            else
            {
                showFPS = Math.round(fps *  m_fpsPrecisionDecimalsPow) / m_fpsPrecisionDecimalsPow;
            }

            #if cpp
            var mem:Float = Math.round( 
                ( cpp.vm.Gc.memInfo64( cpp.vm.Gc.MEM_INFO_RESERVED ) +
                  cpp.vm.Gc.memInfo64( cpp.vm.Gc.MEM_INFO_CURRENT ) ) * MB_CONVERSION)/100;
            #else
            var mem:Float = Math.round(System.totalMemory * MB_CONVERSION)/100;
            #end

            if (mem > m_memPeak)
            {
                m_memPeak = mem;
            }

            m_timeToChange-= dt;
            if (m_timeToChange < 0 || spike)
            {
                m_timeToChange = m_updateTime;
                var dirtyText:Bool = false;
                if ( showFPS != m_showFPS )
                {
                    dirtyText = true;
                    //change color if necessary
                    if ( showFPS < m_initFrameRate && m_isNormalFormat )
                    {
                        m_isNormalFormat = false;
                        defaultTextFormat = m_warnTextFormat;
                    }
                    else if ( showFPS >= m_initFrameRate && !m_isNormalFormat )
                    {
                        m_isNormalFormat = true;
                        defaultTextFormat = m_normalTextFormat;
                    }
                    m_showDt = Math.round( dt * Math.pow(10, 3) ) / Math.pow(10, 3);
                }
                var glVerts = getGLVerts();
                var glCalls = getGLCalls();
                if (m_glVerts!=glVerts)
                {
                    dirtyText = true;
                    m_glVerts = glVerts;
                }
                if (m_glCalls!=glCalls)
                {
                    dirtyText = true;
                    m_glCalls = glCalls;
                }
                if(dirtyText)
                {
                    text = "GL verts: "+m_glVerts+
                       "\nGL calls: "+m_glCalls+"\n"+
                       showFPS + (fps==Math.floor(showFPS)?".0  /  ":"  /  ") + m_showDt +
                       "\nMEM: " + mem + " MB\nMEM peak: " + m_memPeak + " MB";
                }
                m_currentFPS = fps;
                m_showFPS = showFPS;
            }
        }
    }

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
}
