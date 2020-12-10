import utest.Runner;
import utest.ui.Report;
import utest.Assert;
import haxe.io.Bytes;
import haxe.crypto.BaseCode;
import mqtt.*;

// test case from mqtt-packet, https://github.com/mqttjs/mqtt-packet/

class Test {
	public static function main() {
		utest.UTest.run([new ConnectTest()]);
	}
}

class ConnectTest extends utest.Test {
	public function testMin() {
		var p1 = [
			16, 16, // Header
			0, 4, // Protocol ID length
			77, 81, 84, 84, // Protocol ID
			3, // Protocol version
			0, // Connect flags
			0, 30, // Keepalive
			0,
			4, // Client ID length
			116, 101, 115, 116 // Client ID
		];
		Assert.equals(p1.length, 18);
		var p2 = [for (i in p1) StringTools.hex(i, 2)].join("");
		Assert.equals(p2, "101000044D5154540300001E000474657374");
		var p3 = Bytes.ofHex(p2);
		Assert.equals(p2, p3.toHex().toUpperCase());

		var r = new Reader(new haxe.io.BytesInput(p3));
		var p = r.read();

		Assert.same({
			pktType: 1,
			dup: false,
			qos: 0,
			retain: false,
			body: {}
		}, p);
	}

	/*connect MQTT 5*/
	public function testWill() {
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
		];
		Assert.equals(p1.length, 127);
		var p2 = [for (i in p1) StringTools.hex(i, 2)].join("");
		Assert.equals(p2,
			"107D00044D5154540536001E2F11000004D22101B027000000642201C8190117012600047465737400047465737415000474657374160004010203040004746573742F18000004D2010002000010E103000474657374080005746F70696309000401020304260004746573740004746573740005746F706963000404030201");
		var p3 = Bytes.ofHex(p2);
		Assert.equals(p2, p3.toHex().toUpperCase());

		var r = new Reader(new haxe.io.BytesInput(p3));
		var p = r.read();

		Assert.same({
			pktType: 1,
			dup: false,
			qos: 0,
			retain: false,
			body: {
				clientId: "test",
				protocolVersion: 5,
				protocolName: "MQTT",
				cleanStart: true,
				keepalive: 30,
				username: null,
				password: null,
				will: {
					topic: "topic",
					payload: Bytes.ofHex("04030201"),
					qos: 2,
					retain: true,
					properties: {
						willDelayInterval: 1234,
						payloadFormatIndicator: 0,
						messageExpiryInterval: 4321,
						contentType: "test",
						responseTopic: "topic",
						correlationData: Bytes.ofHex("01020304"),
						userProperty: {
							test: "test"
						}
					}
				},
				properties: {
					sessionExpiryInterval: 1234,
					receiveMaximum: 432,
					maximumPacketSize: 100,
					topicAliasMaximum: 456,
					requestResponseInformation: 1,
					requestProblemInformation: 1,
					authenticationMethod: "test",
					authenticationData: Bytes.ofHex("01020304"),
					userProperty: {
						test: "test"
					}
				}
			}
		}, p);
	}

	/*connect MQTT 5 with will properties but with empty will payload*/
	public function testNoWillPayload() {
		var p1 = [
			16, 121, // Header
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
			0, 0 // Will payload length
		];
		Assert.equals(p1.length, 123);
		var p2 = [for (i in p1) StringTools.hex(i, 2)].join("");
		var p3 = Bytes.ofHex(p2);
		var r = new Reader(new haxe.io.BytesInput(p3));
		var p = r.read();

		Assert.same({
			pktType: 1,
			dup: false,
			qos: 0,
			retain: false,
			body: {
				clientId: "test",
				protocolVersion: 5,
				protocolName: "MQTT",
				cleanStart: true,
				keepalive: 30,
				username: null,
				password: null,
				will: {
					topic: "topic",
					payload: Bytes.ofString(""),
					qos: 2,
					retain: true,
					properties: {
						willDelayInterval: 1234,
						payloadFormatIndicator: 0,
						messageExpiryInterval: 4321,
						contentType: "test",
						responseTopic: "topic",
						correlationData: Bytes.ofHex("01020304"),
						userProperty: {
							test: "test"
						}
					}
				},
				properties: {
					sessionExpiryInterval: 1234,
					receiveMaximum: 432,
					maximumPacketSize: 100,
					topicAliasMaximum: 456,
					requestResponseInformation: 1,
					requestProblemInformation: 1,
					authenticationMethod: "test",
					authenticationData: Bytes.ofHex("01020304"),
					userProperty: {
						test: "test"
					}
				}
			}
		}, p);
	}

	public function testNoWillProperties() {
		var p1 = [
			16, 78, // Header
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
			0, // will properties
			0, 5, // Will topic length
			116, 111, 112, 105, 99, // Will topic
			0,
			4, // Will payload length
			4, 3, 2, 1 // Will payload
		];
		Assert.equals(p1.length, 80);
		var p2 = [for (i in p1) StringTools.hex(i, 2)].join("");
		var p3 = Bytes.ofHex(p2);
		var r = new Reader(new haxe.io.BytesInput(p3));
		var p = r.read();

		Assert.same({
			pktType: 1,
			dup: false,
			qos: 0,
			retain: false,
			body: {
				clientId: "test",
				protocolVersion: 5,
				protocolName: "MQTT",
				cleanStart: true,
				keepalive: 30,
				username: null,
				password: null,
				will: {
					topic: "topic",
					payload: Bytes.ofHex("04030201"),
					qos: 2,
					retain: true,
					properties: null
				},
				properties: {
					sessionExpiryInterval: 1234,
					receiveMaximum: 432,
					maximumPacketSize: 100,
					topicAliasMaximum: 456,
					requestResponseInformation: 1,
					requestProblemInformation: 1,
					authenticationMethod: "test",
					authenticationData: Bytes.ofHex("01020304"),
					userProperty: {
						test: "test"
					}
				}
			}
		}, p);
	}

	public function testV4() {
		var p1 = [
			16, 12, // Header
			0, 4, // Protocol ID length
			77, 81, 84, 84, // Protocol ID
			4, // Protocol version
			2, // Connect flags
			0, 30, // Keepalive
			0,
			0 // Client ID length
		];
		Assert.equals(p1.length, 14);
		var p2 = [for (i in p1) StringTools.hex(i, 2)].join("");
		var p3 = Bytes.ofHex(p2);
		var r = new Reader(new haxe.io.BytesInput(p3));
		var p = r.read();

		Assert.same({
			pktType: 1,
			dup: false,
			qos: 0,
			retain: false,
			body: {}
		}, p);
	}
}
