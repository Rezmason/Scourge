package net.rezmason.scourge.textview.demo;

import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.geom.Vector3D;
import flash.ui.Keyboard;

import net.rezmason.gl.utils.BufferUtil;

import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.core.GlyphTexture;

using net.rezmason.scourge.textview.core.GlyphUtils;

class TestBody extends Body {

    inline static var COLOR_RANGE:Int = 6;
    inline static var CHARS:String =
        Strings.ALPHANUMERICS +
    '';

    var time:Float;

    var dragging:Bool;
    var dragX:Float;
    var dragY:Float;
    var dragStartTransform:Matrix3D;
    var rawTransform:Matrix3D;
    var setBackTransform:Matrix3D;

    public function new(bufferUtil:BufferUtil, glyphTexture:GlyphTexture, num:Int = 2400):Void {

        super(bufferUtil, glyphTexture);

        time = 0;

        dragging = false;
        dragStartTransform = new Matrix3D();
        rawTransform = new Matrix3D();
        rawTransform.appendRotation( 45, Vector3D.X_AXIS);
        rawTransform.appendRotation(315, Vector3D.Z_AXIS);
        setBackTransform = rawTransform.clone();
        setBackTransform.appendTranslation(0, 0, 0.5);
        transform.copyFrom(setBackTransform);

        setSize(num); // 40000, 240
    }

    inline function setSize(num:Int):Void {
        growTo(num);

        var dTheta:Float = Math.PI * (3 - Math.sqrt(5));
        var dZ:Float = 2 / (this.numGlyphs + 1);
        var theta:Float = 0;
        var _z:Float = 1 - dZ / 2;

        for (glyph in glyphs) {

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

            glyph.set_shape(x, y, z, 1, 0);
            glyph.set_rgb(r, g, b);
            glyph.set_char(charCode, glyphTexture.font);
            glyph.set_paint(glyph.id | id << 16);

            _z -= dZ;
            theta += dTheta;
        }
    }

    inline function ramp(num:Float):Float return (2 - num) * num;

    override public function adjustLayout(stageWidth:Int, stageHeight:Int):Void {
        super.adjustLayout(stageWidth, stageHeight);

        var screenSize:Float = Math.sqrt(stageWidth * stageWidth + stageHeight * stageHeight);
        var rectSize:Float = Math.min(viewRect.width * stageWidth, viewRect.height * stageHeight) / screenSize;
        var glyphWidth:Float = rectSize * 0.03;
        setGlyphScale(glyphWidth, glyphWidth * glyphTexture.font.glyphRatio * stageWidth / stageHeight);
    }

    override public function update(delta:Float):Void {
        time += delta;

        transform.identity();
        transform.appendRotation(time * 30, Vector3D.Z_AXIS);
        transform.append(setBackTransform);

        for (ike in 0...glyphs.length) {
            var glyph:Glyph = glyphs[ike];

            var d1:Float = glyph.get_z();
            var d2:Float = glyph.get_y();
            var d3:Float = glyph.get_x();
            var p:Float = (Math.cos(time * 4 + d1 * 20) * 0.500 + 1.0) * 0.4;
            var s:Float = (Math.cos(time * 4 + d2 * 30) * 0.100 + 1.5) * 2.0;
            var f:Float = (Math.cos(time * 8 + d3 * 40) * 0.180 + 0.0) + 0.4;

            glyph.set_p(p);
            glyph.set_s(s);
            glyph.set_f(f);
        }

        super.update(delta);
    }

    override public function receiveInteraction(id:Int, interaction:Interaction):Void {
        var glyph:Glyph = glyphs[id];
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
                        case Keyboard.LEFT:  setSize(Std.int(numGlyphs * (shift ? 0.666 : 0.9)));
                        case Keyboard.RIGHT: setSize(Std.int(numGlyphs * (shift ? 1.500 : 1.1)));
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
        for (glyph in glyphs) glyph.set_rgb(r, g, b);
    }

    inline function setGlobalChar(charCode:Int):Void {
        for (glyph in glyphs) glyph.set_char(charCode, glyphTexture.font);
    }

}
