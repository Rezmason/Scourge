package net.rezmason.utils;

import flash.events.Event;
import flash.system.MessageChannel;
import flash.system.Worker;

class TempWorker<T, U> {

    var worker:Worker;
    var incoming:MessageChannel;
    var outgoing:MessageChannel;
    var process:T->U;

    public function new(process:T->U):Void {
        this.process = process;
        worker = Worker.current;
        incoming = worker.getSharedProperty("incoming");
        outgoing = worker.getSharedProperty("outgoing");
        incoming.addEventListener(Event.CHANNEL_MESSAGE, onIncoming);
    }

    function onIncoming(event:Event):Void {
        outgoing.send(process(incoming.receive()));
    }
}
