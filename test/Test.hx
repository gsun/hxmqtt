import utest.Runner;
import utest.ui.Report;
import utest.Assert;

class Test {
	public static function main() {
		utest.UTest.run([new SimpleTest()]);
	}
}

class SimpleTest extends utest.Test {
	public function testVoid() {
		Assert.equals(true, true);
	}
}
