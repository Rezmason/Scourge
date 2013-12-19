class BasicWorkerTest {
    public static function main():Void {
        var agency:TestAgency = new TestAgency(function(s:String) trace(s));
        agency.send('coucou');
    }
}

class TestAgency extends BasicWorkerAgency<String, String> {

    var onReceive:String->Void;

    public function new(onReceive:String->Void):Void {
        this.onReceive = onReceive;
        super('testworker.js');
    }

    override function receive(data:String):Void onReceive(data);
}
