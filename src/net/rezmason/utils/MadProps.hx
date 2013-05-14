package net.rezmason.utils;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;
using Lambda;
#end

class MadProps {

    macro public static function giveProps(metatag:String) {
        var fields = Context.getLocalClass().get().fields.get().filter(function (f) return f.meta.has(metatag));
        var names = fields.map(function (f) return macro $v{f.name});
        return macro [$a{names}];
    }
}
