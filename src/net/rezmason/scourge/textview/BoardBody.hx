package net.rezmason.scourge.textview;

import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.geom.Vector3D;

import haxe.Utf8;

import net.rezmason.gl.utils.BufferUtil;

import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.core.GlyphTexture;

import net.rezmason.scourge.textview.waves.WavePool;
import net.rezmason.scourge.textview.waves.Ripple;
import net.rezmason.scourge.textview.waves.WaveFunctions;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.Types;
import net.rezmason.ropes.GridNode;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using net.rezmason.ropes.GridUtils;
using net.rezmason.scourge.textview.core.GlyphUtils;

class NodeView {
    public var node:BoardNode;
    public var boardGlyph:Glyph;
    public var uiGlyph:Glyph;
    public var x:Float;
    public var y:Float;
    public var z:Float;
    public var size:Float;
    public var curve:Float;
    public var lift:Float;
    public var isVisible:Bool;

    public var distance:Int;

    public function new():Void {
        x = y = z = curve = lift = size = distance = 0;
        isVisible = true;
    }
}

class BoardBody extends Body {

    inline static var COLOR_RANGE:Int = 6;

    static var TEAM_COLORS:Array<Int> = [0xFF0090, 0xFFC800, 0x30FF00, 0x00C0FF, 0xFF6000, 0xC000FF, 0x0030FF, 0x606060, ];
    static var BOARD_COLOR:Int = 0x303030;
    static var WALL_COLOR:Int = 0x606060;
    static var BODY_CHARS:String = TestStrings.ALPHANUMERICS;

    var dragging:Bool;
    var dragX:Float;
    var dragY:Float;
    var dragStartTransform:Matrix3D;
    var rawTransform:Matrix3D;
    var homeTransform:Matrix3D;
    var plainTransform:Matrix3D;

    var boardScale:Float;

    var boardCode:Int;
    var wallCode:Int;
    var bodyCode:Int;
    var headCode:Int;
    var uiCode:Int;
    var blankCode:Int;

    var numPlayers:Int;
    var game:Game;
    var nodeViews:Array<NodeView>;
    var nodeViewsByNode:Map<BoardNode, NodeView>;

    var occupier_:AspectPtr;
    var isFilled_:AspectPtr;
    var head_:AspectPtr;

    var headNodes:Array<BoardNode>;

    var wavePools:Array<WavePool>;

    public function new(bufferUtil:BufferUtil, glyphTexture:GlyphTexture, redrawHitAreas:Void->Void):Void {

        super(bufferUtil, glyphTexture, redrawHitAreas);

        dragging = false;
        dragStartTransform = new Matrix3D();
        rawTransform = new Matrix3D();
        homeTransform = new Matrix3D();
        plainTransform = new Matrix3D();

        boardCode = Utf8.charCodeAt('¤', 0);
        wallCode = Utf8.charCodeAt('#', 0);
        bodyCode = Utf8.charCodeAt('•', 0);
        headCode = Utf8.charCodeAt('Ω', 0);
        uiCode = Utf8.charCodeAt('', 0);
        blankCode = Utf8.charCodeAt(' ', 0);

        boardScale = 1;

        nodeViews = [];
        wavePools = [];
    }

    public function attach(game:Game, numPlayers:Int):Void {

        if (this.game != game) detach();
        if (game == null) return;

        this.game = game;
        this.numPlayers = numPlayers;

        for (ike in 0...numPlayers) {
            if (wavePools[ike] == null) {
                wavePools[ike] = new WavePool(1);
                wavePools[ike].addRipple(new Ripple(WaveFunctions.bolus, 1, 4., 0.5, 20));
                wavePools[ike].addRipple(new Ripple(WaveFunctions.bolus, 0.5, 16., 0.5, 5));
            } else {
                wavePools[ike].size = 1;
            }
        }

        occupier_ = game.plan.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        isFilled_ = game.plan.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        head_ = game.plan.playerAspectLookup[BodyAspect.HEAD.id];

        var nodes:Array<BoardNode> = game.state.nodes;

        growTo(nodes.length * 2);

        nodeViewsByNode = new Map();

        var minX:Float = 0;
        var maxX:Float = 0;
        var minY:Float = 0;
        var maxY:Float = 0;

        for (ike in 0...nodes.length) {

            var view:NodeView = nodeViews[ike];
            if (view == null) nodeViews[ike] = view = new NodeView();
            view.node = nodes[ike];
            view.boardGlyph = glyphs[ike * 2 + 0];
            view.uiGlyph = glyphs[ike * 2 + 1];

            nodeViewsByNode[view.node] = view;

            for (direction in GridUtils.allDirections()) {
                var neighborNode:BoardNode = view.node.neighbors[direction];
                var neighborView:NodeView = null;
                if (neighborNode != null) neighborView = nodeViewsByNode[neighborNode];

                if (neighborView != null) {

                    var x:Float = neighborView.x;
                    var y:Float = neighborView.y;

                    if ((direction + 1) % 8 < 3) y -= 1;
                    if ((direction + 3) % 8 < 3) x += 1;
                    if ((direction + 5) % 8 < 3) y += 1;
                    if ((direction + 7) % 8 < 3) x -= 1;

                    if (minX > x) minX = x;
                    if (maxX < x) maxX = x;
                    if (minY > y) minY = y;
                    if (maxY < y) maxY = y;

                    view.x = x;
                    view.y = y;

                    break;
                }
            }
        }

        var centerX:Float = (minX + maxX) * 0.5;
        var centerY:Float = (minY + maxY) * 0.5;

        boardScale = 18 / (maxX - minX);
        homeTransform.identity();
        homeTransform.appendScale(boardScale, boardScale, boardScale);
        homeTransform.appendTranslation(0, 0, 0.5);

        for (view in nodeViews) {
            var x:Float = (view.x - centerX) * 0.065;
            var y:Float = (view.y - centerY) * 0.065;
            var z:Float = (x * x + y * y) * -0.2;

            view.x = x;
            view.y = y;
            view.z = z;
        }

        transform = rawTransform.clone();
        transform.append(homeTransform);

        headNodes = [];
        handleBoardUpdate();
    }

    public function detach():Void {
        if (game == null) return;

        game = null;
        nodeViews = [];

        for (key in nodeViewsByNode.keys()) nodeViewsByNode.remove(key);
        nodeViewsByNode = null;

        headNodes = null;
    }

    public function handleBoardUpdate():Void {
        var itr:Int = 0;
        for (player in game.state.players) headNodes[itr++] = game.state.nodes[player[head_]];

        for (view in nodeViews) view.distance = -1;

        for (ike in 0...numPlayers) {
            var pendingNodes:List<BoardNode> = new List<BoardNode>();

            var node:BoardNode = headNodes[ike];
            nodeViewsByNode[node].distance = 0;
            var maxDistance:Int = 0;

            while (node != null) {

                var distance:Int = nodeViewsByNode[node].distance;

                if (maxDistance < distance) maxDistance = distance;

                for (neighborNode in node.orthoNeighbors()) {
                    if (neighborNode != null && neighborNode.value[occupier_] == ike) {
                        var neighborView:NodeView = nodeViewsByNode[neighborNode];
                        if (neighborView.distance == -1) {
                            neighborView.distance = distance + 2;
                            pendingNodes.add(neighborNode);
                        }
                    }
                }

                for (neighborNode in node.diagNeighbors()) {
                    if (neighborNode != null && neighborNode.value[occupier_] == ike) {
                        var neighborView:NodeView = nodeViewsByNode[neighborNode];
                        if (neighborView.distance == -1) {
                            neighborView.distance = distance + 3;
                            pendingNodes.add(neighborNode);
                        }
                    }
                }

                node = pendingNodes.pop();
            }

            trace([ike, maxDistance + 1]);
            wavePools[ike].size = maxDistance + 1;
        }

        var wallNodeViews:Array<NodeView> = [];

        for (view in nodeViews) {

            var node:BoardNode = view.node;

            var playerID:Null<Int> = node.value[occupier_];
            var isFilled:Bool = node.value[isFilled_] == Aspect.TRUE;

            var hasPlayer:Bool = playerID != Aspect.NULL;

            view.curve = isFilled ? 0.96 : 1;
            view.lift = isFilled ? -0.05 : 0;

            var code:Int = blankCode;
            var size:Float = 1;
            var color:Int = 0xFFFFFF;
            var isVisible:Bool = true;

            if (isFilled) {
                if (hasPlayer) {
                    color = TEAM_COLORS[playerID % TEAM_COLORS.length];
                    if (headNodes[playerID] == node) {
                        code = headCode;
                        size = 1.2;
                    } else {
                        // code = bodyCode;
                        // code = BODY_CHARS.charCodeAt(Std.random(Utf8.length(BODY_CHARS)));
                        code = BODY_CHARS.charCodeAt(view.distance % Utf8.length(BODY_CHARS));
                        size = 1;
                    }
                } else {

                    isVisible = false;
                    for (direction in GridUtils.allDirections()) {
                        var neighborNode:BoardNode = node.neighbors[direction];
                        if (neighborNode == null) continue;
                        if (neighborNode.value[isFilled_] == Aspect.FALSE || neighborNode.value[occupier_] != Aspect.NULL) {
                            isVisible = true;
                            break;
                        }
                    }

                    code = wallCode;
                    color = WALL_COLOR;
                    size = 0;
                    if (isVisible) wallNodeViews.push(view);
                }
            } else {
                color = BOARD_COLOR;
                code = boardCode;
                size = 0.5;
            }

            view.size = size;
            colorGlyph(view.boardGlyph, color);
            view.boardGlyph.set_pos(view.x * view.curve, view.y * view.curve, view.z + view.lift);
            view.boardGlyph.set_s(size);
            view.boardGlyph.set_char(code, glyphTexture.font);
            view.isVisible = isVisible;
        }

        for (view in wallNodeViews) {
            var itr:Int = 0;
            var flag:Int = 0;
            for (neighborNode in view.node.orthoNeighbors()) {
                var val:Int =
                    neighborNode != null &&
                    nodeViewsByNode[neighborNode].isVisible &&
                    neighborNode.value[isFilled_] == Aspect.TRUE &&
                    neighborNode.value[occupier_] == Aspect.NULL
                    ? 1 : 0;
                flag = flag | (val << itr);
                itr++;
            }

            var code:Int = Utf8.charCodeAt(TestStrings.BOX_SYMBOLS, flag);

            view.boardGlyph.set_s(0.7);
            view.boardGlyph.set_char(code, glyphTexture.font);
        }
    }

    public function handleUIUpdate():Void {
        // Interpret info from UI

    }

    inline function colorGlyph(glyph:Glyph, color:Int):Void {
        glyph.set_color(
            (color >> 16 & 0xFF) / 0xFF,
            (color >> 8  & 0xFF) / 0xFF,
            (color >> 0  & 0xFF) / 0xFF
        );
    }

    override public function adjustLayout(stageWidth:Int, stageHeight:Int):Void {
        super.adjustLayout(stageWidth, stageHeight);

        var rect:Rectangle = sanitizeLayoutRect(stageWidth, stageHeight, viewRect);

        var screenSize:Float = Math.sqrt(stageWidth * stageWidth + stageHeight * stageHeight);
        var rectSize:Float = Math.min(rect.width * stageWidth, rect.height * stageHeight) / screenSize;

        var glyphWidth:Float = rectSize * 0.1 * boardScale;
        var glyphScreenRatio:Float = glyphTexture.font.glyphRatio * stageWidth / stageHeight;
        setGlyphScale(glyphWidth, glyphWidth * glyphScreenRatio);
    }

    override public function update(delta:Float):Void {
        if (!dragging) {
            rawTransform.interpolateTo(plainTransform, 0.1);
            transform.copyFrom(rawTransform);
            transform.append(homeTransform);
        }

        for (pool in wavePools) pool.update(delta);
        for (view in nodeViews) {
            var playerID:Int = view.node.value[occupier_];
            if (playerID != Aspect.NULL && view.node.value[isFilled_] == Aspect.TRUE) {
                var h:Float = wavePools[playerID].getHeightAtIndex(view.distance);
                // view.boardGlyph.set_p(h * 0.08);
                view.boardGlyph.set_z(view.z + view.lift + h * 0.05);
                view.boardGlyph.set_s(view.size - h * 0.2);
            }
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
