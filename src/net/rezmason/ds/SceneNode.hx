package net.rezmason.ds;

class SceneNode<T:(SceneNode<T>)> {

    public var parent(default, null):T;
    public var root(get, null):T;
    
    var childMap:Map<T, T>;

    public inline function new():Void childMap = new Map();

    public function addChild(node:T):Bool {
        var success = false;
        if (node != null) {
            if (node == this) throw 'A SceneNode<T> cannot be added to itself.';
            if (node.contains(cast this)) throw 'A SceneNode<T> cannot be added to a SceneNode<T> that it contains.';
            if (!childMap.exists(node)) {
                childMap.set(node, node);
                if (node.parent != null) node.parent.removeChild(node);
                node.parent = cast this;
                success = true;
            }
        }
        return success;
    }

    public function removeChild(node:T):Bool {
        var success = false;
        if (childMap.exists(node)) {
            success = true;
            childMap.remove(node);
            node.parent = null;
        }
        return success;
    }

    public inline function removeChildren():Void for (child in childMap) removeChild(child);

    public inline function children():Iterator<T> return childMap.iterator();

    public inline function lineage():Iterator<T> {
        var node:T = cast this;
        function hasNext() return node.parent != null;
        function next() {
            var child = node;
            node = node.parent;
            return child;
        }
        return {hasNext:hasNext, next:next};
    }

    public inline function contains(node:T):Bool {
        var found:Bool = false;
        while (node != null) {
            if (node == this) {
                found = true;
                break;
            }
            node = node.parent;
        }
        return found;
    }

    inline function get_root():T {
        var node:T = cast this;
        while (node.parent != null) node = node.parent;
        return node;
    }
}
