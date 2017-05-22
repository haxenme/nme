package nme.debug;

import haxe.Timer;
import nme.events.Event;
import nme.text.TextField;
import nme.text.TextFormat;
import nme.text.TextFieldAutoSize;
import nme.app.Application;

#if cpp
import cpp.vm.Gc;
#else
import openfl.system.System;
#end

@:nativeProperty
class DisplayStats extends TextField
{
    public var currentFPS(get,never):Float;

    private static inline var m_updateTime:Float = 0.5; //sec
    private static inline var m_precisionDecimals:Int = 1;
    private static inline var m_smoothing:Float = 0.1; //lerp with previous
    private static inline var m_spikeRangeInSec:Float = 0.00166; //force update if spike
    private static inline var MB_CONVERSION:Float = 9.53674316e-5;
    private static inline var numVerboseLevels:Int = 3;
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
    private var m_statsArray:Array<Int>;
    private var m_oldStatsArray:Array<Int>;
    private var m_dirtyText:Bool;
    private var m_verboseLevel:Int;
    private var m_memCurrent:Float;
    #if cpp
    private var m_memReserved:Float;
    #end


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
        m_initFrameRate = Application.initFrameRate;
        m_timeToChange = m_updateTime;
        
        text = "";
        autoSize = TextFieldAutoSize.LEFT;

        m_currentTime = haxe.Timer.stamp();
        m_dt = 1.0/m_initFrameRate;
        m_fpsPrecisionDecimalsPow = Math.pow(10, m_precisionDecimals);
        
        m_statsArray = [0,0,0,0];
        m_oldStatsArray = [0,0,0,0];

        #if (NME_DISPLAY_STATS == 1)
        m_verboseLevel = 1;
        #elseif (NME_DISPLAY_STATS == 2)
        m_verboseLevel = 2;
        #end

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

            if(m_verboseLevel>0)
            {
                #if cpp
                m_memCurrent = Math.round( Gc.memInfo64( Gc.MEM_INFO_CURRENT ) * MB_CONVERSION)/100;
                m_memReserved = Math.round( Gc.memInfo64( Gc.MEM_INFO_RESERVED ) * MB_CONVERSION)/100;
                if (m_memReserved > m_memPeak)
                    m_memPeak = m_memReserved;
                #else
                m_memCurrent = Math.round(System.totalMemory * MB_CONVERSION)/100;
                if (m_memCurrent > m_memPeak)
                    m_memPeak = m_memCurrent;
                #end
            }

            m_timeToChange-= dt;
            if (m_timeToChange < 0 || spike)
            {
                m_timeToChange = m_updateTime;
                if ( showFPS != m_showFPS )
                {
                    m_dirtyText = true;
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

                nme_displaystats_get_glstats( m_statsArray );
                for (i in 0...4)
                {
                    if (m_statsArray[i] != m_oldStatsArray[i])
                    {
                        m_dirtyText = true;
                        m_oldStatsArray[i] = m_statsArray[i];
                    }
                }

                if(m_dirtyText)
                {
                    m_dirtyText = false;
                    var vertsTotal:Int = m_statsArray[0] + m_statsArray[2];
                    var callsTotal:Int = m_statsArray[1] + m_statsArray[3];

                    //GL stats
                    if(m_verboseLevel>1)
                    {
                        text = "GL verts: " + vertsTotal +
                           "\n    drawArrays: " + m_statsArray[0] +
                           "\n    drawElements: " + m_statsArray[2] +
                           "\nGL calls: " + callsTotal +
                           "\n    drawArrays: " + m_statsArray[1]+
                           "\n    drawElements: " + m_statsArray[3] + "\n" +
                           showFPS + (fps==Math.ffloor(showFPS)?".0  /  ":"  /  ") + m_showDt;
                    }
                    else
                    {
                        text = "GL verts: " + vertsTotal +
                           "\nGL calls: " + callsTotal + "\n" +
                           showFPS + (fps==Math.ffloor(showFPS)?".0  /  ":"  /  ") + m_showDt;
                    }

                    //Memory stats
                    if(m_verboseLevel>0)
                    {                        text += 
                           "\n\nMEM: " + m_memCurrent +
                           #if cpp
                           " MB\nMEM  reserved: " + m_memReserved + ",  peak: " +
                           #else
                           " MB\nMEM  peak: " +
                           #end
                           m_memPeak + " MB";
                    }

                }
                m_currentFPS = fps;
                m_showFPS = showFPS;
            }
        }
    }

    public function toggleVisibility()
    {
        visible = !visible;
        m_dirtyText = true;
    }

    public function changeVerboseLevel()
    {
        if(visible)
        {
            m_verboseLevel = (++m_verboseLevel)%numVerboseLevels;
            m_dirtyText = true;
        }
    }

   private static var nme_displaystats_get_glstats = nme.PrimeLoader.load("nme_displaystats_get_glstats", "ov");
}
