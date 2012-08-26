package net.rezmason.scourge.model;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.GridNode;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.Pointers;

class BoardUtils {

    private static var ADD_SPACES:EReg = ~/([^\n\t])/g;

    public static function spitBoard(state:State, addSpaces:Bool = true, otherNodeAspects:IntHash<String> = null):String {

        if (state.nodes.length == 0) return "empty grid";

        if (otherNodeAspects == null) otherNodeAspects = new IntHash<String>();
        var otherAspectPtrs:IntHash<AspectPtr> = new IntHash<AspectPtr>();
        for (id in otherNodeAspects.keys()) otherAspectPtrs.set(id, state.nodeAspectLookup[id]);

        var str:String = "";

        var grid:BoardNode = state.nodes[0].run(Gr.nw).run(Gr.w).run(Gr.n);

        var occupier_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];

        for (row in grid.walk(Gr.s)) {
            str += "\n";
            for (column in row.walk(Gr.e)) {

                var otherAspectFound:Bool = false;

                for (id in otherAspectPtrs.keys()) {
                    var ptr:AspectPtr = otherAspectPtrs.get(id);
                    if (state.history.get(column.value.at(ptr)) > 0) {
                        otherAspectFound = true;
                        str += otherNodeAspects.get(id);
                        break;
                    }
                }

                if (!otherAspectFound) {
                    var occupier:Int = state.history.get(column.value.at(occupier_));
                    var isFilled:Int = state.history.get(column.value.at(isFilled_));

                    str += switch (true) {
                        case (occupier > -1): "" + occupier;
                        case (isFilled == 1): "X";
                        default: " ";
                    }
                }
            }
        }

        if (addSpaces) str = ADD_SPACES.replace(str, "$1 ");

        return str;
    }
}
