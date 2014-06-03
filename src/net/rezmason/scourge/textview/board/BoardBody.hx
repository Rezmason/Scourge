package net.rezmason.scourge.textview.board;

import haxe.Utf8;

import flash.geom.Matrix3D;
import flash.geom.Vector3D;

import net.rezmason.gl.utils.BufferUtil;
import net.rezmason.scourge.controller.ControllerTypes;
import net.rezmason.scourge.textview.board.BoardEffects;
import net.rezmason.scourge.textview.board.BoardTypes;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.core.GlyphTexture;

using net.rezmason.scourge.textview.core.GlyphUtils;

class BoardBody extends Body {

    inline static var GLYPHS_PER_NODE:Int = 3;
    inline static var BOARD_MAGNIFICATION:Float = 1.15;
    inline static var WALL_TOP_OFFSET:Float = -0.05;
    inline static var TOP_OFFSET:Float = -0.03;
    inline static var UI_OFFSET:Float = -0.06;
    static var TEAM_COLORS:Array<Color> = [0xFF0090, 0xFFC800, 0x30FF00, 0x00C0FF, 0xFF6000, 0xC000FF, 0x0030FF, 0x606060, ].map(Colors.fromHex);
    static var BOARD_COLOR:Color = Colors.fromHex(0x303030);
    static var WALL_COLOR:Color = Colors.fromHex(0x606060);
    static var UI_COLOR:Color = Colors.fromHex(0xFFFFFF);
    static var BODY_CHARS:String = Strings.ALPHANUMERICS;
    static var BLACK:Color = {r:0, g:0, b:0};
    static var durationsByCause:Map<String, Float> = makeDurationsByCause();
    static var overlapsByCause:Map<String, Float> = makeOverlapsByCause();

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
    var numNodes:Int;
    var nodeViews:Array<NodeView>;
    var nodeTweens:Array<NodeTween>;
    var numActiveTweens:Int;

    var animationTime:Float;
    var totalAnimationTime:Float;

    public function new(bufferUtil:BufferUtil, glyphTexture:GlyphTexture):Void {

        super(bufferUtil, glyphTexture);

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
        nodeTweens = [];
        animationTime = 0;
        totalAnimationTime = 0;
        numActiveTweens = 0;
    }

    public function presentStart(numPlayers:Int, nodePositions:Array<NodePosition>):Void {

        numNodes = nodePositions.length;
        growTo(numNodes * GLYPHS_PER_NODE);

        var minX:Float = 0;
        var maxX:Float = 0;

        for (ike in 0...numNodes) {
            var view:NodeView = nodeViews[ike];
            if (view == null) nodeViews[ike] = view = makeView();
            view.bottomGlyph = glyphs[ike * GLYPHS_PER_NODE + 0];
            view.topGlyph = glyphs[ike * GLYPHS_PER_NODE + 1];
            view.uiGlyph = glyphs[ike * GLYPHS_PER_NODE + 2];

            var position:NodePosition = nodePositions[ike];
            view.x = position.x;
            view.y = position.y;
            view.z = position.z;

            if (minX > view.x) minX = view.x;
            if (maxX < view.x) maxX = view.x;

            view.props = null;

            view.bottomGlyph.set_pos(view.x, view.y, view.z);
            view.topGlyph.set_pos(view.x, view.y, view.z + TOP_OFFSET);
            view.uiGlyph.set_pos(view.x, view.y, view.z + UI_OFFSET);

            view.bottomGlyph.set_char(boardCode, glyphTexture.font);
            view.bottomGlyph.set_s(0);
            view.topGlyph.set_char(bodyCode, glyphTexture.font);
            view.topGlyph.set_s(0);

            view.uiGlyph.set_color(UI_COLOR);
            view.uiGlyph.set_char(uiCode, glyphTexture.font);
            view.uiGlyph.set_s(0);
        }

        boardScale = BOARD_MAGNIFICATION / (maxX - minX);
        
        homeTransform.identity();
        homeTransform.appendScale(boardScale, boardScale, boardScale);
        homeTransform.appendTranslation(0, 0, 0.5);
        
        transform = rawTransform.clone();
        transform.append(homeTransform);
    }

    public function handleUIUpdate():Void {
        // Interpret info from UI
    }

    public function presentSequence(time:Float, maxFreshness:Int, causes:Array<String>, steps:Array<Array<NodeVO>>, distancesFromHead:Array<Int>, neighborBitfields:Array<Int>):Void {
        
        if (numActiveTweens > 0) for (tween in nodeTweens) if (tween != null) tween.effect(tween, tween.end);

        animationTime = 0;
        totalAnimationTime = time;
        nodeTweens = [];

        var nodeVOs:Array<NodeVO> = steps.shift();
        if (steps.length == 0) steps.push(nodeVOs);

        var start:Float = 0;
        var end:Float = 0;

        for (ike in 0...steps.length) {
            var step:Array<NodeVO> = steps[ike];
            var cause:String = causes[ike];
            var duration:Float = durationsByCause[cause];
            var delta:Float = duration * (1 - overlapsByCause[cause]);
            var lastFreshness:Int = -1;
            for (nodeVO in step) {
                if (nodeVO == null) continue;
                var id:Int = nodeVO.id;
                if (lastFreshness < nodeVO.freshness) lastFreshness = nodeVO.freshness;
                else start -= delta;
                var view:NodeView = nodeViews[id];
                var newProps:NodeProps = makeProps(nodeVO.state, nodeVO.occupier, neighborBitfields[id], distancesFromHead[id]);
                var oldProps:NodeProps = view.props;
                if (oldProps == null) oldProps = makeProps();
                var tween:NodeTween = {
                    from:oldProps, 
                    to:newProps, 
                    view:view, 
                    start:start,
                    duration:duration, 
                    end:start + duration,
                    effect:BoardEffects.getEffectForStateChange(nodeVOs[id].state, nodeVO.state),
                };

                if (end < tween.end) end = tween.end;
                start += delta;
                view.props = newProps;
                if (nodeVO.state == Wall) view.topGlyph.set_z(view.z + WALL_TOP_OFFSET);
                nodeTweens.push(tween);
                nodeVOs[id] = nodeVO;
            }
        }

        numActiveTweens = nodeTweens.length;
        
        if (numActiveTweens > 0) {
            // If the animation is too long, we need to compress it
            var scale:Float = time / end;
            if (scale < 1) {
                for (tween in nodeTweens) {
                    tween.start *= scale;
                    tween.duration *= scale;
                    tween.end *= scale;
                }
            }
        }
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
        
        if (numActiveTweens > 0) {
            animationTime += delta;
            for (ike in 0...nodeTweens.length) {
                var tween:NodeTween = nodeTweens[ike];
                if (tween != null && animationTime > tween.start) {
                    if (animationTime > tween.end) {
                        tween.effect(tween, tween.end);
                        nodeTweens[ike] = null;
                        numActiveTweens--;
                    } else {
                        tween.effect(tween, animationTime);
                    }
                }
            }

            if (numActiveTweens == 0) nodeTweens = [];
        }

        if (!dragging) {
            rawTransform.interpolateTo(plainTransform, 0.1);
            transform.copyFrom(rawTransform);
            transform.append(homeTransform);
        }

        super.update(delta);
    }

    override public function receiveInteraction(id:Int, interaction:Interaction):Void {
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

    inline function makeView():NodeView {
        return {
            topGlyph:null,
            bottomGlyph:null,
            uiGlyph:null,
            x:0,
            y:0,
            z:0,
            props:null,
        };
    }

    inline function makeProps(state:Null<NodeState> = null, occupier:Int = -1, bitfield:Int = -1, distance:Int = 0):NodeProps {
        var topSize:Float = 0;
        var topChar:Int = -1;
        var topColor:Color = BLACK;

        var bottomSize:Float = 0;
        var bottomChar:Int = -1;
        var bottomColor:Color = BLACK;

        switch (state) {
            case Wall:
                if (bitfield != -1) {
                    topSize = 1;
                    topChar = Utf8.charCodeAt(Strings.BOX_SYMBOLS, bitfield);
                    topColor = WALL_COLOR;
                    bottomSize = 1;
                    bottomChar = topChar;
                    bottomColor = BOARD_COLOR;
                }
            case Empty:
                bottomColor = BOARD_COLOR;
                bottomChar = boardCode;
                bottomSize = 0.5;
            case Cavity:
                bottomColor = Colors.mult(TEAM_COLORS[occupier % TEAM_COLORS.length], 0.6);
                bottomChar = boardCode;
                bottomSize = 0.5;
            case Body:
                // if (bitfield == 0xF) topChar = BODY_CHARS.charCodeAt(distance % Utf8.length(BODY_CHARS));
                // else topChar = Utf8.charCodeAt(Strings.BODY_GLYPHS, bitfield);
                topChar = bodyCode;
                topColor = TEAM_COLORS[occupier];
                /*
                var numNeighbors:Int = 0;
                for (i in 0...4) numNeighbors += (bitfield >> i) & 1;
                topSize = (numNeighbors / 4) * 0.6 + 0.2;
                */
                topSize = 1;
            case Head:
                topColor = TEAM_COLORS[occupier];
                topChar = headCode;
                topSize = 1.5;
            case null:
            case _:
        }

        return {
            topSize:topSize, topChar:topChar, topColor:topColor, topFont:glyphTexture.font,
            bottomSize:bottomSize, bottomChar:bottomChar, bottomColor:bottomColor, bottomFont:glyphTexture.font,
        };
    }

    private function isNotNull(vo:NodeVO):Bool return vo != null;

    static function makeDurationsByCause():Map<String, Float> {
        return [
            "" => 1,
            "CavityRule" => 2,
            "DecayRule" => 2,
            "DropPieceRule" => 1,
            "EatCellsRule" => 1,
            "BiteRule" => 1,
        ];
    }

    static function makeOverlapsByCause():Map<String, Float> {
        return [
            "" => 1,
            "CavityRule" => 1,
            "DecayRule" => 1,
            "DropPieceRule" => 1,
            "EatCellsRule" => 0.5,
            "PickPieceRule" => 1,
            "BiteRule" => 1,
        ];
    }

}
