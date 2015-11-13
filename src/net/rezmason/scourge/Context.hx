package net.rezmason.scourge;

import lime.app.Application;

import net.rezmason.gl.GLFlowControl;
import net.rezmason.gl.GLSystem;
import net.rezmason.scourge.textview.core.Engine;
import net.rezmason.scourge.textview.core.FontManager;
import net.rezmason.scourge.textview.errands.BeginNavErrand;
import net.rezmason.utils.santa.Santa;
#if debug_graphics import net.rezmason.scourge.textview.core.DebugGraphics; #end
#if hxtelemetry  import hxtelemetry.HxTelemetry; #end
class Context {

    var glSys:GLSystem;
    var glFlow:GLFlowControl;

    public function new():Void {
        glSys = new GLSystem();
        glFlow = glSys.getFlowControl();
        glFlow.onConnect = onGLConnect;
        glFlow.connect();
    }

    function onGLConnect():Void {
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

        glFlow.onConnect = null;
        Santa.mapToClass(GLSystem, Singleton(glSys));
        Santa.mapToClass(FontManager, Singleton(new FontManager(['full'])));

        var engine = new Engine(glFlow);
        Application.current.addModule(engine);
        #if debug_graphics Santa.mapToClass(DebugGraphics, Singleton(engine.debugGraphics)); #end
        
        new GameContext();
        
        var beginNavErrand = new BeginNavErrand(engine);
        if (engine.ready) beginNavErrand.run();
        else engine.readySignal.add(beginNavErrand.run);
    }
}
