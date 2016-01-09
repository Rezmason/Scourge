package net.rezmason.hypertype.core;

#if hxtelemetry
    import hxtelemetry.HxTelemetry;
#end

class Telemetry {

    #if hxtelemetry
        static var telemetry:HxTelemetry;
    #end

    public static inline function init() {
        #if hxtelemetry
            var config = new Config();
            config.allocations = true;
            config.host = 'localhost';
            config.app_name = 'Scourge';
            config.activity_descriptors = [ 
                { name: '.update', description: "Updating", color: 0xFFC800},
                { name: '.render', description: "Rendering", color:0xFF0090}
            ];
            telemetry = new HxTelemetry(config);
        #end
    }

    public static inline function startTiming(label) {
        #if hxtelemetry
            var stack = telemetry.unwind_stack();
            telemetry.start_timing('.update');
            return stack;
        #else
            return null;
        #end
    }

    public static inline function stopTiming(label, stack) {
        #if hxtelemetry
            telemetry.end_timing('.update');
            telemetry.rewind_stack(stack);
        #end
    }

    public static inline function advanceFrame() {
        #if hxtelemetry
            telemetry.advance_frame();
        #end
    }
}
