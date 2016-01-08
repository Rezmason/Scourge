package net.rezmason.hypertype.core;

import lime.app.Application;
import lime.app.Module;
import net.rezmason.gl.GLSystem;
import net.rezmason.gl.RenderTarget;
import net.rezmason.gl.RenderTargetTexture;
import net.rezmason.gl.Texture;
import net.rezmason.gl.ViewportRenderTarget;
import net.rezmason.hypertype.core.CombineRenderMethod;
import net.rezmason.hypertype.core.rendermethods.*;
import net.rezmason.utils.santa.Present;

#if hxtelemetry import hxtelemetry.HxTelemetry; #end

class Engine {

    var active:Bool;
    var glSys:GLSystem;
    var sceneGraph:SceneGraph;
    var mouseSystem:MouseSystem;
    var keyboardSystem:KeyboardSystem;
    var hitboxMethod:SceneRenderMethod;
    var sdfFontMethod:SceneRenderMethod;
    var limeRelay:LimeRelay;
    #if hxtelemetry var telemetry:HxTelemetry; #end

    var inputRenderTarget:RenderTarget;
    var debugDisplay:DebugDisplay;
    var textures:Map<String, Texture> = new Map();
    var inputTexture:RenderTargetTexture;
    var viewport:ViewportRenderTarget;
    var combineMethod:CombineRenderMethod;

    var hitboxPass:RenderPass;
    var sdfPass:RenderPass;
    var hitboxDebugPass:RenderPass;
    var presentedPass:RenderPass;

    public function new():Void {
        #if hxtelemetry telemetry = new Present(HxTelemetry); #end
        active = false;
        glSys = new Present(GLSystem);
        glSys.connect();
        
        sceneGraph = new Present(SceneGraph);
        sceneGraph.testDisconnectSignal.add(new SimulateContextLossErrand().run);
        sceneGraph.teaseHitboxesSignal.add(teaseHitboxes);
        
        mouseSystem = new MouseSystem();
        mouseSystem.interactSignal.add(sceneGraph.routeInteraction);
        sceneGraph.updateRectsSignal.add(mouseSystem.setRectRegions);

        keyboardSystem = new KeyboardSystem();
        keyboardSystem.interactSignal.add(sceneGraph.routeInteraction.bind(null, null));

        viewport = glSys.viewportRenderTarget;

        inputTexture = glSys.createRenderTargetTexture(FLOAT);
        inputRenderTarget = inputTexture.renderTarget;
        textures['input'] = inputTexture;
        
        debugDisplay = new Present(DebugDisplay);
        textures['debug'] = debugDisplay.texture;

        combineMethod = new CombineRenderMethod();
        sdfFontMethod = new SDFFontMethod();
        hitboxMethod = new HitboxMethod();
        
        hitboxPass = new RenderPass();
        mouseSystem.refreshSignal.add(hitboxPass.run);
        hitboxPass.addStep(SceneStep(hitboxMethod, sceneGraph, mouseSystem.renderTarget));

        hitboxDebugPass = new RenderPass();
        hitboxDebugPass.addStep(SceneStep(hitboxMethod, sceneGraph, viewport));

        sdfPass = new RenderPass();
        sdfPass.addStep(SceneStep(sdfFontMethod, sceneGraph, inputRenderTarget));
        sdfPass.addStep(ScreenStep(combineMethod, textures, viewport));
        presentedPass = sdfPass;

        limeRelay = new LimeRelay();
        Application.current.addModule(limeRelay);
        limeRelay.keyDownSignal.add(keyboardSystem.onKeyDown);
        limeRelay.keyUpSignal.add(keyboardSystem.onKeyUp);
        limeRelay.mouseMoveSignal.add(mouseSystem.onMouseMove);
        limeRelay.mouseDownSignal.add(mouseSystem.onMouseDown);
        limeRelay.mouseUpSignal.add(mouseSystem.onMouseUp);
        limeRelay.windowActivateSignal.add(activate);
        limeRelay.windowDeactivateSignal.add(deactivate);
        limeRelay.windowEnterSignal.add(activate);
        limeRelay.windowLeaveSignal.add(deactivate);
        limeRelay.windowResizeSignal.add(setSize);
        limeRelay.renderContextLostSignal.add(glSys.disconnect);
        limeRelay.renderContextRestoredSignal.add(glSys.connect);
        limeRelay.updateSignal.add(update);
        limeRelay.renderSignal.add(render);

        var window = Application.current.window;
        sceneGraph.setSize(window.width, window.height);
        activate();
    }

    public function update(delta) {
        if (!active) return;
        
        #if hxtelemetry
            var stack = telemetry.unwind_stack();
            telemetry.start_timing('.update');
        #end

        sceneGraph.update(delta);
        
        #if hxtelemetry
            telemetry.end_timing('.update');
            telemetry.rewind_stack(stack);
        #end
    }

    public function render() {
        if (!active) return;
            
        #if hxtelemetry
            var stack = telemetry.unwind_stack();
            telemetry.start_timing('.render');
        #end

        presentedPass.run();

        #if hxtelemetry
            telemetry.end_timing('.render');
            telemetry.rewind_stack(stack);
            telemetry.advance_frame();
        #end
    }

    function setSize(width:Int, height:Int):Void {
        sceneGraph.setSize(width, height);
        mouseSystem.setSize(width, height);
        inputTexture.resize(width, height);
        debugDisplay.resize(width, height);
        viewport.resize(width, height);
    }

    function activate():Void {
        if (active) return;
        active = true;
        setSize(sceneGraph.width, sceneGraph.height);
    }

    function deactivate():Void active = false;

    function teaseHitboxes(val) presentedPass = val ? hitboxDebugPass : sdfPass;
}
