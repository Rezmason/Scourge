package net.rezmason.scourge.textview;

import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.system.Capabilities;

import net.rezmason.gl.utils.BufferUtil;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.scourge.textview.core.Interaction;

using net.rezmason.scourge.textview.core.GlyphUtils;

class UIBody extends Body {

    inline static var glideEase:Float = 0.6;
    inline static var NATIVE_DPI:Float = 96;
    inline static var GLYPH_HEIGHT_IN_POINTS:Float = 18;

    var glyphWidthInPixels :Float;
    var glyphHeightInPixels:Float;
    var baseTransform:Matrix3D;

    var currentScrollPos:Float;
    var glideGoal:Float;
    var gliding:Bool;
    var lastRedrawPos:Float;

    var dragging:Bool;
    var dragStartY:Float;
    var dragStartPos:Float;

    var numRows:Int;
    var numCols:Int;

    var uiText:UIText;

    public var padding:Float;

    public function new(bufferUtil:BufferUtil, glyphTexture:GlyphTexture, redrawHitAreas:Void->Void, uiText:UIText):Void {

        super(bufferUtil, glyphTexture, redrawHitAreas);

        baseTransform = new Matrix3D();
        baseTransform.appendScale(1, -1, 1);

        glyphHeightInPixels = GLYPH_HEIGHT_IN_POINTS * getScreenDPI() / NATIVE_DPI;
        glyphWidthInPixels = glyphHeightInPixels / glyphTexture.font.glyphRatio;

        currentScrollPos = Math.NaN;
        gliding = false;

        numRows = 0;
        numCols = 0;

        scaleMode = EXACT_FIT;

        this.uiText = uiText;
    }

    override public function update(delta:Float):Void {

        if (!dragging && uiText.updateDirtyText()) {
            if (Math.isNaN(currentScrollPos)) setScrollPos(uiText.bottomPos());
            glideTextToPos(uiText.bottomPos());
        }

        updateGlide();
        uiText.updateStyledGlyphs(delta);
        taperScrollEdges();
        super.update(delta);
    }

    override public function adjustLayout(stageWidth:Int, stageHeight:Int):Void {

        viewRect.inflate(-padding, -padding);
        super.adjustLayout(stageWidth, stageHeight);
        var rect:Rectangle = sanitizeLayoutRect(stageWidth, stageHeight, viewRect);
        viewRect.inflate(padding, padding);

        numRows = Std.int(rect.height * stageHeight / glyphHeightInPixels) + 1;
        numCols = Std.int(rect.width  * stageWidth  / glyphWidthInPixels );

        setGlyphScale(rect.width / numCols * 2, rect.height / (numRows - 1) * 2);

        growTo(numRows * numCols);

        lastRedrawPos = Math.NaN;
        reorderGlyphs();

        uiText.adjustLayout(numRows, numCols);
    }

    function glideTextToPos(pos:Float):Void {
        gliding = true;
        glideGoal = Math.round(Math.max(0, Math.min(uiText.bottomPos(), pos)));
    }

    override public function interact(id:Int, interaction:Interaction):Void {
        switch (interaction) {
            case MOUSE(type, x, y) if (dragging || id == 0):
                if (dragging) {
                    switch (type) {
                        case DROP, CLICK: dragging = false;
                        case ENTER, EXIT, MOVE: glideTextToPos(dragStartPos + (dragStartY - y) * (numRows - 1));
                        case _:
                    }
                } else if (id == 0 && type == MOUSE_DOWN) {
                    dragging = true;
                    dragStartY = y;
                    dragStartPos = currentScrollPos;
                }
            case _: uiText.interact(id, interaction);
        }
    }

    inline function reorderGlyphs():Void {
        var id:Int = 0;
        for (row in 0...numRows) {
            for (col in 0...numCols) {
                var x:Float = ((col + 0.5) / numCols - 0.5);
                var y:Float = ((row + 0.5) / (numRows - 1) - 0.5);
                glyphs[id].set_pos(x, y, 0);
                id++;
            }
        }
    }

    inline function setScrollPos(pos:Float):Void {
        currentScrollPos = pos;
        var scrollStartIndex:Int = Std.int(currentScrollPos);
        uiText.stylePage(scrollStartIndex, glyphs, glyphTexture.font);
        taperScrollEdges();
        transform.identity();
        transform.append(baseTransform);
        transform.appendTranslation(0, (currentScrollPos - scrollStartIndex) / (numRows - 1), 0);
    }

    inline function taperScrollEdges():Void {
        var offset:Float = ((currentScrollPos % 1) + 1) % 1;
        var lastRow:Int = (numRows - 1) * numCols;
        var glyph:Glyph;
        for (col in 0...numCols) {
            glyph = glyphs[col];
            glyph.set_color(glyph.get_r() * (1 - offset), glyph.get_g() * (1 - offset), glyph.get_b() * (1 - offset));

            glyph = glyphs[lastRow + col];
            glyph.set_color(glyph.get_r() * offset, glyph.get_g() * offset, glyph.get_b() * offset);
        }
    }

    inline function updateGlide():Void {
        if (gliding) {
            gliding = Math.abs(glideGoal - currentScrollPos) > 0.001;
            if (gliding) {
                setScrollPos(currentScrollPos * glideEase + glideGoal * (1 - glideEase));
            } else {
                setScrollPos(glideGoal);
                if (lastRedrawPos != glideGoal) {
                    lastRedrawPos = glideGoal;
                    redrawHitAreas();
                }
            }
        }
    }

    inline function getScreenDPI():Float {
        #if flash
            var dpi:Null<Float> = Reflect.field(flash.Lib.current.loaderInfo.parameters, 'dpi');
            if (dpi == null) dpi = NATIVE_DPI;
            return dpi;
        #else return Capabilities.screenDPI;
        #end
    }
}
