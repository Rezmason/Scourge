package net.rezmason.hypertype.core;

#if hxtelemetry
    import hxtelemetry.HxTelemetry;
#end

class Telemetry {

    #if hxtelemetry
        static var telemetry:HxTelemetry;
    #end

    static var currentStack:String;
    static var currentName:String;

    public static inline function init() {
        #if hxtelemetry
            var config = new Config();
            config.allocations = true;
            config.host = 'localhost';
            config.app_name = 'Scourge';
            config.activity_descriptors = [ 
                { name: '.update', description: "Updating", color: 0xFFC800},
                { name: '.render', description: "Rendering", color:0xFF0090},
                { name: '.lime', description: "Lime", color:0x30FF00},
                { name: '.init', description: "Initializing", color:0x00C0FF},
            ];
            telemetry = new HxTelemetry(config);
        #end
    }

    public inline static function changeName(name) {
        #if hxtelemetry
        if (currentName != null) {
            telemetry.end_timing(currentName);
            telemetry.rewind_stack(currentStack);
        }
        currentName = name;
        currentStack = telemetry.unwind_stack();
        telemetry.start_timing(currentName);
        #end
    }

    public static inline function advanceFrame() {
        #if hxtelemetry
            telemetry.advance_frame();
        #end
    }
}
