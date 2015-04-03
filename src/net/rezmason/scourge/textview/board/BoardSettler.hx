package net.rezmason.scourge.textview.board;

import haxe.Utf8;
import net.rezmason.ecce.Ecce;
import net.rezmason.ecce.Entity;
import net.rezmason.ecce.Query;
import net.rezmason.praxis.Reckoner;
import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.play.Game;
import net.rezmason.scourge.components.*;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.game.body.OwnershipAspect;

import net.kawa.tween.easing.*;

using net.rezmason.scourge.textview.core.GlyphUtils;
using net.rezmason.praxis.grid.GridUtils;

class BoardSettler extends Reckoner {

    static var nudgeArray:Array<XYZ> = makeNudgeArray();

    var body:Body;
    var ecce:Ecce;
    var qBoard:Query;

    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;

    public function new(ecce:Ecce, body:Body):Void {
        super();
        this.ecce = ecce;
        this.body = body;
        qBoard = ecce.query([BoardNodeView, BoardNodeState]);
    }

    @:final public function init(game:Game) primePointers(game.state, game.plan);

    public function run() {
        var affectedEntities:Map<Entity, Bool> = new Map();

        for (entity in qBoard) {
            var view = entity.get(BoardNodeView);
            var nodeState = entity.get(BoardNodeState);
            if (view.raised) {
                affectedEntities[entity] = true;
                for (neighbor in nodeState.locus.orthoNeighbors()) affectedEntities.set(neighbor.value, true);
            }
        }
        
        for (entity in affectedEntities.keys()) {
            var view = entity.get(BoardNodeView);
            view.raised = false;
            
            var nodeState = entity.get(BoardNodeState);

            var anim = ecce.dispense([GlyphAnimation]).get(GlyphAnimation);
            anim.subject = entity;
            if (anim.topFrom == null) anim.topFrom = GlyphUtils.createGlyph();
            if (anim.topTo == null) anim.topTo = GlyphUtils.createGlyph();
            if (anim.bottomFrom == null) anim.bottomFrom = GlyphUtils.createGlyph();
            if (anim.bottomTo == null) anim.bottomTo = GlyphUtils.createGlyph();
            anim.duration = 0.3;
            anim.ease = Quad.easeInOut;
            
            anim.topFrom.copyFrom(view.top);
            anim.topTo.copyFrom(view.top);
            anim.bottomFrom.copyFrom(view.bottom);
            anim.bottomTo.copyFrom(view.bottom);

            anim.topTo.set_p(-0.01);

            var occupier = nodeState.values[occupier_];
            if (!nodeState.petriData.isHead && nodeState.values[isFilled_] == TRUE && occupier != -1) {
                var numNeighbors:Int = 0;
                var bitfield:Int = 0;
                for (neighbor in nodeState.locus.orthoNeighbors()) {
                    if (neighbor != null) {
                        var neighborValues = neighbor.value.get(BoardNodeState).values;
                        if (neighborValues[isFilled_] == TRUE && neighborValues[occupier_] == occupier) {
                            bitfield = bitfield | (1 << numNeighbors);
                        }
                    }
                    numNeighbors++;
                }
                var pos = nodeState.petriData.pos;
                var nudge = nudgeArray[bitfield];
                var x = nudge == null ? Math.random() * 0.4 - 0.2 : nudge.x;
                var y = nudge == null ? Math.random() * 0.4 - 0.2 : nudge.y;
                var char = Utf8.charCodeAt(Strings.BODY_GLYPHS, bitfield);
                anim.topTo.SET({x:pos.x + x * 0.2, y:pos.y + y * 0.2, char:char});
            }
        }
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
            null, // ╋
        ];
    }
}
