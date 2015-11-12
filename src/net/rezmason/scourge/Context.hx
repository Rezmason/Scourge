package net.rezmason.scourge;

import lime.app.Application;

import net.rezmason.gl.GLFlowControl;
import net.rezmason.gl.GLSystem;
import net.rezmason.scourge.textview.core.Engine;
import net.rezmason.scourge.textview.core.FontManager;
import net.rezmason.scourge.textview.errands.BeginNavErrand;
import net.rezmason.utils.santa.Santa;

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
        glFlow.onConnect = null;
        Santa.mapToClass(GLSystem, Singleton(glSys));
        Santa.mapToClass(FontManager, Singleton(new FontManager(['full'])));

        var engine = new Engine(glFlow);
        Application.current.addModule(engine);

        new GameContext();
        
        var beginNavErrand = new BeginNavErrand(engine);
        if (engine.ready) beginNavErrand.run();
        else engine.readySignal.add(beginNavErrand.run);
    }
}
