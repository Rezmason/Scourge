package net.rezmason.ropes.config;

enum RuleType<MovePresenter> {
    Simple;
    Builder;
    Action(presenter:Class<MovePresenter>);
}
