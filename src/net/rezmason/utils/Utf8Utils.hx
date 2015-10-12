package net.rezmason.utils;

import haxe.Utf8;

class Utf8Utils {
    public inline static function lpad(input:String, pad:String, len:Int):String {
        len = len - length(input);
        var str:String = '';
        while (length(str) < len) str = str + pad;
        return str + input;
    }

    public inline static function rpad(input:String, pad:String, len:Int):String {
        len = len - length(input);
        var str:String = '';
        while (length(str) < len) str = str + pad;
        return input + str;
    }

    public inline static function cpad(input:String, pad:String, len:Int):String {
        len = len - length(input);
        var itr:Int = 0;
        var leftStr:String = '';
        var rightStr:String = '';
        while (length(leftStr) + length(rightStr) < len) {
            if (itr % 2 == 0) rightStr = rightStr + pad;
            else leftStr = leftStr + pad;
            itr++;
        }
        return leftStr + input + rightStr;
    }

    public inline static function jpad(input:String, pad:String, len:Int):String {

        input = trim(input, pad);

        var output:String = '';
        var delta:Int = len - length(input);

        if (delta == len) {
            output = rpad(input, pad, len);
        } else if (delta > 0) {
            var pieces:Array<String> = [];
            var spaceCode:Int = ' '.charCodeAt(0);
            var lastCode:Int = 0;
            var start:Int = 0;
            var end:Int = 0;
            var reachedNonSpace:Bool = false;
            Utf8.iter(input, function(code:Int) {
                if (lastCode == spaceCode && code != spaceCode) {
                    if (reachedNonSpace) pieces.push(sub(input, start, end - start));
                    start = end;
                }
                if (code != spaceCode) reachedNonSpace = true;
                lastCode = code;
                end++;
            });
            if (start < end) pieces.push(sub(input, start, end - start));
            var lastPiece:String = pieces.pop();
            var numPieces:Int = pieces.length;

            if (numPieces > 0) {
                var itr:Int = 0;
                for (ike in 0...delta) {
                    var index:Int = Std.int((numPieces - itr * (itr % 2 * 2 - 1) - numPieces % 2) / 2);
                    pieces[index] = pieces[index] + pad;
                    itr = (itr + 1) % numPieces;
                }

                for (piece in pieces) output = output + piece;
            }

            output = output + lastPiece;
        } else {
            output = input;
        }

        return output;
    }

    public inline static function sub(input:String, pos:Int, len:Int = -1):String {
        var output:String = '';
        if (len == -1) len = length(input);
        if (input != '' && len > 0 && pos < length(input)) {
            output = Utf8.sub(input, pos, length(input));
            output = Utf8.sub(output, 0, len);
        }
        return output;
    }

    public inline static function charAt(input:String, pos:Int):String return sub(input, pos, 1);

    public inline static function length(input:String):Int {
        var output:Int = 0;
        if (input != '') output = Utf8.length(input);
        return output;
    }

    public inline static function trim(input:String, char:String = ' '):String {
        return ltrim(rtrim(input, char), char);
    }

    public inline static function ltrim(input:String, char:String = ' '):String {
        if (length(input) > 0) while (charAt(input, 0) == char) input = sub(input, 1);
        return input;
    }

    public inline static function rtrim(input:String, char:String = ' '):String {
        if (length(input) > 0) while (charAt(input, length(input) - 1) == char) input = sub(input, 0, length(input) - 1);
        return input;
    }

    public inline static function fromCharCode(code:Int):String {
        var u = new Utf8();
        u.addChar(code);
        return u.toString();
    }
}
