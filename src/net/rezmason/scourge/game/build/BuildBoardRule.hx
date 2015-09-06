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
using net.rezmason.utils.pointers.Pointers;

typedef XY = {x:Float, y:Float};

class BuildBoardRule extends BaseRule<FullBuildBoardParams> {
    @space(BodyAspect.BODY_NEXT, true) var bodyNext_;
    @space(BodyAspect.BODY_PREV, true) var bodyPrev_;
    @space(OwnershipAspect.IS_FILLED, true) var isFilled_;
    @space(OwnershipAspect.OCCUPIER, true) var occupier_;
    @player(BodyAspect.BODY_FIRST, true) var bodyFirst_;
    @player(BodyAspect.HEAD, true) var head_;

    override private function _prime():Void {
        var bodySpacesByPlayer:Array<Array<Space>> = [for (ike in 0...numPlayers()) []];
        for (petriCell in params.cells) addSpace();
        for (petriCell in params.cells) {
            var petriDatum = petriCell.value;
            var spaceCell = state.cells.getCell(petriCell.id);
            var space = spaceCell.value;

            if (petriDatum.isWall == true) {
                space[isFilled_] = TRUE;
            } else if (petriDatum.owner != -1) {
                space[isFilled_] = TRUE;
                space[occupier_] = petriDatum.owner;
                bodySpacesByPlayer[petriDatum.owner].push(space);
                if (petriDatum.isHead) getPlayer(petriDatum.owner)[head_] = petriCell.id;
            }

            for (direction in GridUtils.allDirections()) {
                var neighbor = petriCell.neighbors[direction];
                if (neighbor != null) spaceCell.attach(state.cells.getCell(neighbor.id), direction);
            }
        }

        for (player in eachPlayer()) {
            var body = bodySpacesByPlayer[getID(player)];
            if (body.length > 0) {
                player[bodyFirst_] = getID(body[0]);
                body.chainByAspect(spaceIdent_, bodyNext_, bodyPrev_);
            }
        }
    }
}
