package net.rezmason.praxis;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.grid.Cell;
import net.rezmason.grid.Grid;
import net.rezmason.grid.Selection;
import net.rezmason.praxis.rule.BaseRule;

using net.rezmason.utils.History;
using net.rezmason.utils.pointers.Pointers;

private typedef Atom = Null<Int>; // Our low-level value type

typedef AspectPointer<T> = Pointer<Atom,T>;
typedef AspectWritePointer<T> = WritePointer<Atom,T>;
typedef AspectPointable<T> = Pointable<Atom,T>; // The properties of an element of the state
typedef AspectIterator<T> = PointerIterator<Atom,T>;

typedef AspectProperty<T> = { var id(default, null):String; var initialValue(default, null):Atom; }; // The distinct possible properties of our state
typedef AspectRequirements<T> = Map<String, AspectProperty<T>>;
typedef AspectLookup<T> = Map<String, AspectWritePointer<T>>; // The indices of property types in the AspectPointable of an element
typedef AspectSource<T> = PointerSource<Atom,T>;

typedef Move = {id:Int, ?relatedID:Int, ?weight:Float};
typedef SavedState = {data:String};
typedef StateHistory = History<Atom>;
typedef Rule = BaseRule<Dynamic>;

abstract PGlobal({}) {}
abstract PPlayer({}) {}
abstract PSpace({}) {}
abstract PCard({}) {}
abstract PExtra({}) {}

typedef Global = AspectPointable<PGlobal>;
typedef Player = AspectPointable<PPlayer>;
typedef Space = AspectPointable<PSpace>;
typedef Card = AspectPointable<PCard>;
typedef Extra = AspectPointable<PExtra>;

typedef BoardCell = Cell<Space>;
typedef BoardGrid = Grid<Space>;
typedef BoardSelection = Selection<Space>;
