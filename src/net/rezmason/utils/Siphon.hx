package net.rezmason.utils;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;
#end

class Siphon {

    macro public static function getDefs(pkg:String = null, base:String = null, filterPattern:String = null) {

        var filter:EReg = null;
        if (filterPattern != null) filter = new EReg(filterPattern, "");

        if (pkg == null) pkg = "";
        var pkgArray:Array<String> = pkg.split(".");

        var pos:Position = Context.currentPos();

        if (base == null) {
            var posString:String = Context.getPosInfos(pos).file;
            base = posString.substr(0, posString.indexOf("/"));
        }

        var path:String = base + "/" + pkgArray.join("/");

        var decExpr:Expr = macro var hash:StringMap<Class<Dynamic>> = new StringMap<Class<Dynamic>>();
        var retExpr:Expr = macro hash;

        var setExprs:Array<Expr> = [];

        var files:Array<String> = FileSystem.readDirectory(path);
        for (file in files) {
            var clazz:String = file;
            var hxIndex:Int = clazz.indexOf(".hx");
            if (hxIndex > -1) {
                clazz = clazz.substring(0, hxIndex);
                if (filter == null || filter.match(clazz)) {
                    setExprs.push(macro hash.set($v{clazz}, cast $p{pkgArray.concat([clazz])}));
                }
            }
        }

        return macro $b{[decExpr].concat(setExprs).concat([retExpr])};
    }
}
