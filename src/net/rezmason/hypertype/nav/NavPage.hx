package net.rezmason.hypertype.nav;

import net.rezmason.hypertype.core.Container;
import net.rezmason.utils.Zig;

class NavPage {
    public var navToSignal(default, null):Zig<NavAddress->Void> = new Zig();
    public var container(default, null):Container = new Container();
    public function new() {
        container.boundingBox.width  = Proportion(1);
        container.boundingBox.height = Proportion(1);
    }
}
