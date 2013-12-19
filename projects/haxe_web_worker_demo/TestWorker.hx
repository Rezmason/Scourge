class TestWorker extends BasicWorker {

    static function main():Void {}

    static var worker:TestWorker = new TestWorker();

    public override function onMessage(e) {
        // trace("on message triggered");
        postMessage('ola');
    }
}
