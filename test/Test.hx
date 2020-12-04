import utest.Runner;
import utest.ui.Report;
import utest.Assert;
import haxe.io.Bytes;
import haxe.crypto.BaseCode;
import mqtt.*;

class Test {
	public static function main() {
		utest.UTest.run([new SimpleTest()]);
	}
}

class SimpleTest extends utest.Test {
	//test case from mqtt-packet, https://github.com/mqttjs/mqtt-packet/
	public function testVoid() { 
		var p1 = [
			16, 125, // Header
			0, 4, // Protocol ID length
			77, 81, 84, 84, // Protocol ID
			5, // Protocol version
			54, // Connect flags
			0, 30, // Keepalive
			47, // properties length
			17, 0, 0, 4, 210, // sessionExpiryInterval
			33, 1, 176, // receiveMaximum
			39, 0, 0, 0, 100, // maximumPacketSize
			34, 1,
			200, // topicAliasMaximum
			25, 1, // requestResponseInformation
			23, 1, // requestProblemInformation,
			38, 0, 4, 116, 101, 115, 116, 0, 4, 116, 101,
			115, 116, // userProperties,
			21, 0, 4, 116, 101, 115, 116, // authenticationMethod
			22, 0, 4, 1, 2, 3, 4, // authenticationData
			0,
			4, // Client ID length
			116, 101, 115, 116, // Client ID
			47, // will properties
			24, 0, 0, 4, 210, // will delay interval
			1,
			0, // payload format indicator
			2, 0, 0, 16, 225, // message expiry interval
			3, 0, 4, 116, 101, 115, 116, // content type
			8, 0, 5, 116, 111, 112, 105,
			99, // response topic
			9, 0, 4, 1, 2, 3, 4, // corelation data
			38, 0, 4, 116, 101, 115, 116, 0, 4, 116, 101, 115, 116, // user properties
			0,
			5, // Will topic length
			116, 111, 112, 105, 99, // Will topic
			0, 4, // Will payload length
			4, 3, 2, 1, // Will payload
			0 //padding
		];
		Assert.equals(p1.length, 128);
		var p2 = [for (i in p1) StringTools.hex(i)].join("");
		Assert.equals(p2, "107D044D51545453601E2F11004D2211B02700064221C819117126047465737404746573741504746573741604123404746573742F18004D21020010E130474657374805746F7069639041234260474657374047465737405746F7069630443210");
		var p3 = Bytes.ofHex(p2);
		Assert.equals(p2, p3.toHex().toUpperCase());
		
		//var r = new Reader(new haxe.io.BytesInput(p3));
		
		
	}
}
