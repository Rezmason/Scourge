package net.rezmason.scourge.textview;

import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.geom.Vector3D;

import net.rezmason.gl.utils.BufferUtil;

import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.core.GlyphTexture;

import net.rezmason.scourge.model.Game;

using net.rezmason.scourge.textview.core.GlyphUtils;

class BoardBody extends Body {

    inline static var COLOR_RANGE:Int = 6;
    inline static var CHARS:String = TestStrings.WEIRD_SYMBOLS;

    static var TEAM_COLORS:Array<Int> = [0xFF0090, 0xFFC800, 0x30FF00, 0x00C0FF, 0xFF6000, 0xC000FF, 0x0030FF, 0x606060, ];

    var dragging:Bool;
    var dragX:Float;
    var dragY:Float;
    var dragStartTransform:Matrix3D;
    var rawTransform:Matrix3D;
    var homeTransform:Matrix3D;

    var game:Game;

    public function new(bufferUtil:BufferUtil, glyphTexture:GlyphTexture, redrawHitAreas:Void->Void, game:Game):Void {

        this.game = game;
        // Create a node view for each node
            // for now, base x and y positions on neighborness
        // Find center and nudge everybody in that direction

        var num:Int = game.state.nodes.length * 1;
        super(bufferUtil, num, glyphTexture, redrawHitAreas);

        dragging = false;
        dragStartTransform = new Matrix3D();
        rawTransform = new Matrix3D();
        rawTransform.appendRotation( 45, Vector3D.X_AXIS);
        rawTransform.appendRotation(315, Vector3D.Z_AXIS);
        homeTransform = new Matrix3D();
        homeTransform.appendTranslation(0, 0, 0.5);

        transform = rawTransform.clone();
        transform.append(homeTransform);

        for (glyph in glyphs) {

        }
    }

    override public function adjustLayout(stageWidth:Int, stageHeight:Int):Void {
        super.adjustLayout(stageWidth, stageHeight);

        var rect:Rectangle = sanitizeLayoutRect(stageWidth, stageHeight, viewRect);

        var screenSize:Float = Math.sqrt(stageWidth * stageWidth + stageHeight * stageHeight);
        var rectSize:Float = Math.min(rect.width * stageWidth, rect.height * stageHeight) / screenSize;
        var glyphWidth:Float = rectSize * 0.03;
        setGlyphScale(glyphWidth, glyphWidth * glyphTexture.font.glyphRatio * stageWidth / stageHeight);
    }

    override public function update(delta:Float):Void {
        if (!dragging) transform.interpolateTo(homeTransform, 0.5);
        super.update(delta);
    }

    override public function interact(id:Int, interaction:Interaction):Void {
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
                if (type == KEY_DOWN) setGlobalChar(char);
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
        transform.copyFrom(rawTransform);
        transform.append(homeTransform);
    }

    inline function stopDrag():Void {
        dragging = false;
    }

    inline function setGlobalColor(r:Float, g:Float, b:Float):Void {
        for (glyph in glyphs) glyph.set_color(r, g, b);
    }

    inline function setGlobalChar(charCode:Int):Void {
        if (charCode > 0) for (glyph in glyphs) glyph.set_char(charCode, glyphTexture.font);
    }

}
