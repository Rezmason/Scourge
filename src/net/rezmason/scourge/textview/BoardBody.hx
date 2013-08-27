package net.rezmason.scourge.textview;

import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.geom.Vector3D;

import net.rezmason.gl.utils.BufferUtil;

import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.core.GlyphTexture;

import net.rezmason.ropes.Types;
import net.rezmason.ropes.GridNode;
import net.rezmason.scourge.model.Game;

using net.rezmason.ropes.GridUtils;
using net.rezmason.scourge.textview.core.GlyphUtils;

class NodeView {
    public var node:BoardNode;
    public var boardGlyph:Glyph;
    public var bodyGlyph:Glyph;
    public var uiGlyph:Glyph;
    public var x:Float;
    public var y:Float;

    public function new():Void x = y = 0;
}

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
    var plainTransform:Matrix3D;

    var game:Game;
    var nodeViews:Array<NodeView>;
    var nodeViewsByNode:Map<BoardNode, NodeView>;

    public function new(bufferUtil:BufferUtil, glyphTexture:GlyphTexture, redrawHitAreas:Void->Void, game:Game):Void {

        this.game = game;
        // Create a node view for each node
            // for now, base x and y positions on neighborness
        // Find center and nudge everybody in that direction

        var nodes:Array<BoardNode> = game.state.nodes;

        super(bufferUtil, nodes.length * 3, glyphTexture, redrawHitAreas);

        nodeViews = [];

        dragging = false;
        dragStartTransform = new Matrix3D();
        rawTransform = new Matrix3D();
        homeTransform = new Matrix3D();
        homeTransform.appendTranslation(0, 0, 0.5);
        plainTransform = new Matrix3D();

        transform = rawTransform.clone();
        transform.append(homeTransform);

        var boardCode:Int = '¤'.charCodeAt(0);
        var bodyCode:Int  = '•'.charCodeAt(0);
        var uiCode:Int    = ''.charCodeAt(0);
        var bodyCodes:String = TestStrings.ALPHANUMERICS;

        var blankCode:Int    = ' '.charCodeAt(0);

        nodeViewsByNode = new Map();

        var DIST:Float = 0.06;

        var minX:Float = 0;
        var maxX:Float = 0;
        var minY:Float = 0;
        var maxY:Float = 0;

        for (ike in 0...nodes.length) {

            var view:NodeView = new NodeView();
            nodeViews.push(view);
            view.node = nodes[ike];
            view.boardGlyph = glyphs[ike * 3 + 0];
            view.bodyGlyph  = glyphs[ike * 3 + 1];
            view.uiGlyph    = glyphs[ike * 3 + 2];

            nodeViewsByNode[view.node] = view;

            for (direction in GridUtils.allDirections()) {
                var neighborView:NodeView = nodeViewsByNode[view.node.neighbors[direction]];
                if (neighborView != null) {

                    var x:Float = neighborView.x;
                    var y:Float = neighborView.y;

                    if ((direction + 1) % 8 < 3) y -= DIST;
                    if ((direction + 3) % 8 < 3) x += DIST;
                    if ((direction + 5) % 8 < 3) y += DIST;
                    if ((direction + 7) % 8 < 3) x -= DIST;

                    if (minX > x) minX = x;
                    if (maxX < x) maxX = x;
                    if (minY > y) minY = y;
                    if (maxY < y) maxY = y;

                    view.x = x;
                    view.y = y;

                    break;
                }
            }

            bodyCode = bodyCodes.charCodeAt(Std.random(bodyCodes.length));

            view.bodyGlyph.set_char(bodyCode, glyphTexture.font);
            view.boardGlyph.set_char(boardCode, glyphTexture.font);

            if (Std.random(2) == 0) {
                var randColor:Int = TEAM_COLORS[Std.random(TEAM_COLORS.length)];
                var red:Float   = (randColor >> 16 & 0xFF) / 0xFF;
                var green:Float = (randColor >> 8  & 0xFF) / 0xFF;
                var blue:Float  = (randColor >> 0  & 0xFF) / 0xFF;

                view.bodyGlyph.set_color(red, green, blue);
                view.boardGlyph.set_color(0, 0, 0);
            } else {
                view.bodyGlyph.set_color(0, 0, 0);
                view.boardGlyph.set_color(0.2, 0.2, 0.2);
            }

            view.uiGlyph.set_char(uiCode, glyphTexture.font);
            view.uiGlyph.set_paint(view.uiGlyph.id | id << 16);


            if (Std.random(10) != 0) view.uiGlyph.set_color(0, 0, 0);
        }

        var centerX:Float = (minX + maxX) * 0.5;
        var centerY:Float = (minY + maxY) * 0.5;

        for (view in nodeViews) {
            var x:Float = view.x - centerX;
            var y:Float = view.y - centerY;
            var z:Float = (x * x + y * y) * -0.2;

            view.x = x;
            view.y = y;

            view.boardGlyph.set_pos(x, y, z - 0.00);
            view.bodyGlyph .set_pos(x, y, z - 0.05);
            view.uiGlyph.set_shape(x, y, z - 0.08, 1.2, 0);
        }
    }

    override public function adjustLayout(stageWidth:Int, stageHeight:Int):Void {
        super.adjustLayout(stageWidth, stageHeight);

        var rect:Rectangle = sanitizeLayoutRect(stageWidth, stageHeight, viewRect);

        var screenSize:Float = Math.sqrt(stageWidth * stageWidth + stageHeight * stageHeight);
        var rectSize:Float = Math.min(rect.width * stageWidth, rect.height * stageHeight) / screenSize;
        var glyphWidth:Float = rectSize * 0.1;
        setGlyphScale(glyphWidth, glyphWidth * glyphTexture.font.glyphRatio * stageWidth / stageHeight);
    }

    override public function update(delta:Float):Void {
        if (!dragging) {
            rawTransform.interpolateTo(plainTransform, 0.1);
            transform.copyFrom(rawTransform);
            transform.append(homeTransform);
        }
        super.update(delta);
    }

    override public function interact(id:Int, interaction:Interaction):Void {
        var glyph:Glyph = glyphs[id];
        switch (interaction) {
            case MOUSE(type, x, y):
                switch (type) {
                    case MOUSE_DOWN: startDrag(x, y);
                    case MOUSE_UP, DROP: stopDrag();
                    case MOVE, ENTER, EXIT: if (dragging) updateDrag(x, y);
                    case _:
                }
            case _:
        }
    }

    inline function startDrag(x:Float, y:Float):Void {
        dragging = true;
        dragStartTransform.copyFrom(rawTransform);
        dragX = x;
        dragY = y;
    }

    inline static var MAG:Float = 10;

    inline function updateDrag(x:Float, y:Float):Void {
        rawTransform.copyFrom(dragStartTransform);

        var dirX:Float = dragX > x ? 1 : -1;
        var dirY:Float = dragY > y ? 1 : -1;

        x = (dragX - x) * dirX;
        y = (dragY - y) * dirY;

        x = Math.sqrt(x * MAG) / MAG;
        y = Math.sqrt(y * MAG) / MAG;

        // TODO: -kx

        rawTransform.appendRotation(x * dirX * 180, Vector3D.Y_AXIS);
        rawTransform.appendRotation(y * dirY * 180, Vector3D.X_AXIS);
        transform.copyFrom(rawTransform);
        transform.append(homeTransform);
    }

    inline function stopDrag():Void {
        dragging = false;
    }
}
