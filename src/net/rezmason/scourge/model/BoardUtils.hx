package net.rezmason.scourge.model;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.GridLocus;
import net.rezmason.ropes.State;
import net.rezmason.ropes.StatePlan;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using net.rezmason.ropes.GridUtils;

class BoardUtils {

    private inline static function ALPHABET():Int { return 'a'.charCodeAt(0); }

    private static var ADD_SPACES:EReg = ~/([^\n\t])/g;

    public inline static function grabXY(state:State, east:Int, south:Int):BoardLocus {
        return state.loci[0].run(Gr.nw).run(Gr.w).run(Gr.n).run(Gr.s, south).run(Gr.e, east);
    }

    public static function spitBoard(state:State, plan:StatePlan, addSpaces:Bool = true, otherNodeAspects:Map<String, String> = null):String {
        if (state.loci.length == 0) return 'empty grid';

        if (otherNodeAspects == null) otherNodeAspects = new Map();
        var otherAspectPtrs:Map<String, AspectPtr> = new Map();
        for (id in otherNodeAspects.keys()) otherAspectPtrs[id] = plan.nodeAspectLookup[id];

        var str:String = '';

        var grid:BoardLocus = state.loci[0].run(Gr.nw).run(Gr.w).run(Gr.n);

        var occupier_:AspectPtr = plan.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = plan.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];

        for (row in grid.walk(Gr.s)) {
            str += '\n';
            for (column in row.walk(Gr.e)) {

                var otherAspectFound:Bool = false;

                for (id in otherAspectPtrs.keys()) {
                    var ptr:AspectPtr = otherAspectPtrs[id];
                    if (column.value[ptr] > 0) {
                        otherAspectFound = true;
                        str += otherNodeAspects[id];
                        break;
                    }
                }

                if (!otherAspectFound) {
                    var occupier:Null<Int> = column.value[occupier_];
                    var isFilled:Null<Int> = column.value[isFilled_];

                    if (occupier == null) str += 'n';
                    else if (occupier != Aspect.NULL && isFilled == Aspect.FALSE) str += String.fromCharCode(ALPHABET() + occupier);
                    else if (occupier != Aspect.NULL) str += '' + occupier;
                    else if (isFilled == Aspect.TRUE) str += 'X';
                    else if (isFilled == Aspect.FALSE && occupier == Aspect.NULL) str += ' ';
                }
            }
        }

        if (addSpaces) str = ADD_SPACES.replace(str, '$1 ');

        return str;
    }
}
