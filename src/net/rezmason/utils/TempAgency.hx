package net.rezmason.utils;

import flash.events.Event;
import flash.utils.ByteArray;
import flash.system.MessageChannel;
import flash.system.Worker;
import flash.system.WorkerDomain;
import haxe.Timer;

class TempAgency<T, U> {

    var queue:Array<U->Void>;
    var started:Bool;

    var worker:Worker;
    var incoming:MessageChannel;
    var outgoing:MessageChannel;
    var shutdownTime:Int;
    var shutdownTimer:Timer;

    public function new(bytes:ByteArray, shutdownTime:Int = 5000):Void {
        this.shutdownTime = shutdownTime;
        started = false;
        queue = [];

        worker = WorkerDomain.current.createWorker(bytes);
        incoming = worker.createMessageChannel(Worker.current);
        outgoing = Worker.current.createMessageChannel(worker);
        worker.setSharedProperty("incoming", outgoing);
        worker.setSharedProperty("outgoing", incoming);
        incoming.addEventListener(Event.CHANNEL_MESSAGE, onIncoming);
        startup();
    }

    public function addWork(work:T, recip:U->Void):Void {
        queue.push(recip);
        outgoing.send(work);
        cancelShutdown();
        startup();
    }

    function onIncoming(event:Event):Void {
        while (incoming.messageAvailable) queue.shift()(incoming.receive());
        if (queue.length == 0) beginShutdown();
    }

    inline function startup():Void {
        if (!started) {
            started = true;
            worker.start();
        }
    }

    inline function beginShutdown():Void {
        shutdownTimer = new Timer(shutdownTime);
        shutdownTimer.run = onShutdown;
    }

    inline function onShutdown():Void {
        shutdownTimer = null;
        worker.terminate();
        started = false;
    }

    inline function cancelShutdown():Void {
        if (shutdownTimer != null) {
            shutdownTimer.stop();
            shutdownTimer = null;
        }
    }
}
