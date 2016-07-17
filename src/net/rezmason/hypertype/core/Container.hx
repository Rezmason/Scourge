package net.rezmason.hypertype.core;

import lime.math.Matrix4;
import lime.math.Vector4;
import net.rezmason.ds.SceneNode;
import net.rezmason.utils.Zig;

using net.rezmason.hypertype.core.GlyphUtils;

class Container extends SceneNode<Container> {

    public var transform(default, null):Matrix4 = new Matrix4();
    public var concatenatedTransform(get, null):Matrix4;
    public var glyphScale(default, set):Float;
    public var concatenatedParams(get, null):Vector4;
    public var mouseEnabled(default, set):Bool = true;
    public var visible(default, set):Bool = true;
    public var isInteractive(get, null):Bool;
    public var interactionSignal(default, null):Zig<Int->Interaction->Void> = new Zig();
    public var updateSignal(default, null):Zig<Float->Void> = new Zig();
    public var invalidateSignal(default, null):Zig<Void->Void> = new Zig();
    public var stage(get, null):Stage;
    var params:Vector4;
    var concatTransform:Matrix4 = new Matrix4();
    var concatParams:Vector4 = new Vector4();

    public function new():Void {
        super();
        params = new Vector4();
        glyphScale = 1;
        params.x = glyphScale;
    }

    override public function addChild(node:Container):Bool {
        var success = super.addChild(node);
        if (success) {
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

    inline function set_glyphScale(val:Float):Float {
        glyphScale = val;
        params.x = glyphScale;
        return glyphScale;
    }

    inline function set_visible(visible:Bool) {
        var isInteractive = this.isInteractive;
        this.visible = visible;
        if (isInteractive != this.isInteractive) invalidateSignal.dispatch();
        return this.visible;
    }

    inline function set_mouseEnabled(mouseEnabled:Bool) {
        var isInteractive = this.isInteractive;
        this.mouseEnabled = mouseEnabled;
        if (isInteractive != this.isInteractive) invalidateSignal.dispatch();
        return this.mouseEnabled;
    }

    inline function get_isInteractive() return visible && mouseEnabled;

    function get_concatenatedTransform():Matrix4 {
        concatTransform.copyFrom(transform);
        if (parent != null) concatTransform.append(parent.concatenatedTransform);
        return concatTransform;
    }

    function get_concatenatedParams():Vector4 {
        concatParams.copyFrom(params);
        if (parent != null) {
            var parentParams = parent.concatenatedParams;
            concatParams.x *= parentParams.x;
            concatParams.y *= parentParams.y;
            concatParams.z *= parentParams.z;
            concatParams.w *= parentParams.w;
        }
        return concatParams;
    }

    inline function get_stage() return cast root;
}
