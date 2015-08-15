package net.rezmason.scourge.game.build;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.grid.GridDirection.*;
import net.rezmason.grid.Cell;
import net.rezmason.praxis.rule.BaseRule;
import net.rezmason.scourge.game.body.BodyAspect;
import net.rezmason.scourge.game.body.OwnershipAspect;
import net.rezmason.scourge.game.TempParams;

using Lambda;
using net.rezmason.praxis.aspect.AspectUtils;
using net.rezmason.grid.GridUtils;
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
        for (petriCell in params.cells) addNode();
        for (petriCell in params.cells) {
            var petriDatum = petriCell.value;
            var nodeCell = state.cells[petriCell.id];
            var node = nodeCell.value;

            if (petriDatum.isWall == true) {
                node[isFilled_] = TRUE;
            } else if (petriDatum.owner != -1) {
                node[isFilled_] = TRUE;
                node[occupier_] = petriDatum.owner;
                bodyNodesByPlayer[petriDatum.owner].push(node);
                if (petriDatum.isHead) getPlayer(petriDatum.owner)[head_] = petriCell.id;
            }

            for (direction in GridUtils.allDirections()) {
                var neighbor = petriCell.neighbors[direction];
                if (neighbor != null) nodeCell.attach(state.cells[neighbor.id], direction);
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
