package net.rezmason.scourge.model;

import net.rezmason.ropes.aspect.Aspect.*;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.GridDirection.*;
import net.rezmason.ropes.GridLocus;
import net.rezmason.ropes.state.State;
import net.rezmason.ropes.state.StatePlan;
import net.rezmason.scourge.model.body.OwnershipAspect;

using net.rezmason.ropes.GridUtils;

class BoardUtils {

    private inline static function ALPHABET():Int { return 'a'.charCodeAt(0); }

    private static var ADD_SPACES:EReg = ~/([^\n\t])/g;

    public inline static function grabXY(state:State, east:Int, south:Int):BoardLocus {
        return state.loci[0].run(NW).run(W).run(N).run(S, south).run(E, east);
    }

    public static function spitBoard(state:State, plan:StatePlan, addSpaces:Bool = true, evaluator:AspectSet->String = null):String {
        if (state.loci.length == 0) return 'empty grid';

        var str:String = '';

        var grid:BoardLocus = state.loci[0].run(NW).run(W).run(N);

        var occupier_:AspectPtr = plan.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = plan.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];

        for (row in grid.walk(S)) {
            str += '\n';
            for (column in row.walk(E)) {
                var char:String = null;
                if (evaluator != null) char = evaluator(column.value);
                if (char == null) {
                    var occupier:Null<Int> = column.value[occupier_];
                    var isFilled:Null<Int> = column.value[isFilled_];

                    if (occupier == null) char = 'n';
                    else if (occupier != NULL && isFilled == FALSE) char = String.fromCharCode(ALPHABET() + occupier);
                    else if (occupier != NULL) char = '' + occupier;
                    else if (isFilled == TRUE) char = 'X';
                    else if (isFilled == FALSE && occupier == NULL) char = ' ';
                }

                str += char;
            }
        }

        if (addSpaces) str = ADD_SPACES.replace(str, '$1 ');

        return str;
    }
}
