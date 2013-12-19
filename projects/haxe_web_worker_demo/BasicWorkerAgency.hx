import haxe.Resource;

class BasicWorkerAgency<T, U> {
    var worker:Worker;

    public function new(resourceID:String):Void {
        var blob = new Blob([Resource.getBytes(resourceID).toString()]);
        var url:String = untyped __js__('window').URL.createObjectURL(blob);
        worker = new Worker(url);
        worker.addEventListener('message', onIncoming);
    }

    public function send(data:T):Void worker.postMessage(data);
    function receive(data:U):Void {}
    function onIncoming(event:Dynamic):Void receive(event.data);
}

@:native("Blob")
extern class Blob {
   public function new(strings:Array<String> ) : Void;
}


@:native("Worker")
extern class Worker {
    public function new(script:String):Void;
    public function postMessage(msg:Dynamic):Void;
    public function addEventListener(type:Dynamic, cb:Dynamic->Void):Void;
}
