package net.rezmason.scourge;

import lime.app.Module;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;

import net.rezmason.utils.Zig;

class Shim extends Module {
    public var activateSignal(default, null):Zig<Void->Void> = new Zig();
    public var deactivateSignal(default, null):Zig<Void->Void> = new Zig();
    public var resizeSignal(default, null):Zig<UInt->UInt->Void> = new Zig();
    public var keyDownSignal(default, null):Zig<KeyCode->KeyModifier->Void> = new Zig();
    public var keyUpSignal(default, null):Zig<KeyCode->KeyModifier->Void> = new Zig();
    public var mouseMoveSignal(default, null):Zig<Float->Float->Void> = new Zig();
    public var mouseDownSignal(default, null):Zig<Float->Float->Int->Void> = new Zig();
    public var mouseUpSignal(default, null):Zig<Float->Float->Int->Void> = new Zig();

    override public function onKeyDown(keyCode, modifier) keyDownSignal.dispatch(keyCode, modifier);
    override public function onKeyUp(keyCode, modifier) keyUpSignal.dispatch(keyCode, modifier);

    override public function onMouseMove(x, y) mouseMoveSignal.dispatch(x, y);
    override public function onMouseDown(x, y, button) mouseDownSignal.dispatch(x, y, button);
    override public function onMouseUp(x, y, button) mouseUpSignal.dispatch(x, y, button);

    override public function onWindowActivate() activateSignal.dispatch();
    override public function onWindowDeactivate() deactivateSignal.dispatch();
    override public function onWindowEnter() activateSignal.dispatch();
    override public function onWindowLeave() deactivateSignal.dispatch();
    override public function onWindowResize (width, height) resizeSignal.dispatch(width, height);

    // override public function onRenderContextLost() {}
    // override public function onRenderContextRestored(_) {}
    // override public function onTextInput(text) {}
}
