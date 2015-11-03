package net.rezmason.scourge.textview.ui;

import lime.math.Rectangle;
import net.rezmason.gl.GLTypes;

import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.CameraScaleMode;
import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.core.Scene;

using net.rezmason.scourge.textview.core.GlyphUtils;

class UIElement {

    inline static var glideEase:Float = 0.6;
    inline static var NATIVE_DPI:Float = 96;
    inline static var DEFAULT_GLYPH_HEIGHT_IN_POINTS:Float = 18;
    inline static var POST_DRAG_FRICTION:Float = 0.925;
    inline static var POST_DRAG_MIN_VY:Float = 0.0001;

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
    
    var dragging:Bool;
    var postDragging:Bool;
    var dragStartY:Float;
    var dragLastY:Float;
    var dragY:Float;
    var dragPostVY:Float;
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
        dragging = false;
        postDragging = false;
        
        spaceCode = ' '.charCodeAt(0);

        baseTransform = new Matrix4();
        baseTransform.appendScale(1, -1, 1);

        glyphHeightInPoints = DEFAULT_GLYPH_HEIGHT_IN_POINTS;
        glyphHeightInPixels = glyphHeightInPoints * getScreenDPI() / NATIVE_DPI;
        glyphWidthInPixels = glyphHeightInPixels / body.glyphTexture.font.glyphRatio;

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
        if (x >= 0 && x <= 1 && y >= 0 && y <= 1 && width >= 0 && width <= 1 && height >= 0 && height <= 1) {
            scene.camera.rect = new Rectangle(x, y, width, height);
            resize();
        }
        return worked;
    }

    public function setFontTexture(tex:GlyphTexture):Bool {
        var worked:Bool = false;
        if (tex != null) {
            worked = true;
            body.glyphTexture = tex;
            recalculateGeometry();
        }
        return worked;
    }

    function update(delta:Float):Void {

        if (!(dragging || postDragging) && uiMediator.isDirty) {
            uiMediator.updateDirtyText();
            if (Math.isNaN(currentScrollPos)) setScrollPos(uiMediator.bottomPos());
            glideTextToPos(uiMediator.bottomPos());
            scene.redrawHitSignal.dispatch();
        }

        if (dragging) {
            dragLastY = dragY;
        } else if (postDragging) {
            dragY += dragPostVY;
            postDragging = Math.abs(dragPostVY) > POST_DRAG_MIN_VY;
            glideTextToPos(dragStartPos + (dragStartY - dragY) * (numRows - 1));
            dragPostVY *= POST_DRAG_FRICTION;
        }

        updateGlide(delta);
        uiMediator.updateSpans(delta, dragging || postDragging);
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
                    case DROP, CLICK if (dragging): 
                        dragging = false;
                        dragPostVY = dragY - dragLastY;
                        postDragging = dragPostVY != 0;
                    case ENTER, EXIT, MOVE if (dragging): 
                        dragY = y;
                        glideTextToPos(dragStartPos + (dragStartY - y) * (numRows - 1));
                    case MOUSE_DOWN if (id <= 0): 
                        dragging = true;
                        postDragging = false;
                        dragStartY = y;
                        dragLastY = dragStartY;
                        dragY = y;
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

        glyphWidthInPixels = glyphHeightInPixels / body.glyphTexture.font.glyphRatio;
        glyphWidth = glyphWidthInPixels / viewPixelWidth * scene.camera.rect.width;
        glyphHeight = glyphHeightInPixels / viewPixelHeight * scene.camera.rect.height;
        
        body.glyphScale = glyphWidth;
        
        numRows = Std.int(viewPixelHeight / glyphHeightInPixels) + 1;
        numCols = Std.int(viewPixelWidth  / glyphWidthInPixels );
        numTextCols = Std.int(Math.max(0, numCols + (hasScrollBar ? -1 : 0)));
        
        body.growTo(numRows * numTextCols + 2 + 1);
        for (ike in numRows * numTextCols...body.numGlyphs) body.getGlyphByID(ike).reset();

        caretGlyph = body.getGlyphByID(body.numGlyphs - 1);
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
            glyph.set_color(glyph.get_color() * (1 - offset));
            if (glyph == caretGlyphGuide) caretGlyph.set_color(caretGlyph.get_color() * (1 - offset));

            glyph = body.getGlyphByID(lastRow + col);
            glyph.set_color(glyph.get_color() * offset);
            if (glyph == caretGlyphGuide) caretGlyph.set_color(caretGlyph.get_color() * offset);
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
        #if flash
            var dpi:Null<Float> = Reflect.field(flash.Lib.current.loaderInfo.parameters, 'dpi');
            if (dpi == null) dpi = NATIVE_DPI;
            return dpi;
        #else
            return NATIVE_DPI; // God damn it
        #end
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
