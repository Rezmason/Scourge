package net.rezmason.scourge.textview.board;

import haxe.Utf8;

import flash.geom.Matrix3D;
import flash.geom.Vector3D;

import net.rezmason.scourge.waves.WavePool;
import net.rezmason.scourge.waves.Ripple;
import net.rezmason.scourge.waves.WaveFunctions;

import net.rezmason.scourge.controller.ControllerTypes;
import net.rezmason.scourge.textview.board.BoardEffects;
import net.rezmason.scourge.textview.board.BoardTypes;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.utils.Zig;

using net.rezmason.scourge.textview.core.GlyphUtils;
using net.rezmason.utils.CharCode;

class BoardSystem {

    inline static var MILLISECONDS_TO_SECONDS:Float = 1 / 1000;
    inline static var GLYPHS_PER_NODE:Int = 3;
    inline static var BOARD_MAGNIFICATION:Float = 1.15;
    inline static var WALL_TOP_OFFSET:Float = -0.05;
    inline static var TOP_OFFSET:Float = -0.03;
    inline static var UI_OFFSET:Float = -0.06;
    inline static var NUDGE_MAG:Float = 0.01;
    static var BODY_CHARS:String = 'abcdefghijklmnopqrstuvwxyz';
    static var BLACK:Color = {r:0, g:0, b:0};
    static var BOARD_CLEANUP_CAUSE:String = "#";
    static var durationsByCause:Map<String, Float> = makeDurationsByCause();
    static var overlapsByCause:Map<String, Float> = makeOverlapsByCause();
    static var nudgeArray:Array<XYZ> = makeNudgeArray();

    public var body(default, null):Body;

    var maxAnimationTime:Float;
    var animationSpeed:Float;
    
    var boardScale:Float;

    inline static var BOARD_CODE:Int = '+'.code(); // ¤
    inline static var WALL_CODE:Int = '╋'.code();
    inline static var CAVITY_CODE:Int = 'ж'.code();
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
    var proceedSignal:Zig<Void->Void>;
    
    var playerIndex:Int;

    public function new():Void {

        body = new Body();
        body.updateSignal.add(update);

        boardScale = 1;
        body.glyphScale = 0.025;
        nodeViews = [];
        nodeTweens = [];
        wavePools = [];
        animationTime = 0;
        numActiveTweens = 0;

        maxAnimationTime = 2000;
        animationSpeed = 1;
    }

    public function setAnimationSpeed(milliseconds:Float):Void {
        animationSpeed = milliseconds * MILLISECONDS_TO_SECONDS;
    }

    public function presentStart(numPlayers:Int, nodePositions:Array<XYZ>):Void {

        finishSequenceAnimation();

        this.numPlayers = numPlayers;
        numNodes = nodePositions.length;
        body.growTo(numNodes * GLYPHS_PER_NODE);

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
            view.bottomGlyph = body.getGlyphByID(ike * GLYPHS_PER_NODE + 0);
            view.topGlyph = body.getGlyphByID(ike * GLYPHS_PER_NODE + 1);
            view.uiGlyph = body.getGlyphByID(ike * GLYPHS_PER_NODE + 2);

            var pos:XYZ = nodePositions[ike];
            view.pos = pos;

            if (minX > pos.x) minX = pos.x;
            if (maxX < pos.x) maxX = pos.x;

            view.waveMult = 0;
            view.waveHeight = 0;
            view.distance = 0;
            view.occupier = 0;
            view.topSize = 0;
            view.topZ = 0;
            view.props = null;

            view.bottomGlyph.reset();
            view.topGlyph.reset();
            view.uiGlyph.reset();

            view.bottomGlyph.set_pos(pos);
            view.topGlyph.set_xyz(pos.x, pos.y, pos.z + TOP_OFFSET);
            view.uiGlyph.set_xyz(pos.x, pos.y, pos.z + UI_OFFSET);

            view.bottomGlyph.set_char(BOARD_CODE);
            view.topGlyph.set_char(BODY_CODE);
            view.uiGlyph.set_char(UI_CODE);
            view.uiGlyph.set_color(ColorPalette.UI_COLOR);
            view.uiGlyph.set_s(0);
        }

        boardScale = BOARD_MAGNIFICATION / (maxX - minX);
        body.glyphScale = 0.025 * boardScale;
        
        body.transform.identity();
        body.transform.appendScale(boardScale, boardScale, boardScale);
        body.transform.appendTranslation(0, 0, 0.5);
    }

    public function handleUIUpdate():Void {
        // Interpret info from UI
    }

    public function presentSequence(
        playerIndex:Int, 
        move:String,
        maxFreshness:Int, 
        causes:Array<String>, 
        steps:Array<Array<NodeVO>>, 
        distancesFromHead:Array<Int>, 
        neighborBitfields:Array<Int>
    ):Void {
        
        finishSequenceAnimation();

        this.playerIndex = playerIndex;

        var nodeVOs:Array<NodeVO> = steps[0];
        
        if (steps.length > 1) {
            steps.shift();
            causes.shift();
        }

        var lastCause:Int = 0;

        var start:Float = 0;
        
        for (ike in 0...steps.length) {
            var step:Array<NodeVO> = steps[ike];
            var cause:String = causes[ike];
            if (cause == 'DecayRule' && step.length > 0) {
                step = step.copy();
                var minFreshness:Int = step[0].freshness;
                var num:Int = step.length;
                while (num > 0) {
                    var randIndex:Int = Std.random(num);
                    num--;
                    var swap:NodeVO = step[num];
                    step[num] = step[randIndex];
                    step[randIndex] = swap;
                }
                for (nodeVO in step) {
                    nodeVO.freshness = minFreshness;
                    minFreshness++;
                }
            }
            var duration:Float = durationsByCause[cause] * animationSpeed;
            var delta:Float = duration * (1 - overlapsByCause[cause]);
            var lastFreshness:Int = -1;
            if (step.length > 0) lastCause = ike;
            for (nodeVO in step) {
                if (nodeVO == null) continue;
                var id:Int = nodeVO.id;
                if (lastFreshness < nodeVO.freshness) lastFreshness = nodeVO.freshness;
                else start -= delta;
                var view:NodeView = nodeViews[id];
                var newProps:NodeProps = makeProps(view.pos, nodeVO, neighborBitfields[id], distancesFromHead[id]);
                var oldProps:NodeProps = view.props;
                if (oldProps == null) oldProps = makeProps(view.pos);

                var effect:BoardEffect = BoardEffects.getEffectForStateChange(nodeVOs[id].state, nodeVO.state);
                effect(view, cause, start, duration, oldProps, newProps, nodeTweens);

                start += delta;
                view.props = newProps;
                nodeVOs[id] = nodeVO;
            }
        }

        // trace(causes.slice(0, lastCause));

        var stragglers:Array<Int> = [];
        var cause:String = BOARD_CLEANUP_CAUSE;
        var duration:Float = durationsByCause[cause] * animationSpeed;
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
                    var newProps:NodeProps = makeProps(view.pos, nodeVOs[ike], neighborBitfield, view.distance);
                    BoardEffects.animateLinear(view, cause, start, duration, view.props, newProps, nodeTweens);
                    view.props = newProps;
                    stragglers.push(ike);
                }
            }
        }
        for (ike in 0...numPlayers) wavePools[ike].size = maxDistances[ike] + 1;
        if (stragglers.length > 0) start += duration;
        // trace('stragglers: $stragglers');

        numActiveTweens = nodeTweens.length;
        
        if (numActiveTweens > 0) {
            var end:Float = 0;
            for (tween in nodeTweens) if (end < tween.start + tween.duration) end = tween.start + tween.duration;
            // If the animation is too long, we need to compress it
            var scale:Float = maxAnimationTime / end;
            if (scale < 1) {
                for (tween in nodeTweens) {
                    tween.start *= scale;
                    tween.duration *= scale;
                }
            }
        }

        if (numActiveTweens == 0 && proceedSignal != null) proceedSignal.dispatch();
        /*
        var tweenString:String = '';
        for (tween in nodeTweens) {
            if (tween.cause == BOARD_CLEANUP_CAUSE) tweenString += BOARD_CLEANUP_CAUSE;
            else tweenString += Std.string(causes.indexOf(tween.cause));
        }
        trace(tweenString);
        */
    }

    private function finishSequenceAnimation():Void {
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
            //tweenString += '\n';
            //trace(tweenString);
        }

        animationTime = 0;
        nodeTweens = [];
    }

    public function setProceedSignal(signal:Zig<Void->Void>):Void {
        proceedSignal = signal;
    }

    function update(delta:Float):Void {
        
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

            if (numActiveTweens == 0) {
                nodeTweens = [];
                if (proceedSignal != null) proceedSignal.dispatch();
            }
        }

        // update waves
        for (pool in wavePools) pool.update(delta);
        for (view in nodeViews) {
            if (view.occupier != -1) {
                var h:Float = wavePools[view.occupier].getHeightAtIndex(view.distance) * view.waveMult;
                view.topGlyph.set_z(view.topZ + h * -0.04);
                view.topGlyph.set_a(0.5 + h * 0.5);
                view.topGlyph.set_s(view.topSize * (1 - h) + (view.topSize + 0.5) * h);
            }
        }
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
            topZ:0,
        };
    }

    inline function getChar(occupier:Int, bitfield:Int, distance:Int):Int {
        var char:Int = -1;
        if (occupier == -1) {
            char = Utf8.charCodeAt(Strings.BOX_SYMBOLS, bitfield);
        } else if (bitfield == 0xF) {
            char = BODY_CHARS.charCodeAt(Std.int(distance / 2) % Utf8.length(BODY_CHARS));
        } else {
            char = Utf8.charCodeAt(Strings.BODY_GLYPHS, bitfield);
        }

        return char;
    }

    inline function clonePos(pos:XYZ):XYZ return {x:pos.x, y:pos.y, z:pos.z};

    inline function makeProps(pos:XYZ, nodeVO:NodeVO = null, bitfield:Int = -1, distance:Int = 0):NodeProps {
        var top:NodeGlyphProps = {size:0, char:-1, color:BLACK, pos:clonePos(pos), thickness:0.5, stretch:1};
        var bottom:NodeGlyphProps = {size:0, char:-1, color:BLACK, pos:clonePos(pos), thickness:0.5, stretch:1};
        var waveMult:Float = 0;

        var state:Null<NodeState> = nodeVO != null ? nodeVO.state : null;
        var occupier:Int = nodeVO != null ? nodeVO.occupier : -1;

        switch (state) {
            case Wall:
                if (bitfield != -1) {
                    top.size = 1;
                    top.char = getChar(occupier, bitfield, distance);
                    top.color = ColorPalette.WALL_COLOR;
                    top.pos.z += WALL_TOP_OFFSET;
                    top.thickness = 0.4;
                    top.stretch = body.glyphTexture.font.glyphRatio;
                    bottom.size = 1;
                    bottom.char = top.char;
                    bottom.color = ColorPalette.BOARD_COLOR;
                    bottom.stretch = body.glyphTexture.font.glyphRatio;
                }
            case Empty:
                bottom.color = ColorPalette.BOARD_COLOR;
                bottom.char = BOARD_CODE;
                bottom.size = 0.7;
            case Cavity:
                bottom.color = Colors.mult(ColorPalette.TEAM_COLORS[occupier % ColorPalette.TEAM_COLORS.length], 0.125);
                bottom.char = CAVITY_CODE;
                bottom.size = 2;
            case Body:
                top.pos.z += TOP_OFFSET;
                top.char = getChar(occupier, bitfield, distance);
                top.color = ColorPalette.TEAM_COLORS[occupier];
                waveMult = 1;
                var numNeighbors:Int = 0;
                for (i in 0...4) numNeighbors += (bitfield >> i) & 1;
                top.size = (numNeighbors / 4) * 0.6 + 0.4;
                //top.stretch = glyphTexture.font.glyphRatio;
                bottom.char = top.char;
                bottom.color = Colors.mult(top.color, 0.15);
                bottom.thickness = 0.8;
                bottom.size = top.size * 1.5;
                //bottom.stretch = glyphTexture.font.glyphRatio;
                if (bitfield != -1) {
                    var nudgePos:Null<XYZ> = nudgeArray[bitfield];
                    if (nudgePos == null) nudgePos = {x:Math.random() - 0.5, y:Math.random() - 0.5, z:0};
                    top.pos.x += nudgePos.x * NUDGE_MAG;
                    top.pos.y += nudgePos.y * NUDGE_MAG;
                    top.pos.z += nudgePos.z * NUDGE_MAG;
                    bottom.pos.x += nudgePos.x * NUDGE_MAG * 0.5;
                    bottom.pos.y += nudgePos.y * NUDGE_MAG * 0.5;
                    bottom.pos.z += nudgePos.z * NUDGE_MAG * 0.5;
                }
            case Head:
                top.pos.z += TOP_OFFSET;
                top.color = ColorPalette.TEAM_COLORS[occupier];
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
        if (frac < 0) frac = 0;
        else if (frac > 1) frac = 1;

        if (tween.ease != null) frac = tween.ease(frac);
        animateGlyph(tween.view.topGlyph, tween.from.top, tween.to.top, frac);
        animateGlyph(tween.view.bottomGlyph, tween.from.bottom, tween.to.bottom, frac);
        tween.view.waveMult = interp(tween.from.waveMult, tween.to.waveMult, frac);
        tween.view.topSize = tween.view.topGlyph.get_s();
        tween.view.topZ = tween.view.topGlyph.get_z();
    }

    inline function animateGlyph(glyph:Glyph, from:NodeGlyphProps, to:NodeGlyphProps, frac:Float):Void {
        glyph.set_s(interp(from.size, to.size , frac));
        glyph.set_x(interp(from.pos.x, to.pos.x , frac));
        glyph.set_y(interp(from.pos.y, to.pos.y , frac));
        glyph.set_z(interp(from.pos.z, to.pos.z , frac));
        glyph.set_f(interp(from.thickness, to.thickness , frac));
        glyph.set_rgb(
            interp(from.color.r, to.color.r, frac),
            interp(from.color.g, to.color.g, frac),
            interp(from.color.b, to.color.b, frac)
        );

        if (from.char == -1) from.char = to.char;
        if (from.char != to.char) glyph.set_f(Math.abs(frac - 0.5));
        var char:Int = frac < 0.5 ? from.char : to.char;
        if (glyph.get_char() != char) {
            glyph.set_h(to.stretch);
            glyph.set_char(char);
        }
    }

    inline static function interp(val1:Float, val2:Float, frac:Float):Float return val1 * (1 - frac) + val2 * frac;

    private function isNotNull(vo:NodeVO):Bool return vo != null;

    static function makeDurationsByCause():Map<String, Float> {
        return [
            "" => 0.4,
            "CavityRule" => 0.4,
            "DecayRule" => 1.0,
            "DropPieceRule" => 1,
            "EatCellsRule" => 0.4,
            "BiteRule" => 1.0,
            BOARD_CLEANUP_CAUSE => 0.2,
        ];
    }

    static function makeOverlapsByCause():Map<String, Float> {
        return [
            "" => 1,
            "CavityRule" => 1,
            "DecayRule" => 0.995,
            "DropPieceRule" => 0.3,
            "EatCellsRule" => 0.5,
            "PickPieceRule" => 1,
            "BiteRule" => 1,
        ];
    }

    static function makeNudgeArray():Array<XYZ> {
        var up:Float = 1;
        var lt:Float = -1;
        var dn:Float = -up;
        var rt:Float = -lt;
        return [
            {x:0       , y:0       , z:0}, // 
            {x:0       , y:up      , z:0}, // ╹
            {x:rt      , y:0       , z:0}, // ╺
            {x:rt      , y:up      , z:0}, // ┗
            {x:0       , y:dn      , z:0}, // ╻
            {x:0       , y:0       , z:0}, // ┃
            {x:rt      , y:dn      , z:0}, // ┏
            {x:rt * 0.5, y:0       , z:0}, // ┣
            {x:lt      , y:0       , z:0}, // ╸
            {x:lt      , y:up      , z:0}, // ┛
            {x:0       , y:0       , z:0}, // ━
            {x:0       , y:up * 0.5, z:0}, // ┻
            {x:lt      , y:dn      , z:0}, // ┓
            {x:lt * 0.5, y:0       , z:0}, // ┫
            {x:0       , y:dn * 0.5, z:0}, // ┳
            null                           // ╋
        ];
    }
}
