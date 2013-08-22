package net.rezmason.scourge.textview;

import net.rezmason.ropes.Types.Move;
import net.rezmason.scourge.controller.Operation;

using Lambda;

class Interpreter {

    public function new():Void {

    }

    public function run(input:String, hinting:Bool):Command {

        var allMoves:Array<Array<Move>> = [[],[],[],[]];
        var operations:Map<String, Operation> = [
            'bite' => new Operation(0, new Map()),
            'drop' => new Operation(1, new Map()),
            'swap' => new Operation(2, new Map()),
            'skip' => new Operation(3, new Map()),
        ];

        // input string is free of syles and hint data

        if (input == null || input.length == 0) return EMPTY;

        var opName:String = input;
        var spcIndex:Int = input.indexOf(' ');
        if (spcIndex != -1) opName = input.substr(0, spcIndex);

        if (opName == 'msg') {
            //     style the opName as a opName
            //     style
            return CHAT(input.substr(opName.length + 1));
        }

        var op:Operation = operations[opName];
        if (op == null) {
            //     style the opName as invalid
            //     style the rest as dim invalid
            return ERROR('UNRECOGNIZED COMMAND $opName');
        }

        // style the opName as a opName

        var stack:Array<String> = input.split(' ');
        stack.reverse();
        stack.pop();

        var filteredMoves = allMoves[op.index].copy();

        var keys:Array<String> = [];

        while (stack.length > 0) {
            var key:String = stack.pop();
            var value:String = stack.pop();

            if (!op.hasParam(key)) {
                //    style key as invalid
                //    style the rest as dim invalid
                return ERROR('UNRECOGNIZED PARAM $key');
            }

            filteredMoves = op.applyFilter(key, value, filteredMoves);

            if (filteredMoves == null) {
                //    style value as invalid
                //    style the rest as dim invalid
                return ERROR('INVALID VALUE $value FOR PARAM $key');
            }

            keys.push(key);

            //    style key as a param
            //    style value as a value
        }

        if (hinting) {
            var hint:String = '';
            for (paramName in op.params) {
                if (!keys.has(paramName)) {
                    //     style as a "hint button"
                    hint += ' $paramName';
                }
            }
        } else {
            if (filteredMoves.length == 1) return COMMIT('MOVE: ${filteredMoves[0]}');
            else return LIST(filteredMoves.map(printMove));
        }

        return null;
    }

    function printMove(move:Move):String {
        var str:String = '';
        for (field in Reflect.fields(move)) str += '$field : ${Reflect.field(move, field)},';
        return '[$str]';
    }
}
