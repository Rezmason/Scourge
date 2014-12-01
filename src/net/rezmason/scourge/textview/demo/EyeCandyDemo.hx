package net.rezmason.scourge.textview.demo;

import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.geom.Vector3D;
import flash.ui.Keyboard;

import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.core.GlyphTexture;

using net.rezmason.scourge.textview.core.GlyphUtils;

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
    var dragStartTransform:Matrix3D;
    var rawTransform:Matrix3D;
    var setBackTransform:Matrix3D;

    public function new(num:Int = 2400):Void {

        body = new Body();
        body.interactionSignal.add(receiveInteraction);
        body.updateSignal.add(update);
        body.glyphScale = 0.007;

        time = 0;

        dragging = false;
        dragStartTransform = new Matrix3D();
        rawTransform = new Matrix3D();
        rawTransform.appendRotation( 45, Vector3D.X_AXIS);
        rawTransform.appendRotation(315, Vector3D.Z_AXIS);
        setBackTransform = rawTransform.clone();
        setBackTransform.appendTranslation(0, 0, 0.5);
        body.transform.copyFrom(setBackTransform);

        setSize(num); // 40000, 240
    }

    inline function setSize(num:Int):Void {
        body.growTo(num);

        var dTheta:Float = Math.PI * (3 - Math.sqrt(5));
        var dZ:Float = 2 / (body.numGlyphs + 1);
        var theta:Float = 0;
        var _z:Float = 1 - dZ / 2;

        for (glyph in body.eachGlyph()) {
            var charCode:Int = CHARS.charCodeAt(glyph.id % CHARS.length);

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

            glyph.set_xyz(x, y, z);
            glyph.set_rgb(r, g, b);
            glyph.set_a(1);
            glyph.set_char(charCode);
            glyph.set_paint(glyph.id | body.id << 16);

            _z -= dZ;
            theta += dTheta;
        }
    }

    inline function ramp(num:Float):Float return (2 - num) * num;

    public function update(delta:Float):Void {
        time += delta;

        body.transform.identity();
        body.transform.appendRotation(time * 30, Vector3D.Z_AXIS);
        body.transform.append(setBackTransform);

        for (glyph in body.eachGlyph()) {
            glyph.set_p(Math.cos(time * 4 + glyph.get_x() * 20) * 0.200 + 0.4);
            glyph.set_s(Math.cos(time * 4 + glyph.get_y() * 30) * 0.200 + 3.0);
            glyph.set_f(Math.cos(time * 8 + glyph.get_z() * 40) * 0.280 + 0.4);
        }
    }

    function receiveInteraction(id:Int, interaction:Interaction):Void {
        switch (interaction) {
            case MOUSE(type, x, y):
                switch (type) {
                    // case CLICK: setGlobalColor(Math.random(), Math.random(), Math.random());
                    case MOUSE_DOWN: startDrag(x, y);
                    case MOUSE_UP, DROP: stopDrag();
                    case MOVE, ENTER, EXIT: if (dragging) updateDrag(x, y);
                    case _:
                }
            case KEYBOARD(type, key, char, shift, alt, ctrl):
                if (type == KEY_DOWN) {
                    switch (key) {
                        case Keyboard.LEFT:  setSize(Std.int(body.numGlyphs * (shift ? 0.666 : 0.9)));
                        case Keyboard.RIGHT: setSize(Std.int(body.numGlyphs * (shift ? 1.500 : 1.1)));
                        case _: setGlobalChar(cast char);
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
        rawTransform.appendRotation((dragX - x) * 180, Vector3D.Y_AXIS);
        rawTransform.appendRotation((dragY - y) * 180, Vector3D.X_AXIS);
        setBackTransform.copyFrom(rawTransform);
        setBackTransform.appendTranslation(0, 0, 0.5);
    }

    inline function stopDrag():Void {
        dragging = false;
    }

    inline function setGlobalColor(r:Float, g:Float, b:Float):Void {
        for (ike in 0...body.numGlyphs) body.getGlyphByID(ike).set_rgb(r, g, b);
    }

    inline function setGlobalChar(charCode:Int):Void {
        for (ike in 0...body.numGlyphs) body.getGlyphByID(ike).set_char(charCode);
    }

}
