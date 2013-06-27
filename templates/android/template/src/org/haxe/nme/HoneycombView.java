package org.haxe.nme;

import android.app.Activity;
import android.content.Context;
import android.view.InputDevice;
import android.view.MotionEvent;

class HoneycombView extends MainView {

    public HoneycombView(Context context,Activity inActivity) {
        super(context, inActivity);
    }

    @Override
    public boolean onGenericMotionEvent(MotionEvent event) {
        if ((event.getSource() & InputDevice.SOURCE_CLASS_JOYSTICK) != 0
            && event.getAction() == MotionEvent.ACTION_MOVE)
        {
            final MainView me = this;
            final int deviceId = event.getDeviceId();
            final InputDevice device = event.getDevice();
            // only check axis values of interest
            int[] axisList = {
                MotionEvent.AXIS_X, MotionEvent.AXIS_Y, MotionEvent.AXIS_Z,
                MotionEvent.AXIS_RX, MotionEvent.AXIS_RY, MotionEvent.AXIS_RZ,
                MotionEvent.AXIS_HAT_X, MotionEvent.AXIS_HAT_Y,
                MotionEvent.AXIS_LTRIGGER, MotionEvent.AXIS_RTRIGGER
            };
            for (int i = 0; i < axisList.length; i++) {
                final int axis = axisList[i];
                final InputDevice.MotionRange range = device.getMotionRange(axis, event.getSource());
                if (range != null) {
                    final float flat = range.getFlat();
                    final float value = event.getAxisValue(axis);

                    if (Math.abs(value) > flat) {
                        queueEvent(new Runnable() {
                            // This method will be called on the rendering thread:
                            public void run() {
                                me.HandleResult(NME.onJoyMotion(deviceId,axis,value));
                            }});
                    } else {
                        queueEvent(new Runnable() {
                            // This method will be called on the rendering thread:
                            public void run() {
                                me.HandleResult(NME.onJoyMotion(deviceId,axis,0));
                            }});
                    }
                }
            }
            return true;
        }
        return super.onGenericMotionEvent(event);
    }
}