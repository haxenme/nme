package mpeg.audio;

using Lambda;

class Utils {
    public static function calculateAudioLengthSamples(mpegAudio:MpegAudio) {
        return mpegAudio.frames
                .map(function(frame) { return lookupSamplesPerFrame(frame.header.version); })
                .fold(function(frameSampleCount, totalSampleCount) { return frameSampleCount + totalSampleCount; },
                        -mpegAudio.encoderDelay - mpegAudio.endPadding);
    }

    public static function lookupSamplesPerFrame(mpegVersion:MpegVersion) {
        return switch (mpegVersion) {
            case Version1: 1152;
            case Version2, Version25: 576;
        };
    }
}
