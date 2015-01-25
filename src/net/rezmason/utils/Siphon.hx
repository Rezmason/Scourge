package net.rezmason.utils;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;
#end

class Siphon {

    macro public static function getDefs(pkg:String, base:String, recursive:Bool = false, classFilter:String = null):Expr {

        var exprs:Array<Expr> = [];

        var pkgArray:Array<String> = pkg.split('.');
        while (base.charAt(base.length - 1) == '/') base = base.substr(0, base.length - 1);
        var path:String = base + '/' + pkgArray.join('/');

        // The default regex matches all file names
        if (classFilter == null) classFilter = '';
        var classEReg:EReg = new EReg(classFilter, '');

        // Here are the .hx files in the specified source folder and package 
        // (and optionally its subpackages) that match the specified filter
        var dirs:Array<String> = recursive ? getSubdirectories(path) : [path];
        var packagedClassNames:Array<String> = [];
        for (dir in dirs) {
            for (file in FileSystem.readDirectory(dir).filter(classEReg.match).filter(~/\.hx$/.match)) {
                var className:String = file.substr(0, file.length - '.hx'.length);
                var classPackage:String = ~/\//g.replace(dir, '.');
                classPackage = classPackage.substr(base.length + 1);
                if (classPackage.length > 0) classPackage += '.';
                packagedClassNames.push(classPackage + className);
            }
        }

        // We assume that there is one class in each file, with the same name as the file
        for (pcn in packagedClassNames) {
            var keyValueExpr:Expr = macro $v{pcn} => cast($p{pcn.split('.')}, Class<Dynamic>);
            exprs.push(keyValueExpr);
        }
        
        if (exprs.length == 0) return macro cast new haxe.ds.StringMap();

        return macro cast [$a{exprs}];
    }

    #if macro
        static inline function getSubdirectories(root:String):Array<String> {
            var dirPaths:Array<String> = [root];
            var itr:Int = 0;
            while (itr < dirPaths.length) {
                for (path in FileSystem.readDirectory(dirPaths[itr])) {
                    var fullPath:String = '${dirPaths[itr]}$path';
                    if (FileSystem.isDirectory(fullPath)) dirPaths.push('$fullPath/');
                }
                itr++;
            }
            return dirPaths;
        }
    #end
}
