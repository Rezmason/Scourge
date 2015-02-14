package net.rezmason.praxis.play;

enum GameEvent {
    SubmitMove(turn:Int, action:String, move:Int);
    Init(config:String, ?savedState:String);
    RelayMove(turn:Int, action:String, move:Int);
    Time(mils:Int);
    End;
}
