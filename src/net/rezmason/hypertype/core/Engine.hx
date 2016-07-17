package net.rezmason.hypertype.core;

import lime.app.Application;
import net.rezmason.gl.RenderTarget;
import net.rezmason.gl.RenderTargetTexture;
import net.rezmason.gl.Texture;
import net.rezmason.gl.ViewportRenderTarget;
import net.rezmason.hypertype.core.rendermethods.*;
import net.rezmason.utils.santa.Present;

class Engine {

    var active:Bool;
    var sceneGraph:SceneGraph;
    var systemCalls:SystemCalls;
    var mouseSystem:MouseSystem;
    var keyboardSystem:KeyboardSystem;
    var hitboxMethod:SceneRenderMethod;
    var sdfFontMethod:SceneRenderMethod;
    var limeRelay:LimeRelay;
    
    var debugDisplay:DebugDisplay;
    var sceneRTT:RenderTargetTexture;
    var bloomRTT1:RenderTargetTexture;
    var bloomRTT2:RenderTargetTexture;

    var viewport:ViewportRenderTarget;
    var combineMethod:CombineMethod;
    var bloomMethod:BloomMethod;

    var hitboxPass:RenderPass;
    var sdfPass:RenderPass;
    var hitboxDebugPass:RenderPass;
    var presentedPass:RenderPass;

    inline static var BLOOM_DOWNSCALE = #if js 8 #else 4 #end ;

    public function new():Void {
        active = false;

        systemCalls = new Present(SystemCalls);
        systemCalls.resizeWindowSignal.add(resizeWindow);
        
        sceneGraph = new Present(SceneGraph);
        sceneGraph.teaseHitboxesSignal.add(teaseHitboxes);
        
        mouseSystem = new MouseSystem();
        mouseSystem.interactSignal.add(sceneGraph.routeInteraction);
        sceneGraph.invalidateHitboxesSignal.add(mouseSystem.invalidate);

        keyboardSystem = new KeyboardSystem();
        keyboardSystem.interactSignal.add(sceneGraph.routeInteraction.bind(null, null));

        viewport = new ViewportRenderTarget();
        sceneRTT = new RenderTargetTexture(FLOAT);
        bloomRTT1 = new RenderTargetTexture(FLOAT);
        bloomRTT2 = new RenderTargetTexture(FLOAT);
        debugDisplay = new Present(DebugDisplay);
        
        combineMethod = new CombineMethod();
        sdfFontMethod = new SDFFontMethod();
        hitboxMethod = new HitboxMethod();
        bloomMethod = new BloomMethod(5);
        
        hitboxPass = new RenderPass();
        mouseSystem.refreshSignal.add(hitboxPass.run);
        hitboxPass.addStep(SceneGraphStep(hitboxMethod, sceneGraph, mouseSystem.renderTarget));

        hitboxDebugPass = new RenderPass();
        hitboxDebugPass.addStep(SceneGraphStep(hitboxMethod, sceneGraph, viewport));

        sdfPass = new RenderPass();
        sdfPass.addStep(SceneGraphStep(sdfFontMethod, sceneGraph, sceneRTT.renderTarget));
        sdfPass.addStep(ScreenStep(bloomMethod, ['input' => sceneRTT], bloomRTT1.renderTarget, [0, 0.002]));
        sdfPass.addStep(ScreenStep(bloomMethod, ['input' => bloomRTT1], bloomRTT2.renderTarget, [0.002, 0]));
        sdfPass.addStep(ScreenStep(combineMethod, ['input' => sceneRTT, 'bloom' => bloomRTT2, 'debug' => debugDisplay.texture], viewport));
        presentedPass = sdfPass;

        limeRelay = new LimeRelay();
        limeRelay.keyDownSignal.add(keyboardSystem.receiveKeyDown);
        limeRelay.keyUpSignal.add(keyboardSystem.receiveKeyUp);
        limeRelay.mouseMoveSignal.add(mouseSystem.receiveMouseMove);
        limeRelay.mouseDownSignal.add(mouseSystem.receiveMouseDown);
        limeRelay.mouseUpSignal.add(mouseSystem.receiveMouseUp);
        limeRelay.windowActivateSignal.add(activate);
        limeRelay.windowDeactivateSignal.add(deactivate);
        limeRelay.windowEnterSignal.add(activate);
        limeRelay.windowLeaveSignal.add(deactivate);
        limeRelay.windowResizeSignal.add(setSize);
        limeRelay.updateSignal.add(update);
        limeRelay.renderSignal.add(render);
        limeRelay.start();
    }

    function update(delta) {
        Telemetry.changeName('.update');
        if (active) sceneGraph.update(delta);
        Telemetry.changeName('.lime');
    }

    function render() {
        Telemetry.changeName('.render');
        #if debug_graphics if (active) debugDisplay.refresh(); #end
        if (active) presentedPass.run();
        Telemetry.changeName('.lime');
        Telemetry.advanceFrame();
    }

    function setSize(width:Int, height:Int):Void {
        sceneGraph.setSize(width, height, 72);
        mouseSystem.setSize(width, height);
        sceneRTT.resize(width, height);
        bloomRTT1.resize(Std.int(width / BLOOM_DOWNSCALE), Std.int(height / BLOOM_DOWNSCALE));
        bloomRTT2.resize(Std.int(width / BLOOM_DOWNSCALE), Std.int(height / BLOOM_DOWNSCALE));
        debugDisplay.resize(width, height);
        viewport.resize(width, height);
    }

    function resizeWindow(pixelWidth:UInt, pixelHeight:UInt) limeRelay.resizeWindow(pixelWidth, pixelHeight);
    function activate():Void active = true;
    function deactivate():Void active = false;
    function teaseHitboxes(val) presentedPass = val ? hitboxDebugPass : sdfPass;
}
