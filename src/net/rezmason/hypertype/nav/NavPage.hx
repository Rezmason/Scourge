package net.rezmason.hypertype.nav;

import net.rezmason.hypertype.core.Body;
import net.rezmason.utils.Zig;

class NavPage {
    public var navToSignal(default, null):Zig<NavAddress->Void> = new Zig();
    public var body(default, null):Body = new Body();
    public function new() {}
}
