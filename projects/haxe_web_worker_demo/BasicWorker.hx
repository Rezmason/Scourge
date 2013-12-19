class BasicWorker {

    public function new() {
        untyped __js__('self').onmessage = onMessage;
    }

    public function onMessage( e : Dynamic ) : Void { }

    public inline function postMessage( m : Dynamic ) : Void {
        untyped __js__('self').postMessage( m );
    }
}
