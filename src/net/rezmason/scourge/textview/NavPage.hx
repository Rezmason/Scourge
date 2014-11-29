package net.rezmason.scourge.textview;

import net.rezmason.scourge.textview.core.Scene;
import net.rezmason.utils.Zig;

class NavPage {

    public var scenes(default, null):Array<Scene>;
    public var navToSignal(default, null):Zig<NavAddress->Void>;
    public var updateViewSignal(default, null):Zig<Void->Void>;

    public function new():Void {
        scenes = [];
        navToSignal = new Zig();
        updateViewSignal = new Zig();
    }
}
