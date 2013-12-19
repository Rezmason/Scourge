package net.rezmason.utils;

import haxe.io.Bytes;

#if flash
    import flash.events.Event;
    import flash.utils.ByteArray;
    import flash.system.MessageChannel;
    import flash.system.Worker;
    import flash.system.WorkerDomain;
#end

class BasicWorkerAgency<T, U> {

    var worker:Worker;

    #if flash
        var incoming:MessageChannel;
        var outgoing:MessageChannel;
    #end

    public function new(bytes:Bytes):Void {
        #if flash
            worker = WorkerDomain.current.createWorker(bytes.getData());
            incoming = worker.createMessageChannel(Worker.current);
            outgoing = Worker.current.createMessageChannel(worker);
            worker.setSharedProperty("incoming", outgoing);
            worker.setSharedProperty("outgoing", incoming);
            incoming.addEventListener(Event.CHANNEL_MESSAGE, onIncoming);
        #elseif js
            var blob = new Blob([bytes.toString()]);
            var url:String = untyped __js__('window').URL.createObjectURL(blob);
            worker = new Worker(url);
            worker.addEventListener('message', onIncoming);
        #end
    }

    public function start():Void {
        #if flash
            worker.start();
        #end
    }

    public function die():Void {
        #if (flash || js)
            worker.terminate();
        #end
    }

    public function send(data:T):Void {
        #if flash
            outgoing.send(data);
        #elseif js
            worker.postMessage(data);
        #end
    }

    function receive(data:U):Void {}

    function onIncoming(event:Dynamic):Void {
        var data:Dynamic = null;
        #if flash
            data = incoming.receive();
        #elseif js
            data = event.data;
        #end

        if (Reflect.hasField(data, '__error')) onErrorIncoming(data.__error);
        else receive(data);
    }

    function onErrorIncoming(error:Dynamic):Void throw error;
}

#if js
    @:native("Blob")
    extern class Blob {
       public function new(strings:Array<String> ) : Void;
    }

    @:native("Worker")
    extern class Worker {
        public function new(script:String):Void;
        public function postMessage(msg:Dynamic):Void;
        public function addEventListener(type:Dynamic, cb:Dynamic->Void):Void;
        public function terminate():Void;
    }
#end
