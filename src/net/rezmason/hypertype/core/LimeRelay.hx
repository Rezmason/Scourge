package net.rezmason.hypertype.core;

import lime.app.Application;
import lime.app.Module;
import net.rezmason.utils.Zig;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;

class LimeRelay extends Module {
    public var keyDownSignal(default, null):Zig<KeyCode->KeyModifier->Void> = new Zig();
    public var keyUpSignal(default, null):Zig<KeyCode->KeyModifier->Void> = new Zig();
    public var mouseMoveSignal(default, null):Zig<Float->Float->Void> = new Zig();
    public var mouseDownSignal(default, null):Zig<Float->Float->Int->Void> = new Zig();
    public var mouseUpSignal(default, null):Zig<Float->Float->Int->Void> = new Zig();
    public var windowActivateSignal(default, null):Zig<Void->Void> = new Zig();
    public var windowDeactivateSignal(default, null):Zig<Void->Void> = new Zig();
    public var windowEnterSignal(default, null):Zig<Void->Void> = new Zig();
    public var windowLeaveSignal(default, null):Zig<Void->Void> = new Zig();
    public var windowResizeSignal(default, null):Zig<Int->Int->Void> = new Zig();
    public var renderContextLostSignal(default, null):Zig<Void->Void> = new Zig();
    public var renderContextRestoredSignal(default, null):Zig<Void->Void> = new Zig();
    public var updateSignal(default, null):Zig<Float->Void> = new Zig();
    public var renderSignal(default, null):Zig<Void->Void> = new Zig();

    override public function onKeyDown(_, keyCode, modifier) keyDownSignal.dispatch(keyCode, modifier);
    override public function onKeyUp(_, keyCode, modifier) keyUpSignal.dispatch(keyCode, modifier);
    override public function onMouseMove(_, x, y) mouseMoveSignal.dispatch(x, y);
    override public function onMouseDown(_, x, y, button) mouseDownSignal.dispatch(x, y, button);
    override public function onMouseUp(_, x, y, button) mouseUpSignal.dispatch(x, y, button);
    override public function onWindowActivate(_) windowActivateSignal.dispatch();
    override public function onWindowDeactivate(_) windowDeactivateSignal.dispatch();
    override public function onWindowEnter(_) windowEnterSignal.dispatch();
    override public function onWindowLeave(_) windowLeaveSignal.dispatch();
    override public function onWindowResize(_, width, height) windowResizeSignal.dispatch(width, height);
    override public function onRenderContextLost(_) renderContextLostSignal.dispatch();
    override public function onRenderContextRestored(_, _) renderContextRestoredSignal.dispatch();
    override public function update(milliseconds) updateSignal.dispatch(milliseconds / 1000);
    override public function render(_) renderSignal.dispatch();
    // override public function onTextInput(text) {}
}
