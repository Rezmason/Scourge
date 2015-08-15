package net.rezmason.scourge.game;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.grid.GridDirection.*;
import net.rezmason.grid.Cell;
import net.rezmason.praxis.state.State;
import net.rezmason.praxis.state.StatePlan;
import net.rezmason.scourge.game.body.OwnershipAspect;
import net.rezmason.utils.Pointers;

using net.rezmason.grid.GridUtils;

class BoardUtils {

    private inline static function ALPHABET():Int { return 'a'.charCodeAt(0); }

    private static var ADD_SPACES:EReg = ~/([^\n\t])/g;

    public inline static function grabXY(state:State, east:Int, south:Int):BoardCell {
        return state.cells[0].run(NW).run(W).run(N).run(S, south).run(E, east);
    }

    public static function spitBoard(state:State, plan:StatePlan, addSpaces:Bool = true, focus:Array<Int> = null):String {
        if (state.cells.length == 0) return 'empty grid';

        var str:String = '';

        var grid:BoardCell = state.cells[0].run(NW).run(W).run(N);

        var occupier_:AspectPtr = plan.spaceAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = plan.spaceAspectLookup[OwnershipAspect.IS_FILLED.id];
        var ident_:AspectPtr = Ptr.intToPointer(0, state.key);

        for (row in grid.walk(S)) {
            str += '\n';
            for (column in row.walk(E)) {
                var char:String = null;
                if (focus != null && focus.indexOf(column.value[ident_]) != -1) char = '@';
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
