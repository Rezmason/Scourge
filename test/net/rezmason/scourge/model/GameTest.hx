package net.rezmason.scourge.model;

import massive.munit.util.Timer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;

import net.rezmason.scourge.model.ScourgeConfigMaker;

/**
* Auto generated MassiveUnit Test Class
*/
class GameTest
{


	public function new()
	{

	}

	@BeforeClass
	public function beforeClass():Void
	{
	}

	@AfterClass
	public function afterClass():Void
	{
	}

	@Before
	public function setup():Void
	{
	}

	@After
	public function tearDown():Void
	{
	}


	@Test
	public function testExample():Void
	{
		var configMaker = new ScourgeConfigMaker();
		var stateHistorian = new StateHistorian();
		var basicRules:Hash<Rule> = RuleFactory.makeBasicRules(configMaker.makeConfig(stateHistorian.history, stateHistorian.historyState));
		var combinedRules:Hash<Rule> = RuleFactory.combineRules(ScourgeConfigMaker.combinedRuleCfg, basicRules);
		for (action in ScourgeConfigMaker.actionList) Assert.isNotNull(combinedRules.get(action));
	}
}
