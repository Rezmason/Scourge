package net.rezmason.scourge;

import net.rezmason.scourge.errands.BeginNavErrand;
import net.rezmason.hypertype.HypertypeContext;
import net.rezmason.utils.santa.Santa;

#if debug_graphics import net.rezmason.hypertype.core.DebugGraphics; #end
#if hxtelemetry  import hxtelemetry.HxTelemetry; #end

class Context {
    public function new():Void {
        
        #if hxtelemetry
            var config = new Config();
            config.allocations = true;
            config.host = 'localhost';
            config.app_name = 'Scourge';
            config.activity_descriptors = [ 
                { name: '.update', description: "Updating", color: 0xFFC800},
                { name: '.render', description: "Rendering", color:0xFF0090}
            ];
            var telemetry = new HxTelemetry(config);
            Santa.mapToClass(HxTelemetry, Singleton(telemetry));
        #end

        var engineContext = new HypertypeContext();
        
        new GameContext();
        
        var engine = engineContext.engine;
        var beginNavErrand = new BeginNavErrand(engine);
        beginNavErrand.run();
    }
}
