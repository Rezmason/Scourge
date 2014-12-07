package net.rezmason.scourge.textview;

import net.rezmason.scourge.textview.core.Scene;
import net.rezmason.utils.Zig;

class NavPage {

    public var navToSignal(default, null):Zig<NavAddress->Void>;

    var scenes:Array<Scene>;

    public function new():Void {
        scenes = [];
        navToSignal = new Zig();
    }

    public inline function eachScene():Iterator<Scene> return scenes.iterator();
}
