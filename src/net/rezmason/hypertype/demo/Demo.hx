package net.rezmason.hypertype.demo;

import net.rezmason.hypertype.core.Body;
import net.rezmason.hypertype.core.Interaction;

using net.rezmason.hypertype.core.GlyphUtils;

class Demo {

    public var body(default, null):Body = new Body();
    var time:Float = 0;

    public function new():Void {
        body.interactionSignal.add(receiveInteraction);
        body.updateSignal.add(update);
    }

    function update(delta:Float):Void time += delta;

    function receiveInteraction(id:Int, interaction:Interaction):Void {}

}
