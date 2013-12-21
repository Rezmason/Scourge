package net.rezmason.utils;

#if flash
    import flash.system.MessageChannel;
    import flash.system.Worker;
#end

class BasicWorker<T, U> {

    #if flash
        var incoming:MessageChannel;
        var outgoing:MessageChannel;
    #elseif js
        var self:Dynamic;
    #elseif (neko || cpp)
        var dead:Bool;
        var outgoing:U->Void;
    #end

    public function new():Void {
        #if flash
            incoming = Worker.current.getSharedProperty('incoming');
            outgoing = Worker.current.getSharedProperty('outgoing');
            incoming.addEventListener('channelMessage', onIncoming);
        #elseif js
            self = untyped __js__('self');
            self.onmessage = onIncoming;
        #elseif (neko || cpp)
            dead = false;
        #end
    }

    @:final function send(data:U):Void {
        #if flash
            outgoing.send(data);
        #elseif js
            self.postMessage(data);
        #elseif (neko || cpp)
            outgoing(data);
        #end
    }

    @:final function sendError(error:Dynamic):Void {
        var data:Dynamic = {__error:error};
        #if flash
            outgoing.send(data);
        #elseif js
            self.postMessage(data);
        #elseif (neko || cpp)
            outgoing(data);
        #end
    }

    @:final function onIncoming(data:Dynamic):Void {
        #if flash
            data = incoming.receive();
        #elseif js
            data = data.data;
        #elseif (neko || cpp)
            if (data == '__die__') {
                dead = true;
                return;
            }
        #end

        receive(data);
    }

    function receive(data:T):Void {}

    #if (neko || cpp)
        @:allow(net.rezmason.utils.BasicWorkerAgency)
        function breathe(fetch:Void->T, outgoing:U->Void):Void {
            this.outgoing = outgoing;
            while (!dead) onIncoming(fetch());
        }
    #end
}
