package net.rezmason.utils;

class TestWorker extends BasicWorker<Int, String> {

    #if (flash || js)
        static var worker:TestWorker = new TestWorker();
    #end

    static function main():Void {}

    override function receive(data:Int):Void {
        if (data == -1) sendError('BLARG');
        else send(Std.string(data));
    }
}
