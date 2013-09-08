package net.rezmason.scourge.textview;

import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.system.Capabilities;
import flash.ui.Keyboard;

import haxe.Utf8;

import net.rezmason.gl.utils.BufferUtil;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.text.Sigil.STYLE;
import net.rezmason.scourge.textview.text.Style;

using net.rezmason.scourge.textview.core.GlyphUtils;

class UIBody extends Body {

    inline static var glideEase:Float = 0.6;
    inline static var NATIVE_DPI:Float = 96;
    inline static var GLYPH_HEIGHT_IN_POINTS:Float = 24;

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

    public function new(bufferUtil:BufferUtil, glyphTexture:GlyphTexture, redrawHitAreas:Void->Void, uiText:UIText):Void {

        baseTransform = new Matrix3D();
        baseTransform.appendScale(1, -1, 1);

        glyphHeightInPixels = GLYPH_HEIGHT_IN_POINTS * getScreenDPI() / NATIVE_DPI;
        glyphWidthInPixels = glyphHeightInPixels / glyphTexture.font.glyphRatio;

        var numGlyphColumns:Int = Std.int(Capabilities.screenResolutionX / glyphWidthInPixels);
        var numGlyphRows:Int = Std.int(Capabilities.screenResolutionY / glyphHeightInPixels);

        var numGlyphs:Int = (numGlyphRows + 1) * numGlyphColumns;

        currentScrollPos = Math.NaN;
        gliding = false;

        numRows = 0;
        numCols = 0;

        super(bufferUtil, numGlyphs, glyphTexture, redrawHitAreas);

        letterbox = false;

        this.uiText = uiText;
    }

    override public function update(delta:Float):Void {

        if (!dragging && uiText.updateDirtyText()) {
            if (Math.isNaN(currentScrollPos)) currentScrollPos = uiText.bottomPos();
            setScrollPos(currentScrollPos);

            glideTextToPos(uiText.bottomPos());
        }

        updateGlide();
        uiText.updateStyledGlyphs(delta);
        taperScrollEdges();
        super.update(delta);
    }

    override public function adjustLayout(stageWidth:Int, stageHeight:Int):Void {
        super.adjustLayout(stageWidth, stageHeight);
        var rect:Rectangle = sanitizeLayoutRect(stageWidth, stageHeight, viewRect);

        numRows = Std.int(rect.height * stageHeight / glyphHeightInPixels) + 1;

        numCols = Std.int(rect.width  * stageWidth  / glyphWidthInPixels );
        setGlyphScale(rect.width / numCols * 2, rect.height / (numRows - 1) * 2);

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
            case MOUSE(type, x, y):
                if (dragging) {
                    switch (type) {
                        case DROP, CLICK:
                            dragging = false;
                        case ENTER, EXIT, MOVE:
                            glideTextToPos(dragStartPos + (dragStartY - y) * (numRows - 1));
                        case _:
                    }
                } else if (id == 0) {
                    if (type == MOUSE_DOWN) {
                        dragging = true;
                        dragStartY = y;
                        dragStartPos = currentScrollPos;
                    }
                } else {
                    uiText.interact(id, interaction);
                }
            case KEYBOARD(type, key, char, shift, alt, ctrl): uiText.interact(id, interaction);
        }
    }

    inline function reorderGlyphs():Void {
        var id:Int = 0;
        for (row in 0...numRows) {
            for (col in 0...numCols) {
                var x:Float = ((col + 0.5) / numCols - 0.5);
                var y:Float = ((row + 0.5) / (numRows - 1) - 0.5);
                var glyph:Glyph = glyphs[id++];
                glyph.set_pos(x, y, 0);
            }
        }

        var numGlyphsInLayout:Int = numRows * numCols;
        for (ike in 0...numGlyphsInLayout) glyphs[ike].set_s(1);
        for (ike in numGlyphsInLayout...numGlyphs) glyphs[ike].set_s(0);
    }

    inline function setScrollPos(pos:Float):Void {

        currentScrollPos = pos;

        var scrollStartIndex:Int = Std.int(currentScrollPos);
        var id:Int = 0;
        var pageSegment:Array<String> = uiText.getPageSegment(scrollStartIndex);
        var styleIndex:Int = uiText.getLineStyleIndex(scrollStartIndex);

        uiText.resetStyledGlyphs();

        var styleCode:Int = Utf8.charCodeAt(STYLE, 0);

        var currentStyle:Style = uiText.getStyleByIndex(styleIndex);
        for (line in pageSegment) {
            var index:Int = 0;
            for (index in 0...Utf8.length(line)) {
                var charCode:Int = Utf8.charCodeAt(line, index);
                if (charCode == styleCode) {
                    currentStyle = uiText.getStyleByIndex(++styleIndex);
                } else {
                    var glyph:Glyph = glyphs[id++];
                    glyph.set_char(charCode, glyphTexture.font);
                    currentStyle.addGlyph(glyph);
                    glyph.set_z(0);
                }
            }
        }

        uiText.updateStyledGlyphs(0);
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
        #elseif js return Capabilities.screenDPI;
        #else return NATIVE_DPI;
        #end
    }
}
