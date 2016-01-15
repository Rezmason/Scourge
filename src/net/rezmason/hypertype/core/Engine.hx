package net.rezmason.hypertype.core;

import lime.app.Application;
import net.rezmason.gl.RenderTarget;
import net.rezmason.gl.RenderTargetTexture;
import net.rezmason.gl.Texture;
import net.rezmason.gl.ViewportRenderTarget;
import net.rezmason.hypertype.core.rendermethods.*;
import net.rezmason.utils.santa.Present;
import lime.math.Vector4;

class Engine {

    var active:Bool;
    var sceneGraph:SceneGraph;
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

    public function new():Void {
        active = false;
        
        sceneGraph = new Present(SceneGraph);
        sceneGraph.teaseHitboxesSignal.add(teaseHitboxes);
        
        mouseSystem = new MouseSystem();
        mouseSystem.interactSignal.add(sceneGraph.routeInteraction);
        sceneGraph.updateRectsSignal.add(mouseSystem.setRectRegions);

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
        bloomMethod = new BloomMethod(10);
        
        hitboxPass = new RenderPass();
        mouseSystem.refreshSignal.add(hitboxPass.run);
        hitboxPass.addStep(SceneStep(hitboxMethod, sceneGraph, mouseSystem.renderTarget));

        hitboxDebugPass = new RenderPass();
        hitboxDebugPass.addStep(SceneStep(hitboxMethod, sceneGraph, viewport));

        sdfPass = new RenderPass();
        sdfPass.addStep(SceneStep(sdfFontMethod, sceneGraph, sceneRTT.renderTarget));

        sdfPass.addStep(ScreenStep(bloomMethod, ['input' => sceneRTT], bloomRTT1.renderTarget, [new Vector4(0, 0.002, 0, 0)]));
        sdfPass.addStep(ScreenStep(bloomMethod, ['input' => bloomRTT1], bloomRTT2.renderTarget, [new Vector4(0.002, 0, 0, 0)]));
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
        var stack = Telemetry.startTiming('.update');
        if (active) sceneGraph.update(delta);
        Telemetry.stopTiming('.update', stack);
    }

    function render() {
        var stack = Telemetry.startTiming('.render');
        if (active) presentedPass.run();
        Telemetry.stopTiming('.render', stack);
        Telemetry.advanceFrame();
    }

    function setSize(width:Int, height:Int):Void {
        sceneGraph.setSize(width, height);
        mouseSystem.setSize(width, height);
        sceneRTT.resize(width, height);
        bloomRTT1.resize(width, height); // TODO: fractional size
        bloomRTT2.resize(width, height);
        debugDisplay.resize(width, height);
        viewport.resize(width, height);
    }

    function activate():Void active = true;
    function deactivate():Void active = false;
    function teaseHitboxes(val) presentedPass = val ? hitboxDebugPass : sdfPass;
}
