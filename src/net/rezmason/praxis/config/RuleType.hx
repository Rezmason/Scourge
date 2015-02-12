package net.rezmason.praxis.config;

enum RuleType<MovePresenter> {
    Simple;
    Builder;
    Action(presenter:Class<MovePresenter>);
}
