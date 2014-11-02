package net.rezmason.scourge.textview.ui;

import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.system.Capabilities;

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
    var glyphWidth:Float;
    var glyphHeight:Float;
    var baseTransform:Matrix3D;

    var viewPixelWidth:Float;
    var viewPixelHeight:Float;

    var currentScrollPos:Float;
    var scrollY:Float;
    var glideGoal:Float;
    var gliding:Bool;
    var lastRedrawPos:Float;

    var caretGlyph:Glyph;
    var caretGlyphID:Int;
    var caretGlyphGuide:Glyph;
    var scrollerTrackGlyph:Glyph;
    var scrollerThumbGlyph:Glyph;

    var dragging:Bool;
    var dragStartY:Float;
    var dragStartPos:Float;

    var numRows:Int;
    var numCols:Int;
    var numTextCols:Int;

    var bodyPaint:Int;

    var uiMediator:UIMediator;

    public var showScrollBar(default, set):Bool;
    var scrollBarVisible:Bool;
    var scrollBarFade:Float;

    var sized:Bool;

    public function new(uiMediator:UIMediator):Void {

        super();
        sized = false;
        showScrollBar = false;
        scrollBarVisible = false;
        scrollBarFade = 0;

        bodyPaint = id << 16;
        spaceCode = ' '.charCodeAt(0);

        baseTransform = new Matrix3D();
        baseTransform.appendScale(1, -1, 1);

        glyphHeightInPoints = DEFAULT_GLYPH_HEIGHT_IN_POINTS;
        glyphHeightInPixels = glyphHeightInPoints * getScreenDPI() / NATIVE_DPI;
        glyphWidthInPixels = glyphHeightInPixels / glyphTexture.font.glyphRatio;

        currentScrollPos = Math.NaN;
        scrollY = 0;
        gliding = false;

        numRows = 0;
        numCols = 0;
        numTextCols = 0;

        camera.scaleMode = EXACT_FIT;

        this.uiMediator = uiMediator;
    }

    public function setFontSize(size:Float):Bool {
        var worked:Bool = false;
        if (!Math.isNaN(size) && size >= 14 && size <= 72) {
            worked = true;
            glyphHeightInPoints = size;
            glyphHeightInPixels = glyphHeightInPoints * getScreenDPI() / NATIVE_DPI;
            glyphWidthInPixels = glyphHeightInPixels / glyphTexture.font.glyphRatio;
            glyphWidth = glyphWidthInPixels / stageWidth;
            glyphHeight = glyphHeightInPixels / stageHeight;
            setGlyphScale(glyphWidth, glyphHeight);
            recalculateGeometry();
        }
        return worked;
    }

    public function setFontTexture(tex:GlyphTexture):Bool {
        var worked:Bool = false;
        if (tex != null) {
            worked = true;
            glyphTexture = tex;
            glyphWidthInPixels = glyphHeightInPixels / glyphTexture.font.glyphRatio;
            recalculateGeometry();
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

        updateGlide(delta);
        uiMediator.updateSpans(delta);
        findAndPositionCaret();
        taperScrollEdges();
        if (showScrollBar) updateScrollFade(delta);

        super.update(delta);
    }

    override public function resize(stageWidth:Int, stageHeight:Int):Void {
        sized = true;
        var originalViewRect:Rectangle = camera.rect.clone();
        super.resize(stageWidth, stageHeight);
        viewPixelHeight = camera.rect.height * stageHeight;
        viewPixelWidth  = camera.rect.width  * stageWidth;
        camera.rect = originalViewRect;
        glyphWidth = glyphWidthInPixels / stageWidth;
        glyphHeight = glyphHeightInPixels / stageHeight;
        setGlyphScale(glyphWidth, glyphHeight);
        recalculateGeometry();
    }

    function glideTextToPos(pos:Float):Void {
        gliding = true;
        glideGoal = Math.round(Math.max(0, Math.min(uiMediator.bottomPos(), pos)));
    }

    override public function receiveInteraction(id:Int, interaction:Interaction):Void {

        switch (interaction) {
            case MOUSE(type, x, y):
                switch (type) {
                    case DROP, CLICK if (dragging): dragging = false;
                    case ENTER, EXIT, MOVE if (dragging): glideTextToPos(dragStartPos + (dragStartY - y) * (numRows - 1));
                    case MOUSE_DOWN if (id <= 0): 
                        dragging = true;
                        dragStartY = y;
                        dragStartPos = currentScrollPos;
                    
                    case ENTER if (showScrollBar): scrollBarVisible = true;
                    case EXIT if (showScrollBar): scrollBarVisible = false;

                    case _:
                }
            case _:
        }

        uiMediator.receiveInteraction(id, interaction);
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

    function recalculateGeometry():Void {
        if (sized) {
            numRows = Std.int(viewPixelHeight / glyphHeightInPixels) + 1;
            numCols = Std.int(viewPixelWidth  / glyphWidthInPixels );
            numTextCols = numCols + (showScrollBar ? -1 : 0);

            growTo(numRows * numTextCols + 2 + 1);

            for (ike in numRows * numTextCols...numGlyphs) glyphs[ike].reset();

            caretGlyph = glyphs[numGlyphs - 1];

            if (showScrollBar) {
                scrollerTrackGlyph = glyphs[numRows * numTextCols];
                scrollerThumbGlyph = glyphs[numRows * numTextCols + 1];

                scrollerTrackGlyph.set_rgb(1, 1, 1);
                scrollerTrackGlyph.set_i(0.1);
                scrollerTrackGlyph.set_paint(bodyPaint);
                scrollerTrackGlyph.set_s(numRows);
                scrollerTrackGlyph.set_h(0.95 / numRows);

                scrollerThumbGlyph.set_rgb(1, 1, 1);
                scrollerThumbGlyph.set_i(1);
                scrollerThumbGlyph.set_paint(bodyPaint);
            } else {
                scrollerTrackGlyph = null;
                scrollerThumbGlyph = null;
            }

            lastRedrawPos = Math.NaN;
            reorderGlyphs();
            updateScroller();

            uiMediator.adjustLayout(numRows, numTextCols);
            uiMediator.styleCaret(caretGlyph, glyphTexture.font);
        }
    }

    inline function reorderGlyphs():Void {
        var id:Int = 0;
        for (row in 0...numRows) {
            var y:Float = (row + 0.5 - (numRows - 1) / 2) * glyphHeight / camera.rect.height;
            for (col in 0...numTextCols) {
                var x:Float = (col + 0.5 - numCols / 2) * glyphWidth / camera.rect.width;
                glyphs[id].set_xyz(x, y, 0);
                id++;
            }
        }
    }

    inline function updateScroller():Void {
        if (showScrollBar) {

            var thumbHeight:Float = numRows / (numRows + uiMediator.bottomPos());

            if (thumbHeight >= 1) {
                scrollerTrackGlyph.set_rgb(0, 0, 0);
                scrollerThumbGlyph.set_rgb(0, 0, 0);
            } else {
                scrollerTrackGlyph.set_rgb(1, 1, 1);
                scrollerThumbGlyph.set_rgb(1, 1, 1);
            }

            var thumbY:Float = (currentScrollPos / uiMediator.bottomPos() - 0.5) * (1 - thumbHeight);
            if (Math.isNaN(thumbY)) thumbY = 0;

            scrollerThumbGlyph.set_s(thumbHeight * numRows);
            scrollerThumbGlyph.set_h(0.65 / (thumbHeight * numRows));
            
            var scrollX:Float = ((numTextCols + 0.5) / numCols - 0.5);
            scrollerTrackGlyph.set_xyz(scrollX, scrollY, 0);
            scrollerThumbGlyph.set_xyz(scrollX, scrollY + thumbY, 0);
        }
    }

    inline function setScrollPos(pos:Float):Void {
        currentScrollPos = pos;
        var scrollStartIndex:Int = Std.int(currentScrollPos);
        caretGlyphID = uiMediator.stylePage(scrollStartIndex, glyphs, caretGlyph, glyphTexture.font);
        findAndPositionCaret();
        taperScrollEdges();
        scrollY = (currentScrollPos - scrollStartIndex) / (numRows - 1);
        transform.identity();
        transform.append(baseTransform);
        transform.appendTranslation(0, scrollY, 0);
        updateScroller();
    }

    inline function taperScrollEdges():Void {
        var offset:Float = ((currentScrollPos % 1) + 1) % 1;
        var lastRow:Int = (numRows - 1) * numTextCols;
        var glyph:Glyph;
        for (col in 0...numTextCols) {
            glyph = glyphs[col];
            glyph.set_color(Colors.mult(glyph.get_color(), 1 - offset));
            if (glyph == caretGlyphGuide) caretGlyph.set_color(Colors.mult(caretGlyph.get_color(), 1 - offset));

            glyph = glyphs[lastRow + col];
            glyph.set_color(Colors.mult(glyph.get_color(), offset));
            if (glyph == caretGlyphGuide) caretGlyph.set_color(Colors.mult(caretGlyph.get_color(), offset));
        }
    }

    inline function updateGlide(delta:Float):Void {
        if (gliding) {
            gliding = Math.abs(glideGoal - currentScrollPos) > 0.001;
            if (gliding) {
                delta *= 40;
                var nextScrollPos:Float = currentScrollPos * glideEase + glideGoal * (1 - glideEase);
                setScrollPos(nextScrollPos * delta + currentScrollPos * (1 - delta));
            } else {
                setScrollPos(glideGoal);
                if (lastRedrawPos != glideGoal) {
                    lastRedrawPos = glideGoal;
                    redrawHitSignal.dispatch();
                }
            }
        }
    }

    inline function updateScrollFade(delta:Float):Void {
        var changed:Bool = false;
        var scrollBarFadeGoal:Float = 0;
        if (scrollBarVisible && scrollBarFade < 1) {
            scrollBarFadeGoal = 1;
            changed = true;
        } else if (!scrollBarVisible && scrollBarFade > 0) {
            scrollBarFadeGoal = 0;
            changed = true;
        }

        if (changed) {
            delta *= 10;
            scrollBarFade = scrollBarFade * (1 - delta) + scrollBarFadeGoal * delta;
            scrollerTrackGlyph.set_rgb(scrollBarFade, scrollBarFade, scrollBarFade);
            scrollerThumbGlyph.set_rgb(scrollBarFade, scrollBarFade, scrollBarFade);
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

    inline function set_showScrollBar(val:Bool):Bool {
        showScrollBar = val;
        recalculateGeometry();
        return val;
    }
}
