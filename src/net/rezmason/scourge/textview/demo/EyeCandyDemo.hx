package net.rezmason.scourge.textview.demo;

import net.rezmason.gl.GLTypes;

import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.core.GlyphTexture;

using net.rezmason.scourge.textview.core.GlyphUtils;
using net.rezmason.utils.CharCode;

class EyeCandyDemo {

    inline static var COLOR_RANGE:Int = 6;
    inline static var CHARS:String =
        Strings.ALPHANUMERICS +
    '';

    public var body(default, null):Body;

    var time:Float;

    var dragging:Bool;
    var dragX:Float;
    var dragY:Float;
    var dragStartTransform:Matrix4;
    var rawTransform:Matrix4;
    var setBackTransform:Matrix4;

    var brightGlyphs:Array<Glyph>;
    var darkerGlyphs:Array<Glyph>;

    public function new(num:Int = 2400):Void {

        body = new Body();
        body.interactionSignal.add(receiveInteraction);
        body.updateSignal.add(update);
        body.glyphScale = 0.007;

        time = 0;

        dragging = false;
        dragStartTransform = new Matrix4();
        rawTransform = new Matrix4();
        rawTransform.appendRotation( 45, Vector4.X_AXIS);
        rawTransform.appendRotation(315, Vector4.Z_AXIS);
        setBackTransform = rawTransform.clone();
        setBackTransform.appendTranslation(0, 0, 0.5);
        body.transform.copyFrom(setBackTransform);

        setSize(num); // 40000, 240
    }

    inline function setSize(num:Int):Void {
        body.growTo(num * 2);

        brightGlyphs = [for (ike in 0...num) body.getGlyphByID(ike * 2)];
        darkerGlyphs = [for (ike in 0...num) body.getGlyphByID(ike * 2 + 1)];

        var dTheta:Float = Math.PI * (3 - Math.sqrt(5));
        var dZ:Float = 2 / (num + 1);
        var theta:Float = 0;
        var _z:Float = 1 - dZ / 2;

        var darkCharCode = '•'.code();

        for (ike in 0...num) {
            var charCode:Int = CHARS.charCodeAt(ike % CHARS.length);

            var rad:Float = Math.sqrt(1 - _z * _z);
            var x:Float = Math.cos(theta) * rad;
            var y:Float = Math.sin(theta) * rad;
            var z:Float = _z;

            x *= 0.6;
            y *= 0.6;
            z *= 0.6;

            var r:Float = ramp(x + 0.5);
            var g:Float = ramp(y + 0.5);
            var b:Float = ramp(z + 0.5);

            var brightGlyph = brightGlyphs[ike];
            brightGlyph.SET({x:x, y:y, z:z, r:r, g:g, b:b, a:1, char:charCode, paint:brightGlyph.id});
            
            x *= 0.8;
            y *= 0.8;
            z *= 0.8;

            r -= 1;
            g -= 1;
            b -= 1;

            var darkerGlyph = darkerGlyphs[ike];
            darkerGlyph.SET({x:x, y:y, z:z, r:r, g:g, b:b, a:1, char:darkCharCode, paint:darkerGlyph.id, s:10});
            darkerGlyph.set_s(0);

            _z -= dZ;
            theta += dTheta;
        }
    }

    inline function ramp(num:Float):Float return (2 - num) * num;

    public function update(delta:Float):Void {
        time += delta;

        body.transform.identity();
        body.transform.appendRotation(time * 30, Vector4.Z_AXIS);
        body.transform.append(setBackTransform);

        for (glyph in body.eachGlyph()) {
            glyph.set_p(Math.cos(time * 4 + glyph.get_x() * 20) * 0.200 + 0.4);
        }

        for (glyph in brightGlyphs) {
            glyph.set_s(Math.cos(time * 4 + glyph.get_y() * 30) * 0.200 + 3.0);
            glyph.set_f(Math.cos(time * 8 + glyph.get_z() * 40) * 0.280 + 0.4);
        }
    }

    function receiveInteraction(id:Int, interaction:Interaction):Void {
        switch (interaction) {
            case MOUSE(type, x, y):
                switch (type) {
                    case MOUSE_DOWN: startDrag(x, y);
                    case MOUSE_UP, DROP: stopDrag();
                    case MOVE, ENTER, EXIT: if (dragging) updateDrag(x, y);
                    case _:
                }
            case KEYBOARD(type, keyCode, modifier):
                if (type == KEY_DOWN) {
                    switch (keyCode) {
                        case LEFT:  setSize(Std.int(body.numGlyphs * (modifier.shiftKey ? 0.666 : 0.9)));
                        case RIGHT: setSize(Std.int(body.numGlyphs * (modifier.shiftKey ? 1.500 : 1.1)));
                        case _: setGlobalChar(cast keyCode);
                    }
                }
        }
    }

    inline function startDrag(x:Float, y:Float):Void {
        dragging = true;
        dragStartTransform.copyFrom(rawTransform);
        dragX = x;
        dragY = y;
    }

    inline function updateDrag(x:Float, y:Float):Void {
        rawTransform.copyFrom(dragStartTransform);
        rawTransform.appendRotation((dragX - x) * 180, Vector4.Y_AXIS);
        rawTransform.appendRotation((dragY - y) * 180, Vector4.X_AXIS);
        setBackTransform.copyFrom(rawTransform);
        setBackTransform.appendTranslation(0, 0, 0.5);
    }

    inline function stopDrag():Void {
        dragging = false;
    }

    inline function setGlobalChar(charCode:Int):Void {
        for (glyph in brightGlyphs) glyph.set_char(charCode);
    }

}
