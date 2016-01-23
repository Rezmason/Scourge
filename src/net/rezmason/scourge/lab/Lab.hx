package net.rezmason.scourge.lab;

class Lab {
    var width:Int;
    var height:Int;
    public function new(width:Int, height:Int):Void {
        this.width = width;
        this.height = height;
    }

    function update():Void {}
    function draw():Void {}

    public function render():Void {
        update();
        draw();
    }
}
