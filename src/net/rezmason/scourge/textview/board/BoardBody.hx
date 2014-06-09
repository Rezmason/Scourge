package net.rezmason.scourge.textview.board;

import haxe.Utf8;

import flash.geom.Matrix3D;
import flash.geom.Vector3D;

import net.rezmason.scourge.waves.WavePool;
import net.rezmason.scourge.waves.Ripple;
import net.rezmason.scourge.waves.WaveFunctions;

import net.rezmason.gl.utils.BufferUtil;
import net.rezmason.scourge.controller.ControllerTypes;
import net.rezmason.scourge.textview.board.BoardEffects;
import net.rezmason.scourge.textview.board.BoardTypes;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.core.GlyphTexture;

using net.rezmason.scourge.textview.core.GlyphUtils;
using net.rezmason.utils.CharCode;

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
    static var BOARD_CLEANUP_CAUSE:String = "#";
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

    inline static var BOARD_CODE:Int = '¤'.code();
    inline static var WALL_CODE:Int = '#'.code();
    inline static var BODY_CODE:Int = '•'.code();
    inline static var HEAD_CODE:Int = 'Ω'.code();
    inline static var UI_CODE:Int = ''.code();
    inline static var BLANK_CODE:Int = ' '.code();

    var numPlayers:Int;
    var numNodes:Int;
    var nodeViews:Array<NodeView>;
    var nodeTweens:Array<NodeTween>;
    var numActiveTweens:Int;

    var wavePools:Array<WavePool>;

    var animationTime:Float;
    var totalAnimationTime:Float;

    public function new(bufferUtil:BufferUtil, glyphTexture:GlyphTexture):Void {

        super(bufferUtil, glyphTexture);

        dragging = false;
        dragStartTransform = new Matrix3D();
        rawTransform = new Matrix3D();
        homeTransform = new Matrix3D();
        plainTransform = new Matrix3D();
        
        boardScale = 1;
        nodeViews = [];
        nodeTweens = [];
        wavePools = [];
        animationTime = 0;
        totalAnimationTime = 0;
        numActiveTweens = 0;
    }

    public function presentStart(numPlayers:Int, nodePositions:Array<XYZ>):Void {

        this.numPlayers = numPlayers;
        numNodes = nodePositions.length;
        growTo(numNodes * GLYPHS_PER_NODE);

        for (ike in 0...numPlayers) {
            if (wavePools[ike] == null) {
                wavePools[ike] = new WavePool(1);
                wavePools[ike].addRipple(new Ripple(WaveFunctions.bolus, 1, 4., 0.5, 20, true));
            } else {
                wavePools[ike].size = 1;
            }
        }

        var minX:Float = 0;
        var maxX:Float = 0;

        for (ike in 0...numNodes) {
            var view:NodeView = nodeViews[ike];
            if (view == null) nodeViews[ike] = view = makeView();
            view.bottomGlyph = glyphs[ike * GLYPHS_PER_NODE + 0];
            view.topGlyph = glyphs[ike * GLYPHS_PER_NODE + 1];
            view.uiGlyph = glyphs[ike * GLYPHS_PER_NODE + 2];

            var pos:XYZ = nodePositions[ike];
            view.pos = pos;

            if (minX > pos.x) minX = pos.x;
            if (maxX < pos.x) maxX = pos.x;

            view.props = null;

            view.bottomGlyph.set_pos(pos);
            view.topGlyph.set_xyz(pos.x, pos.y, pos.z + TOP_OFFSET);
            view.uiGlyph.set_xyz(pos.x, pos.y, pos.z + UI_OFFSET);

            view.bottomGlyph.set_char(BOARD_CODE, glyphTexture.font);
            view.bottomGlyph.set_s(0);
            view.topGlyph.set_char(BODY_CODE, glyphTexture.font);
            view.topGlyph.set_s(0);

            view.uiGlyph.set_color(UI_COLOR);
            view.uiGlyph.set_char(UI_CODE, glyphTexture.font);
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
        
        if (numActiveTweens > 0) {
            //var tweenString:String = '';
            for (tween in nodeTweens) {
                if (tween != null) {
                    animateTween(tween, tween.start + tween.duration);
                    //tweenString += '*';
                } else {
                    //tweenString += ' ';
                }
            }
            // tweenString += '\n';
            //trace(tweenString);
        }

        animationTime = 0;
        totalAnimationTime = time;
        nodeTweens = [];

        var nodeVOs:Array<NodeVO> = steps[0];
        
        if (steps.length > 1) {
            steps.shift();
            causes.shift();
        }

        var start:Float = 0;
        
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
                var newProps:NodeProps = makeProps(view.pos.z, nodeVO, neighborBitfields[id], distancesFromHead[id]);
                var oldProps:NodeProps = view.props;
                if (oldProps == null) oldProps = makeProps(view.pos.z);

                var effect:BoardEffect = BoardEffects.getEffectForStateChange(nodeVOs[id].state, nodeVO.state);
                effect(view, cause, start, duration, oldProps, newProps, nodeTweens);

                start += delta;
                view.props = newProps;
                nodeVOs[id] = nodeVO;
            }
        }

        var hasStragglers:Bool = false;
        var cause:String = BOARD_CLEANUP_CAUSE;
        var duration:Float = durationsByCause[cause];
        var maxDistances:Array<Int> = [];
        for (ike in 0...numPlayers) maxDistances[ike] = 0;
        for (ike in 0...numNodes) {
            var view:NodeView = nodeViews[ike];
            view.distance = distancesFromHead[ike];
            if (view.distance < 0) view.distance = 0;
            view.occupier = nodeVOs[ike].occupier;
            if (maxDistances[view.occupier] < view.distance) maxDistances[view.occupier] = view.distance;

            if (nodeVOs[ike].state == Body) {
                var neighborBitfield:Int = neighborBitfields[ike];
                var char:Int = getChar(view.occupier, neighborBitfield, view.distance);
                if (view.props.top.char != char) {
                    var newProps:NodeProps = makeProps(view.pos.z, nodeVOs[ike], neighborBitfield, view.distance);
                    BoardEffects.animateLinear(view, cause, start, duration, view.props, newProps, nodeTweens);
                    view.props = newProps;
                    hasStragglers = true;
                }
            }
        }
        for (ike in 0...numPlayers) wavePools[ike].size = maxDistances[ike] + 1;
        if (hasStragglers) start += duration;

        numActiveTweens = nodeTweens.length;
        
        if (numActiveTweens > 0) {
            var end:Float = 0;
            for (tween in nodeTweens) if (end < tween.start + tween.duration) end = tween.start + tween.duration;
            // If the animation is too long, we need to compress it
            var scale:Float = time / end;
            if (scale < 1) {
                for (tween in nodeTweens) {
                    tween.start *= scale;
                    tween.duration *= scale;
                }
            }
        }

        /*
        var tweenString:String = '';
        for (tween in nodeTweens) tweenString += Std.string(causes.indexOf(tween.cause));
        trace(tweenString);
        */
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
        
        // update animations
        if (numActiveTweens > 0) {
            animationTime += delta;
            //var tweenString:String = '';
            for (ike in 0...nodeTweens.length) {
                var tween:NodeTween = nodeTweens[ike];
                if (tween != null) {
                    if (animationTime < tween.start) {
                        //tweenString += ' ';
                    } else if (animationTime > tween.start + tween.duration) {
                        //tweenString += '•';
                        animateTween(tween, tween.start + tween.duration);
                        nodeTweens[ike] = null;
                        numActiveTweens--;
                    } else {
                        //tweenString += '|';
                        animateTween(tween, animationTime);
                    }
                } else {
                    //tweenString += ' ';
                }
            }

            //trace(tweenString);

            if (numActiveTweens == 0) nodeTweens = [];
        }

        // update waves
        for (pool in wavePools) pool.update(delta);
        for (view in nodeViews) {
            if (view.occupier != -1) {
                var h:Float = wavePools[view.occupier].getHeightAtIndex(view.distance) * view.waveMult;
                view.topGlyph.set_p(h * -0.1);
                view.topGlyph.set_s(view.topSize * (1 - h) + (view.topSize + 0.3) * h);
            }
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
            pos:null,
            waveMult:0,
            waveHeight:0,
            props:null,
            distance:0,
            occupier:-1,
            topSize:1,
        };
    }

    inline function getChar(occupier:Int, bitfield:Int, distance:Int):Int {
        var char:Int = -1;
        if (occupier == -1) {
            char = Utf8.charCodeAt(Strings.BOX_SYMBOLS, bitfield);
        } else if (bitfield == 0xF) {
            char = BODY_CHARS.charCodeAt(distance % Utf8.length(BODY_CHARS));
        } else {
            char = Utf8.charCodeAt(Strings.BODY_GLYPHS, bitfield);
        }
        return char;
    }

    inline function makeProps(z:Float, nodeVO:NodeVO = null, bitfield:Int = -1, distance:Int = 0):NodeProps {
        var top:NodeGlyphProps = {size:0, char:-1, color:BLACK, z:z, thickness:0.5};
        var bottom:NodeGlyphProps = {size:0, char:-1, color:BLACK, z:z, thickness:0.5};
        var waveMult:Float = 0;

        var state:Null<NodeState> = nodeVO != null ? nodeVO.state : null;
        var occupier:Int = nodeVO != null ? nodeVO.occupier : -1;

        switch (state) {
            case Wall:
                if (bitfield != -1) {
                    top.size = 1;
                    top.char = getChar(occupier, bitfield, distance);
                    top.color = WALL_COLOR;
                    top.z += WALL_TOP_OFFSET;
                    bottom.size = 1;
                    bottom.char = top.char;
                    bottom.color = BOARD_COLOR;
                }
            case Empty:
                bottom.color = BOARD_COLOR;
                bottom.char = BOARD_CODE;
                bottom.size = 0.75;
            case Cavity:
                bottom.color = Colors.mult(TEAM_COLORS[occupier % TEAM_COLORS.length], 0.6);
                bottom.char = BOARD_CODE;
                bottom.size = 0.75;
            case Body:
                top.char = getChar(occupier, bitfield, distance);
                top.color = TEAM_COLORS[occupier];
                waveMult = 1;
                var numNeighbors:Int = 0;
                for (i in 0...4) numNeighbors += (bitfield >> i) & 1;
                top.size = (numNeighbors / 4) * 0.6 + 0.45;
                bottom.char = top.char;
                bottom.color = Colors.mult(top.color, 0.15);
                bottom.thickness = 0.8;
                bottom.size = top.size * 1.5;
            case Head:
                top.color = TEAM_COLORS[occupier];
                top.char = HEAD_CODE;
                top.size = 1.5;
                bottom.char = top.char;
                waveMult = 1;
                bottom.color = Colors.mult(top.color, 0.15);
                bottom.thickness = 0.8;
                bottom.size = top.size * 1.5;
            case null:
            case _:
        }

        return {top:top, bottom:bottom, waveMult:waveMult};
    }

    inline function animateTween(tween:NodeTween, now:Float):Void {
        var frac:Float = (now - tween.start) / tween.duration;
        if (tween.ease != null) frac = tween.ease(frac);
        animateGlyph(tween.view.topGlyph, tween.from.top, tween.to.top, frac);
        animateGlyph(tween.view.bottomGlyph, tween.from.bottom, tween.to.bottom, frac);
        tween.view.waveMult = interp(tween.from.waveMult, tween.to.waveMult, frac);
        tween.view.topSize = tween.view.topGlyph.get_s();
    }

    inline function animateGlyph(glyph:Glyph, from:NodeGlyphProps, to:NodeGlyphProps, frac:Float):Void {
        glyph.set_s(interp(from.size, to.size , frac));
        glyph.set_z(interp(from.z, to.z , frac));
        glyph.set_f(interp(from.thickness, to.thickness , frac));
        glyph.set_rgb(
            interp(from.color.r, to.color.r, frac),
            interp(from.color.g, to.color.g, frac),
            interp(from.color.b, to.color.b, frac)
        );
        
        if (from.char == -1) {
            if (glyph.get_char() != to.char) glyph.set_char(to.char, glyphTexture.font);
        } else {

            if (from.char != to.char) {
                if (frac < 0.5) {
                    glyph.set_f(interp(0.5, 0, frac * 2));
                } else {
                    glyph.set_f(interp(0, 0.5, frac * 2 - 1));
                    if (glyph.get_char() != to.char) glyph.set_char(to.char, glyphTexture.font);
                }
            }

            if (frac < 0.5 && glyph.get_char() != from.char) glyph.set_char(from.char, glyphTexture.font);
        }
    }

    inline static function interp(val1:Float, val2:Float, frac:Float):Float return val1 * (1 - frac) + val2 * frac;

    private function isNotNull(vo:NodeVO):Bool return vo != null;

    static function makeDurationsByCause():Map<String, Float> {
        return [
            "" => 1,
            "CavityRule" => 3,
            "DecayRule" => 3,
            "DropPieceRule" => 2,
            "EatCellsRule" => 1,
            "BiteRule" => 1,
            BOARD_CLEANUP_CAUSE => 1,
        ];
    }

    static function makeOverlapsByCause():Map<String, Float> {
        return [
            "" => 1,
            "CavityRule" => 1,
            "DecayRule" => 1,
            "DropPieceRule" => 0,
            "EatCellsRule" => 0.5,
            "PickPieceRule" => 1,
            "BiteRule" => 0,
        ];
    }

}
