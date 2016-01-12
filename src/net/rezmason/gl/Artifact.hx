package net.rezmason.gl;

class Artifact {
    public var isDisposed(default, null):Bool = false;
    public function dispose() isDisposed = true;
}
