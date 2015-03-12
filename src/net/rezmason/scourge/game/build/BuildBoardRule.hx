package net.rezmason.scourge.game.build;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.grid.GridDirection.*;
import net.rezmason.praxis.grid.GridLocus;
import net.rezmason.praxis.rule.BaseRule;
import net.rezmason.scourge.game.body.BodyAspect;
import net.rezmason.scourge.game.body.OwnershipAspect;
import net.rezmason.scourge.game.TempParams;

using Lambda;
using net.rezmason.praxis.aspect.AspectUtils;
using net.rezmason.praxis.grid.GridUtils;
using net.rezmason.utils.Pointers;

typedef XY = {x:Float, y:Float};

class BuildBoardRule extends BaseRule<FullBuildBoardParams> {
    @node(BodyAspect.BODY_NEXT) var bodyNext_;
    @node(BodyAspect.BODY_PREV) var bodyPrev_;
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(BodyAspect.HEAD) var head_;

    override private function _prime():Void {
        var bodyNodesByPlayer:Array<Array<AspectSet>> = [for (ike in 0...numPlayers()) []];
        for (petriLocus in params.loci) addNode();
        for (petriLocus in params.loci) {
            var petriDatum = petriLocus.value;
            var nodeLocus = state.loci[petriLocus.id];
            var node = nodeLocus.value;

            if (petriDatum.isWall == true) {
                node[isFilled_] = TRUE;
            } else if (petriDatum.owner != -1) {
                node[isFilled_] = TRUE;
                node[occupier_] = petriDatum.owner;
                bodyNodesByPlayer[petriDatum.owner].push(node);
                if (petriDatum.isHead) getPlayer(petriDatum.owner)[head_] = petriLocus.id;
            }

            for (direction in GridUtils.allDirections()) {
                var neighbor = petriLocus.neighbors[direction];
                if (neighbor != null) nodeLocus.attach(state.loci[neighbor.id], direction);
            }
        }

        for (player in eachPlayer()) {
            var body = bodyNodesByPlayer[getID(player)];
            if (body.length > 0) {
                player[bodyFirst_] = getID(body[0]);
                body.chainByAspect(ident_, bodyNext_, bodyPrev_);
            }
        }
    }
}
