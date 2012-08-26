package net.rezmason.scourge.model;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.GridNode;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;

using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.Pointers;

class BoardUtils {

    private static var ADD_SPACES:EReg = ~/([^\n\t])/g;

    public static function spitBoard(state:State, addSpaces:Bool = true):String {

        if (state.nodes.length == 0) return "empty grid";

        var str:String = "";

        var grid:BoardNode = state.nodes[0].run(Gr.nw).run(Gr.w).run(Gr.n);

        var occupier_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        var freshness_:AspectPtr = state.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];

        for (row in grid.walk(Gr.s)) {
            str += "\n";
            for (column in row.walk(Gr.e)) {

                var occupier:Int = state.history.get(occupier_.dref(column.value));
                var isFilled:Int = state.history.get(isFilled_.dref(column.value));
                var freshness:Int = 0;

                if (!freshness_.isNull()) freshness = state.history.get(freshness_.dref(column.value));

                str += switch (true) {
                    case (freshness > 0): "F";
                    case (occupier > -1): "" + occupier;
                    case (isFilled == 1): "X";
                    default: " ";
                }
            }
        }

        if (addSpaces) str = ADD_SPACES.replace(str, "$1 ");

        return str;
    }
}
