package net.rezmason.hypertype.demo;

import net.rezmason.hypertype.core.Body;
import net.rezmason.hypertype.core.Container;
import net.rezmason.hypertype.core.Interaction;

using net.rezmason.hypertype.core.GlyphUtils;

class Demo {

    public var container(default, null):Container = new Container();
    var body:Body = new Body();
    var time:Float = 0;

    public function new():Void {
        container.boundingBox.set({width:REL(1), height:REL(1), scaleMode:SHOW_ALL, align:CENTER, verticalAlign:MIDDLE});
        container.boxed = true;
        container.addChild(body);
        body.interactionSignal.add(receiveInteraction);
        body.updateSignal.add(update);
    }

    function update(delta:Float):Void time += delta;

    function receiveInteraction(id:Int, interaction:Interaction):Void {}

}
