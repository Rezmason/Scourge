package net.rezmason.scourge.model;

enum RuleType<MovePresenter> {
    Simple;
    Builder;
    Action(presenter:Class<MovePresenter>);
}
