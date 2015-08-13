package net.rezmason.scourge;

import lime.app.Application;

import net.rezmason.scourge.GameContext;
import net.rezmason.scourge.textview.NavSystem;
import net.rezmason.scourge.textview.ScourgeNavPageAddresses;
import net.rezmason.scourge.textview.core.Engine;
import net.rezmason.scourge.textview.core.FontManager;
import net.rezmason.scourge.textview.pages.*;
import net.rezmason.gl.*;
import net.rezmason.utils.santa.Santa;

class Context {

    var shim:Shim;
    var engine:Engine;
    var glSys:GLSystem;
    var glFlow:GLFlowControl;

    public function new():Void {
        shim = new Shim();
        Application.current.addModule(shim);
        glSys = new GLSystem();
        glFlow = glSys.getFlowControl();
        glFlow.onConnect = onGLConnect;
        glFlow.connect();
    }

    function onGLConnect():Void {
        glFlow.onConnect = null;
        Santa.mapToClass(GLSystem, Singleton(glSys));
        Santa.mapToClass(Shim, Singleton(shim));
        Santa.mapToClass(FontManager, Singleton(new FontManager(['full'])));

        makeEngine();
        new GameContext();
        makeNavSystem();
    }

    function makeEngine():Void {
        engine = new Engine(glFlow);
        engine.readySignal.add(addListeners);
        engine.init();
    }

    function addListeners():Void {
        shim.activateSignal.add(engine.activate);
        shim.deactivateSignal.add(engine.deactivate);
        shim.resizeSignal.add(engine.setSize);

        #if flash flash.Lib.current.stage.dispatchEvent(new flash.events.Event('resize')); #end
        var window = Application.current.window;
        engine.setSize(window.width, window.height);
        engine.activate();
    }

    function makeNavSystem():Void {
        var navSystem:NavSystem = new NavSystem(engine);
        navSystem.addPage(ScourgeNavPageAddresses.SPLASH, new SplashPage());
        navSystem.addPage(ScourgeNavPageAddresses.ABOUT, new AboutPage());
        navSystem.addPage(ScourgeNavPageAddresses.GAME, new GamePage());

        navSystem.goto(Page(ScourgeNavPageAddresses.SPLASH));
    }
}
