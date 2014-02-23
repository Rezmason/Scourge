package net.rezmason.scourge.textview.ui;

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
    inline static var DEFAULT_GLYPH_HEIGHT_IN_POINTS:Float = 18;

    var spaceCode:Int;

    var glyphHeightInPoints:Float;
    var glyphWidthInPixels:Float;
    var glyphHeightInPixels:Float;
    var baseTransform:Matrix3D;

    var croppedViewRect:Rectangle;
    var viewPixelWidth:Float;
    var viewPixelHeight:Float;

    var currentScrollPos:Float;
    var glideGoal:Float;
    var gliding:Bool;
    var lastRedrawPos:Float;

    var caretGlyph:Glyph;
    var caretGlyphID:Int;
    var caretGlyphGuide:Glyph;

    var dragging:Bool;
    var dragStartY:Float;
    var dragStartPos:Float;

    var numRows:Int;
    var numCols:Int;

    var bodyPaint:Int;

    var uiMediator:UIMediator;

    public function new(bufferUtil:BufferUtil, glyphTexture:GlyphTexture, uiMediator:UIMediator):Void {

        super(bufferUtil, glyphTexture);

        bodyPaint = id << 16;
        spaceCode = ' '.charCodeAt(0);

        baseTransform = new Matrix3D();
        baseTransform.appendScale(1, -1, 1);

        glyphHeightInPoints = DEFAULT_GLYPH_HEIGHT_IN_POINTS;
        glyphHeightInPixels = glyphHeightInPoints * getScreenDPI() / NATIVE_DPI;
        glyphWidthInPixels = glyphHeightInPixels / glyphTexture.font.glyphRatio;

        currentScrollPos = Math.NaN;
        gliding = false;

        numRows = 0;
        numCols = 0;

        scaleMode = EXACT_FIT;

        this.uiMediator = uiMediator;
    }

    public function setFontSize(size:Float):Bool {
        var worked:Bool = false;
        if (!Math.isNaN(size) && size >= 14 && size <= 72) {
            worked = true;
            glyphHeightInPoints = size;
            glyphHeightInPixels = glyphHeightInPoints * getScreenDPI() / NATIVE_DPI;
            glyphWidthInPixels = glyphHeightInPixels / glyphTexture.font.glyphRatio;
            resize();
        }
        return worked;
    }

    public function setFontTexture(tex:GlyphTexture):Bool {
        var worked:Bool = false;
        if (tex != null) {
            worked = true;
            glyphTexture = tex;
            glyphWidthInPixels = glyphHeightInPixels / glyphTexture.font.glyphRatio;
            resize();
        }
        return worked;
    }

    override public function update(delta:Float):Void {

        if (!dragging && uiMediator.isDirty) {
            uiMediator.updateDirtyText(bodyPaint);
            if (Math.isNaN(currentScrollPos)) setScrollPos(uiMediator.bottomPos());
            glideTextToPos(uiMediator.bottomPos());
            redrawHitSignal.dispatch();
        }

        updateGlide();
        uiMediator.updateSpans(delta);
        findAndPositionCaret();
        taperScrollEdges();

        super.update(delta);
    }

    override public function adjustLayout(stageWidth:Int, stageHeight:Int):Void {
        croppedViewRect = viewRect;
        var originalViewRect:Rectangle = viewRect.clone();
        viewRect.inflate(-0.02, -0.02);
        super.adjustLayout(stageWidth, stageHeight);
        viewPixelHeight = viewRect.height * stageHeight;
        viewPixelWidth  = viewRect.width  * stageWidth;
        viewRect = originalViewRect;
        resize();
    }

    function glideTextToPos(pos:Float):Void {
        gliding = true;
        glideGoal = Math.round(Math.max(0, Math.min(uiMediator.bottomPos(), pos)));
    }

    override public function receiveInteraction(id:Int, interaction:Interaction):Void {
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
            case _: uiMediator.receiveInteraction(id, interaction);
        }
    }

    inline function findAndPositionCaret():Void {
        caretGlyphGuide = null;

        if (caretGlyphID != -1) {
            var leftGlyph:Glyph = glyphs[caretGlyphID - 1];
            var rightGlyph:Glyph = glyphs[caretGlyphID];

            if (leftGlyph != null || rightGlyph != null) {
                if (leftGlyph == null) {
                    caretGlyphGuide = rightGlyph;
                } else if (rightGlyph == null) {
                    caretGlyphGuide =  leftGlyph;
                } else {
                    var  leftCodeIsSpace:Bool =  leftGlyph.get_char() == spaceCode;
                    var rightCodeIsSpace:Bool = rightGlyph.get_char() == spaceCode;
                    if (!leftCodeIsSpace || !rightCodeIsSpace) {
                        if (leftCodeIsSpace) {
                            caretGlyphGuide = rightGlyph;
                        } else if (rightCodeIsSpace) {
                            caretGlyphGuide =  leftGlyph;
                        } else {
                            caretGlyphGuide = leftGlyph;
                        }
                    } else {
                        caretGlyphGuide = leftGlyph;
                    }
                }
            }

            if (caretGlyphGuide == leftGlyph) {
                caretGlyph.set_x(caretGlyphGuide.get_x() + 0.5 / numCols);
            } else if (caretGlyphGuide == rightGlyph) {
                caretGlyph.set_x(caretGlyphGuide.get_x() - 0.5 / numCols);
            }
        }

        if (caretGlyphGuide != null) {
            caretGlyph.set_y(caretGlyphGuide.get_y());
            caretGlyph.set_z(caretGlyphGuide.get_z());
        } else {
            caretGlyph.set_z(1);
        }
    }

    inline function resize():Void {
        numRows = Std.int(viewPixelHeight / glyphHeightInPixels) + 1;
        numCols = Std.int(viewPixelWidth  / glyphWidthInPixels );

        setGlyphScale(croppedViewRect.width / numCols * 2, croppedViewRect.height / (numRows - 1) * 2);

        growTo(numRows * numCols + 1);

        caretGlyph = glyphs[numGlyphs - 1];

        lastRedrawPos = Math.NaN;
        reorderGlyphs();

        uiMediator.adjustLayout(numRows, numCols);
        uiMediator.styleCaret(caretGlyph, glyphTexture.font);
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
        caretGlyphID = uiMediator.stylePage(scrollStartIndex, glyphs, caretGlyph, glyphTexture.font);
        findAndPositionCaret();
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
            glyph.set_color(Colors.mult(glyph.get_color(), 1 - offset));
            if (glyph == caretGlyphGuide) caretGlyph.set_color(Colors.mult(caretGlyph.get_color(), 1 - offset));

            glyph = glyphs[lastRow + col];
            glyph.set_color(Colors.mult(glyph.get_color(), offset));
            if (glyph == caretGlyphGuide) caretGlyph.set_color(Colors.mult(caretGlyph.get_color(), offset));
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
                    redrawHitSignal.dispatch();
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
