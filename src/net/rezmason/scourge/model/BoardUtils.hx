package net.rezmason.scourge.model;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.GridNode;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using net.rezmason.scourge.model.GridUtils;

class BoardUtils {

    private static var ADD_SPACES:EReg = ~/([^\n\t])/g;

    public static function spitGrid(head:BoardNode, history:History<Int>, addSpaces:Bool = true):String {
        var str:String = "";

        var grid:BoardNode = head.run(Gr.nw).run(Gr.w).run(Gr.n);

        for (row in grid.walk(Gr.s)) {
            str += "\n";
            for (column in row.walk(Gr.e)) {
                var ownerAspect:OwnershipAspect = cast column.value.get(OwnershipAspect.id);
                str += switch (true) {
                    case (history.get(ownerAspect.occupier) > -1): "" + history.get(ownerAspect.occupier);
                    case (history.get(ownerAspect.isFilled) == 1): "X";
                    default: " ";
                }
            }
        }

        if (addSpaces) str = ADD_SPACES.replace(str, "$1 ");

        return str;
    }
}
