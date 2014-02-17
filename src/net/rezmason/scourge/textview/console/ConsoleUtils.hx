package net.rezmason.scourge.textview.console;

import net.rezmason.scourge.textview.console.ConsoleTypes;

class ConsoleUtils {

    public static function startsWith(arg:String, sub:String):Bool return arg.indexOf(sub) == 0;

    public static function argToHint(arg:String, type:ConsoleTokenType):ConsoleToken return {text:arg, type:type};

    public inline static function blankState():ConsoleState {
        var tok = blankToken();
        return {input:tok, output:null, hint:null, currentToken:tok, caretIndex:0};
    }

    public inline static function blankToken(prev:ConsoleToken = null, next:ConsoleToken = null):ConsoleToken {
        return {text:'', type:null, prev:prev, next:next};
    }

    public inline static function styleError(str:String):String return '§{${Strings.ERROR_OUTPUT_STYLENAME}}$str§{}';
}
