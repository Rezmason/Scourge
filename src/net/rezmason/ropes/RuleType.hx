package net.rezmason.ropes;

enum RuleType<MovePresenter> {
    Simple;
    Builder;
    Action(presenter:Class<MovePresenter>);
}
