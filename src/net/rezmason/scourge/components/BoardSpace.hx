package net.rezmason.scourge.components;

import net.rezmason.ropes.RopesTypes.AspectSet;
import net.rezmason.ecce.Component;

class BoardSpace extends Component {

    public var ident:Int;
    public var values:AspectSet;
    public var lastValues:AspectSet;

    /*
    override function copyFrom(other:Component) {
        if (other != null) {
            // this.x = other.x;
        }
    }
    */
}
