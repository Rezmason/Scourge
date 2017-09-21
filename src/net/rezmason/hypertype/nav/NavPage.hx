package net.rezmason.hypertype.nav;

import net.rezmason.hypertype.core.Container;
import net.rezmason.utils.Zig;

class NavPage {
    public var navToSignal(default, null):Zig<NavAddress->Void> = new Zig();
    public var container(default, null):Container = new Container();
    public function new() {
        container.boundingBox.set({width:REL(1), height:REL(1), scaleMode:SHOW_ALL, align:CENTER, verticalAlign:MIDDLE});
        container.boxed = true;
    }
}
