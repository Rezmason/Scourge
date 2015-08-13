package net.rezmason.utils.openfl;

#if (openfl || lime)
    import lime.Assets;
#end

class Resource {
    public inline static function getString(path:String):String {
        return #if (openfl || lime) Assets.getText #else haxe.Resource.getString #end (path);
    }
}
