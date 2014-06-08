package net.rezmason.utils;

class CharCode {

    macro public static function code(char:String) return macro $v{haxe.Utf8.charCodeAt(char, 0)};
}
