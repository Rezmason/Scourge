package net.rezmason.praxis.play;

enum GameEvent {
    Proceed(turn:Int);
    Init(config:String, ?savedState:String);
    SubmitMove(turn:Int, action:String, move:Int);
    Time(mils:Int);
    End;
}
