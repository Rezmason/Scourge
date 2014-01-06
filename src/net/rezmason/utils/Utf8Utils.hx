package net.rezmason.utils;

import haxe.Utf8;

class Utf8Utils {
    public inline static function rpad(input:String, pad:String, len:Int):String {
        len = len - length(input);
        var str:String = '';
        while (str.length < len) str = str + pad;
        return input + str;
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
        while (charAt(input, 0) == char) input = sub(input, 1);
        return input;
    }

    public inline static function rtrim(input:String, char:String = ' '):String {
        while (charAt(input, length(input) - 1) == char) input = sub(input, 0, length(input) - 1);
        return input;
    }
}
