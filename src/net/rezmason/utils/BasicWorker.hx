package net.rezmason.utils;

#if flash
    import flash.events.Event;
    import flash.system.MessageChannel;
    import flash.system.Worker;
#end

#if flash
    typedef Boss = Worker;
#end

class BasicWorker<T, U> {

    #if flash
        var incoming:MessageChannel;
        var outgoing:MessageChannel;
    #elseif js
        var self:Dynamic;
    #end

    public function new():Void {
        #if flash
            incoming = Boss.current.getSharedProperty('incoming');
            outgoing = Boss.current.getSharedProperty('outgoing');
            incoming.addEventListener(Event.CHANNEL_MESSAGE, onIncoming);
        #elseif js
            self = untyped __js__('self');
            self.onmessage = onIncoming;
        #end
    }

    @:final function send(data:U):Void {
        #if flash
            outgoing.send(data);
        #elseif js
            self.postMessage(data);
        #end
    }

    @:final function sendError(error:Dynamic):Void {
        var data:Dynamic = {__error:error};
        #if flash
            outgoing.send(data);
        #elseif js
            self.postMessage(data);
        #end
    }

    @:final function onIncoming(event:Dynamic):Void {
        #if flash
            receive(incoming.receive());
        #elseif js
            receive(event.data);
        #end
    }

    function receive(data:T):Void {}
}
