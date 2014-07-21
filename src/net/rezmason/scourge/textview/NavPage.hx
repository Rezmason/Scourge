package net.rezmason.scourge.textview;

import net.rezmason.scourge.textview.core.Body;
import net.rezmason.utils.Zig;

class NavPage {

    public var bodies(default, null):Array<Body>;
    public var navToSignal(default, null):Zig<NavAddress->Void>;
    public var updateViewSignal(default, null):Zig<Void->Void>;

    public function new():Void {
        bodies = [];
        navToSignal = new Zig();
        updateViewSignal = new Zig();
    }
}
