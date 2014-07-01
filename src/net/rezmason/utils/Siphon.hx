package net.rezmason.utils;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;
#end

class Siphon {

    macro public static function getDefs(pkg:String, base:String, classFilter:String = null):Expr {

        var exprs:Array<Expr> = [];

        var pkgArray:Array<String> = pkg.split('.');
        while (base.charAt(base.length - 1) == '/') base = base.substr(0, base.length - 1);
        var path:String = base + '/' + pkgArray.join('/');

        // The default regex matches all file names
        if (classFilter == null) classFilter = '';
        var classEReg:EReg = new EReg(classFilter, '');

        // Here are the .hx files in the specified source folder and package that match the specified filter
        var files:Array<String> = FileSystem.readDirectory(path).filter(classEReg.match).filter(~/\.hx$/.match);

        // We assume that there is one class in each file, with the same name as the file
        // We also assume that none of the classes have the same name– they're in the same package, after all
        for (file in files) {
            var clazz:String = file.split('.')[0];
            var keyValueExpr:Expr = macro $v{clazz} => cast($p{pkgArray.concat([clazz])}, Class<Dynamic>);
            exprs.push(keyValueExpr);
        }

        return macro [$a{exprs}];
    }

    macro public static function getClassName(classExpr) {
        var clazz:String = null;
        switch (classExpr.expr) {
            case EField(expr, field): clazz = field;
            case EConst(CIdent(field)): clazz = field;
            case _: throw 'Siphon.getClassName only works with classes.';
        }

        try {
            Context.getType(clazz);
        } catch (error:Dynamic) {
            trace('$clazz: $error');
            clazz = null;
        }

        return macro $v{clazz};
    }
}
