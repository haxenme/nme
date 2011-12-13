package org.haxenme.unittesting.tests;


import haxe.unit.TestCase;


/**
 * ...
 * @author Joshua Granick
 */

class MathTest extends TestCase {

	
	public function testAtan2 () {
		
		assertEquals (Math.atan2 (100, 10), 1.4711276743037347);
		assertEquals (Math.atan2 (-12.7, 2.5), -1.3764310606998786);
		assertEquals (Math.atan2 (0, -7), 3.141592653589793);
		assertEquals (Math.atan2 (-100, -10), -1.6704649792860586);
		assertEquals (Math.atan2 (3.14, -3.14), 2.356194490192345);
		assertEquals (Math.atan2 (17.7777777, 0.3333333), 1.552048525389491);
		assertEquals (Math.atan2 (-1, -2), -2.677945044588987);
		
	}
	
	
}