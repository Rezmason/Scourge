package net.rezmason.scourge.components;

import net.rezmason.ecce.Component;
import net.rezmason.ecce.Entity;

class GlyphAnimation extends Component {

    public var index:Int;
    public var duration:Float;
    public var overlap:Float;
    public var startTime:Float;
    public var subject:Entity;

    /*
    override function copyFrom(other:Component) {
        if (other != null) {
            // this.x = other.x;
        }
    }
    */
}
