package net.rezmason.scourge.controller.board;

import haxe.Utf8;
import net.rezmason.ecce.Ecce;
import net.rezmason.ecce.Entity;
import net.rezmason.ecce.Query;
import net.rezmason.math.Vec3;
import net.rezmason.praxis.Reckoner;
import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.play.Game;
import net.rezmason.scourge.components.*;
import net.rezmason.scourge.game.body.OwnershipAspect;
import net.rezmason.scourge.ScourgeStrings.*;
import net.rezmason.utils.santa.Present;

import motion.easing.*;

using net.rezmason.hypertype.core.GlyphUtils;
using net.rezmason.grid.GridUtils;

class BoardSettler extends Reckoner {

    static var nudgeArray:Array<Vec3> = makeNudgeArray();

    var ecce:Ecce;
    var qBoard:Query;

    @space(OwnershipAspect.IS_FILLED) var isFilled_;
    @space(OwnershipAspect.OCCUPIER) var occupier_;

    public function new():Void {
        super();
        ecce = new Present(Ecce);
        qBoard = ecce.query([BoardSpaceView, BoardSpaceState]);
    }

    @:final public function init(game:Game) primePointers(game.state, game.plan);

    public function run() {

        var animationEntities = null;

        var affectedEntities:Map<Entity, Bool> = new Map();

        for (entity in qBoard) {
            var view = entity.get(BoardSpaceView);
            var spaceState = entity.get(BoardSpaceState);
            if (view.changed) {
                affectedEntities[entity] = true;
                for (neighbor in spaceState.cell.orthoNeighbors()) affectedEntities.set(neighbor.value, true);
            }
        }
        
        for (entity in affectedEntities.keys()) {
            var view = entity.get(BoardSpaceView);
            
            var spaceState = entity.get(BoardSpaceState);

            var animEntity = ecce.dispense([GlyphAnimation]);
            if (animationEntities == null) animationEntities = [];
            animationEntities.push(animEntity);

            var anim = animEntity.get(GlyphAnimation);
            anim.subject = entity;
            if (anim.topFrom == null) anim.topFrom = GlyphUtils.createGlyph();
            if (anim.topTo == null) anim.topTo = GlyphUtils.createGlyph();
            if (anim.bottomFrom == null) anim.bottomFrom = GlyphUtils.createGlyph();
            if (anim.bottomTo == null) anim.bottomTo = GlyphUtils.createGlyph();
            anim.startTime = 0;
            anim.duration = 0.3;
            anim.ease = Quad.easeInOut.calculate;
            
            if (view.changed) {
                view.changed = false;
                anim.topFrom.copyFrom(view.lastTopTo);
                anim.topTo.copyFrom(view.lastTopTo);
                anim.bottomFrom.copyFrom(view.lastBottomTo);
                anim.bottomTo.copyFrom(view.lastBottomTo);
            } else {
                anim.topFrom.copyFrom(view.top);
                anim.topTo.copyFrom(view.top);
                anim.bottomFrom.copyFrom(view.bottom);
                anim.bottomTo.copyFrom(view.bottom);
            }
            
            anim.topTo.set_p(-0.01);

            var occupier = spaceState.values[occupier_];
            if (!spaceState.petriData.isHead && spaceState.values[isFilled_] == TRUE && occupier != -1) {
                var numNeighbors:Int = 0;
                var bitfield:Int = 0;
                for (neighbor in spaceState.cell.orthoNeighbors()) {
                    if (neighbor != null) {
                        var neighborValues = neighbor.value.get(BoardSpaceState).values;
                        if (neighborValues[isFilled_] == TRUE && neighborValues[occupier_] == occupier) {
                            bitfield = bitfield | (1 << numNeighbors);
                        }
                    }
                    numNeighbors++;
                }
                var pos = spaceState.petriData.pos;
                var nudge = nudgeArray[bitfield];
                var x = nudge == null ? Math.random() * 0.4 - 0.2 : nudge.x;
                var y = nudge == null ? Math.random() * 0.4 - 0.2 : nudge.y;
                var char = Utf8.charCodeAt(ScourgeStrings.BODY_GLYPHS, bitfield);
                anim.topTo.SET({x:pos.x + x * 0.2, y:pos.y + y * 0.2, char:char});
                view.lastTopTo.copyFrom(anim.topTo);
            }

        }

        return animationEntities;
    }

    static function makeNudgeArray():Array<Vec3> {
        var up:Float = 1;
        var lt:Float = -1;
        var dn:Float = -up;
        var rt:Float = -lt;
        return [
            new Vec3(0       , 0       , 0), // 
            new Vec3(0       , up      , 0), // ╹
            new Vec3(rt      , 0       , 0), // ╺
            new Vec3(rt      , up      , 0), // ┗
            new Vec3(0       , dn      , 0), // ╻
            new Vec3(0       , 0       , 0), // ┃
            new Vec3(rt      , dn      , 0), // ┏
            new Vec3(rt * 0.5, 0       , 0), // ┣
            new Vec3(lt      , 0       , 0), // ╸
            new Vec3(lt      , up      , 0), // ┛
            new Vec3(0       , 0       , 0), // ━
            new Vec3(0       , up * 0.5, 0), // ┻
            new Vec3(lt      , dn      , 0), // ┓
            new Vec3(lt * 0.5, 0       , 0), // ┫
            new Vec3(0       , dn * 0.5, 0), // ┳
            null, // ╋
        ];
    }
}
