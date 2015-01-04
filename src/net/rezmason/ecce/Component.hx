package net.rezmason.ecce;

@:allow(net.rezmason.ecce)
class Component {

    function copyFrom(other:Component) {
        if (other != null) for (field in Reflect.fields(this)) {
            Reflect.setField(this, field, Reflect.field(other, field));
        }
    }
}
