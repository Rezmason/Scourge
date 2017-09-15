package net.rezmason.hypertype.core;

import lime.math.Matrix4;
import net.rezmason.ds.SceneNode;
import net.rezmason.utils.Zig;

using net.rezmason.hypertype.core.GlyphUtils;

class Container extends SceneNode<Container> {

    public var transform(default, null):Matrix4 = new Matrix4();
    public var concatenatedTransform(get, null):Matrix4;
    public var mouseEnabled(default, set):Bool = true;
    public var visible(default, set):Bool = true;
    public var isInteractive(get, null):Bool;
    public var interactionSignal(default, null):Zig<Int->Interaction->Void> = new Zig();
    public var updateSignal(default, null):Zig<Float->Void> = new Zig();
    public var invalidateSignal(default, null):Zig<Void->Void> = new Zig();
    public var stage(get, null):Stage;
    public var boundingBox(default, null):BoundingBox = new BoundingBox();
    var concatTransform:Matrix4 = new Matrix4();

    override public function addChild(node:Container):Bool {
        var success = super.addChild(node);
        if (success) {
            node.updateBoundingBox();
            node.update(0);
            node.invalidateSignal.add(invalidateSignal.dispatch);
            invalidateSignal.dispatch();
        }
        return success;
    }

    override public function removeChild(node:Container):Bool {
        var success = super.removeChild(node);
        if (success) {
            node.invalidateSignal.remove(invalidateSignal.dispatch);
            invalidateSignal.dispatch();
        }
        return success;
    }

    @:allow(net.rezmason.hypertype.core)
    function update(delta:Float):Void updateSignal.dispatch(delta);

    @:allow(net.rezmason.hypertype.core)
    function interact(glyphID:Int, interaction:Interaction):Void interactionSignal.dispatch(glyphID, interaction);

    inline function set_visible(val:Bool) {
        var isInteractive = this.isInteractive;
        visible = val;
        if (isInteractive != this.isInteractive) invalidateSignal.dispatch();
        return visible;
    }

    inline function set_mouseEnabled(val:Bool) {
        var isInteractive = this.isInteractive;
        mouseEnabled = val;
        if (isInteractive != this.isInteractive) invalidateSignal.dispatch();
        return mouseEnabled;
    }

    inline function get_isInteractive() return visible && mouseEnabled;

    function get_concatenatedTransform():Matrix4 {
        concatTransform.copyFrom(transform);
        if (parent != null) concatTransform.append(parent.concatenatedTransform);
        return concatTransform;
    }

    inline function get_stage() return cast root;

    public function updateBoundingBox() {
        boundingBox.solve((parent == null) ? null : parent.boundingBox.output);
        // TODO: do something with it
        for (child in children()) child.updateBoundingBox();
    }
}
