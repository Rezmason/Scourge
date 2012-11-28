package net.rezmason.utils;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;
#end

class Siphon {

    @:macro public static function getDefs(pkg:String = null, base:String = null, filterPattern:String = null) {

        var filter:EReg = null;
        if (filterPattern != null) filter = new EReg(filterPattern, "");

        if (pkg == null) pkg = "";

        var pos:Position = Context.currentPos();

        if (base == null) {
            var posString:String = Context.getPosInfos(pos).file;
            base = posString.substr(0, posString.indexOf("/"));
        }

        var path:String = base + "/" + pkg.split(".").join("/");
        if (pkg.length > 0) pkg += ".";

        var decExpr:Expr = macro var hash:Hash<Class<Dynamic>> = new Hash<Class<Dynamic>>();
        var retExpr:Expr = macro hash;

        var setExprs:Array<Expr> = [];

        var files:Array<String> = FileSystem.readDirectory(path);
        for (file in files) {
            var clazz:String = file;
            var hxIndex:Int = clazz.indexOf(".hx");
            if (hxIndex == -1) continue;
            clazz = clazz.substring(0, hxIndex);

            if (filter != null && !filter.match(clazz)) continue;

            var inf = {min:setExprs.length, max:setExprs.length, file:pkg + clazz};
            var clazzDef:Expr = Context.parse(pkg + clazz, Context.makePosition(inf));
            //trace(clazzDef); // EField(EField(EField(EConst(CIdent("path")), "to"), "my"), "Class")

            var expr:Expr = macro hash.set($(clazz), cast $clazzDef );
            setExprs.push(expr);
        }

        var block:Array<Expr> = [decExpr].concat(setExprs).concat([retExpr]);

        return {expr:EBlock(block), pos:pos};
    }
}
