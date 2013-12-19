package net.rezmason.utils;

class TestWorker extends BasicWorker<Int, String> {

    static var worker:TestWorker = new TestWorker();

    static function main():Void {}

    override function receive(data:Int):Void {
        if (data == -1) sendError('BLARG');
        else send(Std.string(data));
    }
}
