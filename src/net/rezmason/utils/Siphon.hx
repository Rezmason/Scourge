package net.rezmason.utils;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;
#end

class Siphon {

    macro public static function getDefs(pkg:String = null, base:String = null, classFilter:String = null) {

        var exprs:Array<Expr> = [];

        // The default package is the top-level package
        if (pkg == null) pkg = "";
        var pkgArray:Array<String> = pkg.split(".");

        // The default base is the source folder of the Siphon file
        if (base == null) base = Context.getPosInfos(Context.currentPos()).file;
        var path:String = base.split("/")[0] + "/" + pkgArray.join("/");

        // The default regex matches all file names
        if (classFilter == null) classFilter = "";
        var classEReg:EReg = new EReg(classFilter, "");

        // Here are the .hx files in the specified source folder and package that match the specified filter
        var files:Array<String> = FileSystem.readDirectory(path).filter(classEReg.match).filter(~/\.hx$/.match);

        // We assume that there is one class in each file, with the same name as the file
        // We also assume that none of the classes have the same name– they're in the same package, after all
        for (file in files) {
            var clazz:String = file.split(".")[0];
            var keyValueExpr:Expr = macro $v{clazz} => cast($p{pkgArray.concat([clazz])}, Class<Dynamic>);
            exprs.push(keyValueExpr);
        }

        return macro [$a{exprs}];
    }
}
