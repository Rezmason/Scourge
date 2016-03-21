package net.rezmason.hypertype.ui;

import lime.math.Rectangle;
import lime.math.Matrix4;

import net.rezmason.hypertype.core.Body;
import net.rezmason.hypertype.core.CameraScaleMode;
import net.rezmason.hypertype.core.Glyph;
import net.rezmason.hypertype.core.GlyphFont;
import net.rezmason.hypertype.core.Interaction;
import net.rezmason.hypertype.core.Scene;

using net.rezmason.hypertype.core.GlyphUtils;

class UIElement {

    inline static var glideEase:Float = 0.6;
    inline static var NATIVE_DPI:Float = 96;
    inline static var DEFAULT_GLYPH_HEIGHT_IN_POINTS:Float = 18;
    static var UNIT_RECT:Rectangle = new Rectangle(0, 0, 1, 1);
    
    public var body(default, null):Body;
    public var scene(default, null):Scene;

    var spaceCode:Int;

    var glyphHeightInPoints:Float;
    var glyphWidthInPixels:Float;
    var glyphHeightInPixels:Float;
    var glyphWidth:Float;
    var glyphHeight:Float;
    var baseTransform:Matrix4;

    var viewPixelWidth:Float;
    var viewPixelHeight:Float;

    var currentScrollPos:Float;
    var scrollY:Float;
    var scrollBarX:Float;
    var glideGoal:Float;
    var gliding:Bool;
    var lastRedrawPos:Float;

    var caretGlyph:Glyph;
    var caretGlyphID:Int;
    var caretGlyphGuide:Glyph;
    
    var dragBehavior:DragBehavior;
    var dragStartPos:Float;

    var numRows:Int;
    var numCols:Int;
    var numTextCols:Int;

    var uiMediator:UIMediator;

    public var hasScrollBar(default, set):Bool;
    var scrollBar:UIScrollBar;

    public function new(uiMediator:UIMediator):Void {
        this.uiMediator = uiMediator;
        scene = new Scene();
        scene.camera.scaleMode = EXACT_FIT;
        scene.resizeSignal.add(resize);
        viewPixelWidth = 0;
        viewPixelHeight = 0;
        body = new Body();
        scene.root.addChild(body);
        body.interactionSignal.add(receiveInteraction);
        body.updateSignal.add(update);
        scrollBar = null;
        hasScrollBar = false;
        dragBehavior = new DragBehavior();
        
        spaceCode = ' '.charCodeAt(0);

        baseTransform = new Matrix4();
        baseTransform.appendScale(1, -1, 1);

        glyphHeightInPoints = DEFAULT_GLYPH_HEIGHT_IN_POINTS;
        glyphHeightInPixels = glyphHeightInPoints * getScreenDPI() / NATIVE_DPI;
        glyphWidthInPixels = glyphHeightInPixels / body.font.glyphRatio;

        currentScrollPos = Math.NaN;
        scrollY = 0;
        scrollBarX = 0;
        gliding = false;

        numRows = 0;
        numCols = 0;
        numTextCols = 0;
    }

    public function setFontSize(size:Float):Bool {
        var worked:Bool = false;
        if (!Math.isNaN(size) && size >= 14 && size <= 72) {
            worked = true;
            glyphHeightInPoints = size;
            glyphHeightInPixels = glyphHeightInPoints * getScreenDPI() / NATIVE_DPI;
            recalculateGeometry();
        }
        return worked;
    }

    public function setLayout(x:Float, y:Float, width:Float, height:Float):Bool {
        var worked = false;
        var rect = new Rectangle(x, y, width, height);
        if (UNIT_RECT.containsRect(rect) && rect.width * rect.height > 0) {
            scene.camera.rect = rect;
            resize();
            worked = true;
        }
        return worked;
    }

    public function setFont(font:GlyphFont):Bool {
        var worked:Bool = false;
        if (font != null) {
            worked = true;
            body.font = font;
            recalculateGeometry();
        }
        return worked;
    }

    function update(delta:Float):Void {

        if (dragBehavior.active) {
            dragBehavior.update(delta);
            glideTextToPos(dragStartPos - dragBehavior.displacement.y * (numRows - 1));
        } else if (uiMediator.isDirty) {
            uiMediator.updateDirtyText();
            if (Math.isNaN(currentScrollPos)) setScrollPos(uiMediator.bottomPos());
            glideTextToPos(uiMediator.bottomPos());
            scene.redrawHitSignal.dispatch();
        }

        updateGlide(delta);
        uiMediator.updateSpans(delta, dragBehavior.active);
        findAndPositionCaret();
        taperScrollEdges();
        if (hasScrollBar) scrollBar.updateFade(delta);
    }

    function resize():Void {
        viewPixelHeight = scene.camera.rect.height * scene.stageHeight;
        viewPixelWidth  = scene.camera.rect.width  * scene.stageWidth;
        recalculateGeometry();
    }

    function glideTextToPos(pos:Float):Void {
        gliding = true;
        // glideGoal = Math.round(Math.max(0, Math.min(uiMediator.bottomPos(), pos)));
        glideGoal = Math.max(0, Math.min(uiMediator.bottomPos(), pos));
    }

    function receiveInteraction(id:Int, interaction:Interaction):Void {

        switch (interaction) {
            case MOUSE(type, x, y):
                switch (type) {
                    case DROP, CLICK if (dragBehavior.dragging): dragBehavior.stopDrag();
                    case ENTER, EXIT, MOVE if (dragBehavior.dragging): 
                        dragBehavior.updateDrag(x, y);
                        glideTextToPos(dragStartPos - dragBehavior.displacement.y * (numRows - 1));
                    case MOUSE_DOWN if (id <= 0): 
                        dragBehavior.startDrag(x, y);
                        dragStartPos = currentScrollPos;
                    case ENTER if (hasScrollBar): scrollBar.visible = true;
                    case EXIT if (hasScrollBar): scrollBar.visible = false;

                    case _:
                }
            case _:
        }

        uiMediator.receiveInteraction(id, interaction);
    }

    inline function findAndPositionCaret():Void {
        caretGlyphGuide = null;

        if (caretGlyphID != -1) {
            var leftGlyph:Glyph = body.getGlyphByID(caretGlyphID - 1);
            var rightGlyph:Glyph = body.getGlyphByID(caretGlyphID);

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
        if (viewPixelWidth == 0 || viewPixelHeight == 0) return;

        glyphWidthInPixels = glyphHeightInPixels / body.font.glyphRatio;
        glyphWidth = glyphWidthInPixels / viewPixelWidth * scene.camera.rect.width;
        glyphHeight = glyphHeightInPixels / viewPixelHeight * scene.camera.rect.height;
        
        body.glyphScale = glyphWidth;
        
        numRows = Std.int(viewPixelHeight / glyphHeightInPixels) + 1;
        numCols = Std.int(viewPixelWidth  / glyphWidthInPixels );
        numTextCols = Std.int(Math.max(0, numCols + (hasScrollBar ? -1 : 0)));
        
        body.size = numRows * numTextCols + 2 + 1;
        for (ike in numRows * numTextCols...body.size) body.getGlyphByID(ike).reset();

        caretGlyph = body.getGlyphByID(body.size - 1);
        if (hasScrollBar) {
            scrollBar.setGlyphs(body.getGlyphByID(numRows * numTextCols), body.getGlyphByID(numRows * numTextCols + 1));
        }
        
        lastRedrawPos = Math.NaN;
        reorderGlyphs();
        updateScrollBarPosition();

        uiMediator.adjustLayout(numRows, numTextCols);
        uiMediator.styleCaret(caretGlyph);
    }

    inline function reorderGlyphs():Void {
        var id:Int = 0;
        for (row in 0...numRows) {
            var y:Float = (row + 0.5 - (numRows - 1) / 2) * glyphHeight / scene.camera.rect.height;
            for (col in 0...numTextCols) {
                var x:Float = (col + 0.5 - numCols / 2) * glyphWidth / scene.camera.rect.width;
                body.getGlyphByID(id).set_xyz(x, y, 0);
                id++;
            }
        }
    }

    inline function setScrollPos(pos:Float):Void {
        currentScrollPos = pos;
        var scrollStartIndex:Int = Std.int(currentScrollPos);
        caretGlyphID = uiMediator.stylePage(scrollStartIndex, body, caretGlyph);
        findAndPositionCaret();
        taperScrollEdges();
        scrollY = (currentScrollPos - scrollStartIndex) / (numRows - 1);
        scrollBarX = ((numTextCols + 0.5) / numCols - 0.5);
        body.transform.identity();
        body.transform.append(baseTransform);
        body.transform.appendTranslation(0, scrollY, 0);
        updateScrollBarPosition();
    }

    inline function updateScrollBarPosition():Void {
        if (hasScrollBar) {
            var thumbHeight:Float = numRows / (numRows + uiMediator.bottomPos());
            var thumbY:Float = (currentScrollPos / uiMediator.bottomPos() - 0.5) * (1 - thumbHeight);
            scrollBar.updatePosition(scrollBarX, scrollY, thumbY, thumbHeight * numRows, numRows);
        }
    }

    inline function taperScrollEdges():Void {
        var offset:Float = ((currentScrollPos % 1) + 1) % 1;
        var lastRow:Int = (numRows - 1) * numTextCols;
        var glyph:Glyph;
        for (col in 0...numTextCols) {
            glyph = body.getGlyphByID(col);
            glyph.mult_color(1 - offset);
            if (glyph == caretGlyphGuide) caretGlyph.mult_color(1 - offset);
            glyph = body.getGlyphByID(lastRow + col);
            glyph.mult_color(offset);
            if (glyph == caretGlyphGuide) caretGlyph.mult_color(offset);
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
                    scene.redrawHitSignal.dispatch();
                }
            }
        }
    }

    inline function getScreenDPI():Float {
        return NATIVE_DPI; // God damn it
    }

    inline function set_hasScrollBar(val:Bool):Bool {
        if (hasScrollBar != val) {
            hasScrollBar = val;
            scrollBar = val ? new UIScrollBar() : null;
            recalculateGeometry();
        }
        return val;
    }
}
