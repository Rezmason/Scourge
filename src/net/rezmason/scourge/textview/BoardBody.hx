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
import net.rezmason.ropes.GridLocus;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using net.rezmason.ropes.GridUtils;
using net.rezmason.utils.Pointers;
using net.rezmason.scourge.textview.core.GlyphUtils;

class NodeView {
    public var node:AspectSet;
    public var locus:BoardLocus;
    public var boardGlyphs:Array<Glyph>;
    public var uiGlyph:Glyph;
    public var x:Float;
    public var y:Float;
    public var z:Float;
    public var size:Float;
    public var curve:Float;
    public var lift:Float;
    public var isVisible:Bool;
    public var wiggleX:Float;
    public var wiggleY:Float;

    public var distance:Int;

    public function new():Void {
        x = y = z = curve = lift = size = distance = 0;
        isVisible = true;
        wiggleX = wiggleY = 0;
    }
}

class BoardBody extends Body {

    inline static var BOARD_GLYPHS_PER_NODE:Int = 2;

    static var TEAM_COLORS:Array<Color> = [0xFF0090, 0xFFC800, 0x30FF00, 0x00C0FF, 0xFF6000, 0xC000FF, 0x0030FF, 0x606060, ].map(Colors.fromHex);
    static var BOARD_COLOR:Color = Colors.fromHex(0x303030);
    static var WALL_COLOR:Color = Colors.fromHex(0x606060);
    static var BODY_CHARS:String = Strings.ALPHANUMERICS;

    /*
    var dragging:Bool;
    var dragX:Float;
    var dragY:Float;
    var dragStartTransform:Matrix3D;
    var rawTransform:Matrix3D;
    var homeTransform:Matrix3D;
    var plainTransform:Matrix3D;
    */

    var boardScale:Float;

    var boardCode:Int;
    var wallCode:Int;
    var bodyCode:Int;
    var headCode:Int;
    var uiCode:Int;
    var blankCode:Int;
    var fatCode:Int;

    var invalid:Bool;

    var numPlayers:Int;
    var game:Game;
    var nodeViews:Array<NodeView>;

    var ident_:AspectPtr;
    var occupier_:AspectPtr;
    var isFilled_:AspectPtr;
    var head_:AspectPtr;

    var headNodes:Array<AspectSet>;

    // wave pools - disabled
    // var wavePools:Array<WavePool>;

    public function new(bufferUtil:BufferUtil, glyphTexture:GlyphTexture):Void {

        super(bufferUtil, glyphTexture);

        /*
        dragging = false;
        dragStartTransform = new Matrix3D();
        rawTransform = new Matrix3D();
        homeTransform = new Matrix3D();
        plainTransform = new Matrix3D();
        */

        boardCode = Utf8.charCodeAt('¤', 0);
        wallCode = Utf8.charCodeAt('#', 0);
        bodyCode = Utf8.charCodeAt('•', 0);
        headCode = Utf8.charCodeAt('Ω', 0);
        uiCode = Utf8.charCodeAt('', 0);
        blankCode = Utf8.charCodeAt(' ', 0);
        fatCode = Utf8.charCodeAt('!', 0);

        boardScale = 1;

        nodeViews = [];
        // wave pools - disabled
        // wavePools = [];
        invalid = false;
    }

    public function attach(game:Game, numPlayers:Int):Void {

        detach();
        if (game == null) return;

        this.game = game;
        this.numPlayers = numPlayers;

        // wave pools - disabled
        /*
        for (ike in 0...numPlayers) {
            if (wavePools[ike] == null) {
                wavePools[ike] = new WavePool(1);
                wavePools[ike].addRipple(new Ripple(WaveFunctions.bolus, 1, 4., 0.5, 20));
            } else {
                wavePools[ike].size = 1;
            }
        }
        */

        ident_ = Ptr.intToPointer(0, game.state.key);
        occupier_ = game.plan.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        isFilled_ = game.plan.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        head_ = game.plan.playerAspectLookup[BodyAspect.HEAD.id];

        var nodes:Array<AspectSet> = game.state.nodes;
        var loci:Array<BoardLocus> = game.state.loci;

        growTo(nodes.length * (BOARD_GLYPHS_PER_NODE + 1));

        var minX:Float = 0;
        var maxX:Float = 0;
        var minY:Float = 0;
        var maxY:Float = 0;

        for (ike in 0...nodes.length) {

            var view:NodeView = nodeViews[ike];
            if (view == null) nodeViews[ike] = view = new NodeView();
            view.node = nodes[ike];
            view.locus = loci[ike];
            view.uiGlyph = glyphs[ike * 2 + 0];
            view.boardGlyphs = [];
            for (jen in 0...BOARD_GLYPHS_PER_NODE) view.boardGlyphs.push(glyphs[ike * 2 + 1 + jen]);

            for (direction in GridUtils.allDirections()) {
                var neighborLocus:BoardLocus = view.locus.neighbors[direction];
                var neighborView:NodeView = null;
                if (neighborLocus != null) neighborView = nodeViews[getID(neighborLocus.value)];

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
        /*
        homeTransform.identity();
        homeTransform.appendScale(boardScale, boardScale, boardScale);
        homeTransform.appendTranslation(0, 0, 0.5);
        */
        transform.identity();
        transform.appendScale(boardScale, boardScale, boardScale);
        transform.appendTranslation(0, 0, 0.5);

        for (view in nodeViews) {
            var x:Float = (view.x - centerX) * 0.065;
            var y:Float = (view.y - centerY) * 0.065;
            var z:Float = (x * x + y * y) * -0.2;

            view.x = x;
            view.y = y;
            view.z = z;
        }

        /*
        transform = rawTransform.clone();
        transform.append(homeTransform);
        */

        headNodes = [];
        invalidateBoard();
    }

    public function detach():Void {
        if (game == null) return;

        game = null;
        nodeViews = [];
        headNodes = null;
        for (glyph in glyphs) glyph.reset();
    }

    public function invalidateBoard(?cause:String):Void {
        // trace(cause);
        invalid = true;
    }

    private function updateBoard():Void {
        var itr:Int = 0;
        for (player in game.state.players) headNodes[itr++] = game.state.nodes[player[head_]];

        for (view in nodeViews) view.distance = -1;

        for (ike in 0...numPlayers) {

            var maxDistance:Int = 0;
            var node:AspectSet = headNodes[ike];

            if (node != null) {

                nodeViews[getID(node)].distance = -2;
                var pendingNodes:List<AspectSet> = new List<AspectSet>();

                while (node != null) {

                    var view:NodeView = nodeViews[getID(node)];
                    var distance:Int = view.distance;

                    if (maxDistance < distance) maxDistance = distance;

                    for (neighborLocus in view.locus.orthoNeighbors()) {
                        if (neighborLocus != null && neighborLocus.value[occupier_] == ike) {
                            var neighborView:NodeView = nodeViews[getID(neighborLocus.value)];
                            if (neighborView.distance == -1) {
                                neighborView.distance = distance + 2;
                                pendingNodes.add(neighborLocus.value);
                            }
                        }
                    }

                    for (neighborLocus in view.locus.diagNeighbors()) {
                        if (neighborLocus != null && neighborLocus.value[occupier_] == ike) {
                            var neighborView:NodeView = nodeViews[getID(neighborLocus.value)];
                            if (neighborView.distance == -1) {
                                neighborView.distance = distance + 3;
                                pendingNodes.add(neighborLocus.value);
                            }
                        }
                    }

                    node = pendingNodes.pop();
                }
            }

            // wave pools - disabled
            // wavePools[ike].size = maxDistance + 1;
        }

        var wallNodeViews:Array<NodeView> = [];
        var bodyNodeViews:Array<NodeView> = [];

        for (view in nodeViews) {

            var node:AspectSet = view.node;
            var locus:BoardLocus = view.locus;

            var playerID:Null<Int> = node[occupier_];
            var isFilled:Bool = node[isFilled_] == Aspect.TRUE;

            var hasPlayer:Bool = playerID != Aspect.NULL;

            view.curve = isFilled ? 0.96 : 1;

            if (isFilled) view.lift = -0.05;
            else if (hasPlayer) view.lift = -0.03;
            else view.lift = 0;

            var code:Int = uiCode;
            var size:Float = 1;
            var color:Color = Colors.white();
            var isVisible:Bool = true;
            var glow:Float = 0;
            var wiggleX:Float = 0;
            var wiggleY:Float = 0;

            if (view.distance < 0) view.distance = 0;

            if (isFilled) {
                if (hasPlayer) {
                    color = TEAM_COLORS[playerID % TEAM_COLORS.length];
                    glow = 0.15;
                    if (headNodes[playerID] == node) {
                        code = headCode;
                        size = 1.5;
                    } else {
                        code = bodyCode;
                        // code = BODY_CHARS.charCodeAt(Std.random(Utf8.length(BODY_CHARS)));
                        // code = BODY_CHARS.charCodeAt(view.distance % Utf8.length(BODY_CHARS));

                        var numNeighbors:Int = 0;
                        for (direction in GridUtils.allDirections()) {
                            var neighborLocus:BoardLocus = locus.neighbors[direction];
                            if (neighborLocus != null && neighborLocus.value[occupier_] == playerID) numNeighbors++;
                        }
                        size = (numNeighbors / 8) * 0.6 + 0.2;

                        bodyNodeViews.push(view);
                    }

                    wiggleX = view.wiggleX;
                    wiggleY = view.wiggleY;

                    // if (wiggleX == 0) wiggleX = (Math.random() * 2 - 1) * 0.01;
                    // if (wiggleY == 0) wiggleY = (Math.random() * 2 - 1) * 0.01;

                } else {
                    isVisible = false;
                    for (direction in GridUtils.allDirections()) {
                        var neighborLocus:BoardLocus = locus.neighbors[direction];
                        if (neighborLocus == null) continue;
                        if (neighborLocus.value[isFilled_] == Aspect.FALSE || neighborLocus.value[occupier_] != Aspect.NULL) {
                            isVisible = true;
                            break;
                        }
                    }

                    code = wallCode;
                    color = WALL_COLOR;
                    size = 0;
                    if (isVisible) wallNodeViews.push(view);
                }
            } else if (hasPlayer) {
                color = Colors.mult(TEAM_COLORS[playerID % TEAM_COLORS.length], 0.6);
                glow = 0.05;
                code = boardCode;
                size = 0.5;
            } else {
                color = BOARD_COLOR;
                code = boardCode;
                size = 0.5;
            }

            view.size = size;
            view.wiggleX = wiggleX;
            view.wiggleY = wiggleY;

            var z:Float = view.z;

            for (glyph in view.boardGlyphs) {
                glyph.set_color(color);
                glyph.set_f(0.5 + glow);
                glyph.set_x(view.x * view.curve + view.wiggleX);
                glyph.set_y(view.y * view.curve + view.wiggleX);
                glyph.set_z(z + view.lift);
                glyph.set_s(size);
                glyph.set_char(code, glyphTexture.font);

                z += 0.04;
                color = Colors.mult(color, code == wallCode ? 0.5 : 0.1);
            }
            view.isVisible = isVisible;
        }

        for (view in wallNodeViews) {
            var itr:Int = 0;
            var flag:Int = 0;
            for (neighborLocus in view.locus.orthoNeighbors()) {
                var neighborNode:AspectSet = null;
                if (neighborLocus != null) neighborNode = neighborLocus.value;
                var val:Int =
                    neighborLocus != null &&
                    nodeViews[getID(neighborNode)].isVisible &&
                    neighborNode[isFilled_] == Aspect.TRUE &&
                    neighborNode[occupier_] == Aspect.NULL
                    ? 1 : 0;
                flag = flag | (val << itr);
                itr++;
            }

            var code:Int = Utf8.charCodeAt(Strings.BOX_SYMBOLS, flag);

            for (glyph in view.boardGlyphs) {
                glyph.set_s(0.7);
                glyph.set_char(code, glyphTexture.font);
            }
        }

        /*
        for (view in bodyNodeViews) {
            var itr:Int = 0;
            var flag:Int = 0;
            var playerID:Null<Int> = view.node[occupier_];
            for (neighborLocus in view.locus.orthoNeighbors()) {
                var neighborNode:AspectSet = null;
                if (neighborLocus != null) neighborNode = neighborLocus.value;
                var val:Int =
                    neighborLocus != null &&
                    nodeViews[getID(neighborNode)].isVisible &&
                    neighborNode[isFilled_] == Aspect.TRUE &&
                    neighborNode[occupier_] == playerID
                    ? 1 : 0;
                flag = flag | (val << itr);
                itr++;
            }

            var code:Int = Utf8.charCodeAt(Strings.BODY_GLYPHS, flag);
            if (code == fatCode) code = BODY_CHARS.charCodeAt(view.distance % Utf8.length(BODY_CHARS));

            for (glyph in view.boardGlyphs) {
                glyph.set_char(code, glyphTexture.font);
            }
        }
        */
    }

    public function handleUIUpdate():Void {
        // Interpret info from UI

    }

    override public function adjustLayout(stageWidth:Int, stageHeight:Int):Void {
        super.adjustLayout(stageWidth, stageHeight);

        var screenSize:Float = Math.sqrt(stageWidth * stageWidth + stageHeight * stageHeight);
        var rectSize:Float = Math.min(viewRect.width * stageWidth, viewRect.height * stageHeight) / screenSize;

        var glyphWidth:Float = rectSize * 0.1 * boardScale;
        var glyphScreenRatio:Float = glyphTexture.font.glyphRatio * stageWidth / stageHeight;
        setGlyphScale(glyphWidth, glyphWidth * glyphScreenRatio);
    }

    override public function update(delta:Float):Void {
        /*
        if (!dragging) {
            rawTransform.interpolateTo(plainTransform, 0.1);
            transform.copyFrom(rawTransform);
            transform.append(homeTransform);
        }
        */

        if (invalid) {
            updateBoard();
            invalid = false;
        }

        // wave pools - disabled
        /*
        for (pool in wavePools) pool.update(delta);
        for (view in nodeViews) {
            var playerID:Int = view.node[occupier_];
            if (playerID != Aspect.NULL && view.node[isFilled_] == Aspect.TRUE) {
                var h:Float = wavePools[playerID].getHeightAtIndex(view.distance);
                // view.boardGlyph.set_p(h * 0.08);

                var z:Float = view.z;
                var s:Float = view.size - h * 0.2;

                for (glyph in view.boardGlyphs) {
                    glyph.set_x(view.x * view.curve + view.wiggleX * (1 + h * 2));
                    glyph.set_y(view.y * view.curve + view.wiggleY * (1 + h * 2));
                    glyph.set_z(z + view.lift + h * 0.05);
                    glyph.set_s(s);
                    glyph.set_f(0.5 - h * 0.2);

                    z += 0.04;
                    s *= 2;
                }

            }
        }
        */

        super.update(delta);
    }

    override public function receiveInteraction(id:Int, interaction:Interaction):Void {
        var glyph:Glyph = glyphs[id];
        switch (interaction) {
            case MOUSE(type, x, y):
                switch (type) {
                    case MOUSE_DOWN: //startDrag(x, y);
                    case MOUSE_UP, DROP: //stopDrag();
                    case MOVE, ENTER, EXIT: //if (dragging) updateDrag(x, y);
                    case _:
                }
            case _:
        }
    }

    /*
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
    */

    inline function getID(node:AspectSet):Int {
        return node[ident_];
    }
}
