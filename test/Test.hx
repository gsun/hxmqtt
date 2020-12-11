import utest.Runner;
import utest.ui.Report;
import utest.Assert;
import haxe.io.Bytes;
import haxe.crypto.BaseCode;
import mqtt.*;

// test case from mqtt-packet, https://github.com/mqttjs/mqtt-packet/

class Test {
	public static function main() {
		utest.UTest.run([new ConnectTest(), new ConnackTest(), new PublishTest()]);
	}
}

class ConnectTest extends utest.Test {
	public function testMin() {
		var p1 = [
			16, 17, // Header
			0, 4, // Protocol ID length
			77, 81, 84, 84, // Protocol ID
			5, // Protocol version
			0, // Connect flags
			0, 30, // Keepalive
			0, 0,
			4, // Client ID length
			116, 101, 115, 116 // Client ID
		];

		var p2 = [for (i in p1) StringTools.hex(i, 2)].join("");
		Assert.equals(p2, "101100044D5154540500001E00000474657374");
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
				cleanStart: false,
				keepalive: 30,
				username: null,
				password: null,
				will: {
					topic: null,
					payload: null,
					qos: 0,
					retain: false,
					properties: null
				},
				properties: null
			}
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

		var p2 = [for (i in p1) StringTools.hex(i, 2)].join("");
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

class ConnackTest extends utest.Test {
	public function testProperties() {
		var p1 = [
			32, 87, 0, 0, 84, // properties length
			17, 0, 0, 4, 210, // sessionExpiryInterval
			33, 1, 176, // receiveMaximum
			36, 2, // Maximum qos
			37,
			1, // retainAvailable
			39, 0, 0, 0, 100, // maximumPacketSize
			18, 0, 4, 116, 101, 115, 116, // assignedClientIdentifier
			34, 1,
			200, // topicAliasMaximum
			31, 0, 4, 116, 101, 115, 116, // reasonString
			38, 0, 4, 116, 101, 115, 116, 0, 4, 116, 101, 115, 116, // userProperties
			40,
			1, // wildcardSubscriptionAvailable
			41, 1, // subscriptionIdentifiersAvailable
			42, 0, // sharedSubscriptionAvailable
			19, 4, 210, // serverKeepAlive
			26, 0, 4, 116, 101, 115, 116, // responseInformation
			28, 0, 4, 116, 101, 115, 116, // serverReference
			21, 0, 4, 116, 101, 115,
			116, // authenticationMethod
			22, 0, 4, 1, 2, 3, 4 // authenticationData
		];

		var p2 = [for (i in p1) StringTools.hex(i, 2)].join("");
		var p3 = Bytes.ofHex(p2);
		var r = new Reader(new haxe.io.BytesInput(p3));
		var p = r.read();

		Assert.same({
			pktType: 2,
			dup: false,
			qos: 0,
			retain: false,
			body: {
				reasonCode: 0,
				sessionPresent: false,
				properties: {
					sessionExpiryInterval: 1234,
					receiveMaximum: 432,
					maximumQoS: 2,
					retainAvailable: 1,
					maximumPacketSize: 100,
					assignedClientIdentifier: "test",
					topicAliasMaximum: 456,
					reasonString: "test",
					wildcardSubscriptionAvailable: 1,
					subscriptionIdentifierAvailable: 1,
					sharedSubscriptionAvailabe: 0,
					serverKeepAlive: 1234,
					responseInformation: "test",
					serverReference: "test",
					authenticationMethod: "test",
					authenticationData: Bytes.ofHex("01020304"),
					userProperty: {
						test: "test"
					}
				}
			}
		}, p);
	}

	public function testMultiUserProperties() {
		var p1 = [
			32, 100, 0, 0, 97, // properties length
			17, 0, 0, 4, 210, // sessionExpiryInterval
			33, 1, 176, // receiveMaximum
			36, 2, // Maximum qos
			37,
			1, // retainAvailable
			39, 0, 0, 0, 100, // maximumPacketSize
			18, 0, 4, 116, 101, 115, 116, // assignedClientIdentifier
			34, 1,
			200, // topicAliasMaximum
			31, 0, 4, 116, 101, 115, 116, // reasonString
			38, 0, 4, 116, 101, 115, 116, 0, 4, 116, 101, 115, 116, 38, 0, 4, 116, 101,
			115, 116, 0, 4, 116, 101, 115, 116, // userProperties
			40, 1, // wildcardSubscriptionAvailable
			41, 1, // subscriptionIdentifiersAvailable
			42,
			0, // sharedSubscriptionAvailable
			19, 4, 210, // serverKeepAlive
			26, 0, 4, 116, 101, 115, 116, // responseInformation
			28, 0, 4, 116, 101, 115,
			116, // serverReference
			21, 0, 4, 116, 101, 115, 116, // authenticationMethod
			22, 0, 4, 1, 2, 3, 4 // authenticationData
		];

		var p2 = [for (i in p1) StringTools.hex(i, 2)].join("");
		var p3 = Bytes.ofHex(p2);
		var r = new Reader(new haxe.io.BytesInput(p3));
		var p = r.read();

		Assert.same({
			pktType: 2,
			dup: false,
			qos: 0,
			retain: false,
			body: {
				reasonCode: 0,
				sessionPresent: false,
				properties: {
					sessionExpiryInterval: 1234,
					receiveMaximum: 432,
					maximumQoS: 2,
					retainAvailable: 1,
					maximumPacketSize: 100,
					assignedClientIdentifier: "test",
					topicAliasMaximum: 456,
					reasonString: "test",
					wildcardSubscriptionAvailable: 1,
					subscriptionIdentifierAvailable: 1,
					sharedSubscriptionAvailabe: 0,
					serverKeepAlive: 1234,
					responseInformation: "test",
					serverReference: "test",
					authenticationMethod: "test",
					authenticationData: Bytes.ofHex("01020304"),
					userProperty: {
						test: "test"
					}
				}
			}
		}, p);
	}

	public function testReturuCode0() {
		var p1 = [32, 2, 1, 0, 0];

		var p2 = [for (i in p1) StringTools.hex(i, 2)].join("");
		var p3 = Bytes.ofHex(p2);
		var r = new Reader(new haxe.io.BytesInput(p3));
		var p = r.read();

		Assert.same({
			pktType: 2,
			dup: false,
			qos: 0,
			retain: false,
			body: {
				reasonCode: 0,
				sessionPresent: true,
				properties: null
			}
		}, p);
	}

	public function testReturuCode5() {
		var p1 = [32, 2, 1, 5, 0];

		var p2 = [for (i in p1) StringTools.hex(i, 2)].join("");
		var p3 = Bytes.ofHex(p2);
		var r = new Reader(new haxe.io.BytesInput(p3));
		var p = r.read();

		Assert.same({
			pktType: 2,
			dup: false,
			qos: 0,
			retain: false,
			body: {}
		}, p);
	}
}

class PublishTest extends utest.Test {
	public function testMin() {
		var p1 = [
			48, 10, // Header
			0, 4, // Topic length
			116, 101, 115, 116, // Topic (test)
			116, 101, 115, 116 // Payload (test)
		];

		var p2 = [for (i in p1) StringTools.hex(i, 2)].join("");
		var p3 = Bytes.ofHex(p2);
		var r = new Reader(new haxe.io.BytesInput(p3));
		var p = r.read();

		Assert.same({
			pktType: 3,
			dup: false,
			qos: 0,
			retain: false,
			body: {
				topic: "test",
				packetIdentifier: 29797,
				properties: {
					userProperty: {}
				},
				payload: Bytes.ofString("")
			}
		}, p);
	}

	public function testV5() {
		var p1 = [
			61, 86, // Header
			0, 4, // Topic length
			116, 101, 115, 116, // Topic (test)
			0, 10, // Message ID
			73, // properties length
			1,
			1, // payloadFormatIndicator
			2, 0, 0, 16, 225, // message expiry interval
			35, 0, 100, // topicAlias
			8, 0, 5, 116, 111, 112, 105, 99, // response topic
			9, 0, 4, 1, 2, 3, 4, // correlationData
			38, 0, 4, 116, 101, 115, 116, 0, 4, 116, 101, 115, 116, // userProperties
			38, 0, 4, 116, 101, 115, 116, 0,
			4, 116, 101, 115, 116, // userProperties
			38, 0, 4, 116, 101, 115, 116, 0, 4, 116, 101, 115, 116, // userProperties
			11, 120, // subscriptionIdentifier
			3, 0, 4, 116, 101, 115, 116, // content type
			116, 101, 115, 116 // Payload (test)
		];

		var p2 = [for (i in p1) StringTools.hex(i, 2)].join("");
		var p3 = Bytes.ofHex(p2);
		var r = new Reader(new haxe.io.BytesInput(p3));
		var p = r.read();

		Assert.same({
			pktType: 3,
			dup: true,
			qos: 2,
			retain: true,
			body: {
				topic: "test",
				packetIdentifier: 10,
				properties: {
					payloadFormatIndicator: 1,
					messageExpiryInterval: 4321,
					topicAlias: 100,
					responseTopic: "topic",
					correlationData: Bytes.ofHex("01020304"),
					subscriptionIdentifier: [120],
					contentType: "test",
					userProperty: {
						test: "test"
					}
				},
				payload: Bytes.ofString('test')
			}
		}, p);
	}

	public function testMultiSubscriptionIdentifier() {
		var p1 = [
			61, 64, // Header
			0, 4, // Topic length
			116, 101, 115, 116, // Topic (test)
			0, 10, // Message ID
			51, // properties length
			1,
			1, // payloadFormatIndicator
			2, 0, 0, 16, 225, // message expiry interval
			35, 0, 100, // topicAlias
			8, 0, 5, 116, 111, 112, 105, 99, // response topic
			9, 0, 4, 1, 2, 3, 4, // correlationData
			38, 0, 4, 116, 101, 115, 116, 0, 4, 116, 101, 115, 116, // userProperties
			11, 120, // subscriptionIdentifier
			11, 121, // subscriptionIdentifier
			11, 122, // subscriptionIdentifier
			3, 0, 4, 116, 101, 115, 116, // content type
			116, 101, 115,
			116 // Payload (test)
		];

		var p2 = [for (i in p1) StringTools.hex(i, 2)].join("");
		var p3 = Bytes.ofHex(p2);
		var r = new Reader(new haxe.io.BytesInput(p3));
		var p = r.read();

		Assert.same({
			pktType: 3,
			dup: true,
			qos: 2,
			retain: true,
			body: {
				topic: "test",
				packetIdentifier: 10,
				properties: {
					payloadFormatIndicator: 1,
					messageExpiryInterval: 4321,
					topicAlias: 100,
					responseTopic: "topic",
					correlationData: Bytes.ofHex("01020304"),
					subscriptionIdentifier: [120, 121, 122],
					contentType: "test",
					userProperty: {
						test: "test"
					}
				},
				payload: Bytes.ofString('test')
			}
		}, p);
	}

	public function testVariableSubscriptionIdentifier() {
		var p1 = [
			61, 27, // Header
			0, 4, // Topic length
			116, 101, 115, 116, // Topic (test)
			0, 10, // Message ID
			14, // properties length
			1,
			0, // payloadFormatIndicator
			11, 128, 1, // subscriptionIdentifier
			11, 128, 128, 1, // subscriptionIdentifier
			11, 128, 128, 128,
			1, // subscriptionIdentifier
			116, 101, 115, 116 // Payload (test)
		];

		var p2 = [for (i in p1) StringTools.hex(i, 2)].join("");
		var p3 = Bytes.ofHex(p2);
		var r = new Reader(new haxe.io.BytesInput(p3));
		var p = r.read();

		Assert.same({
			pktType: 3,
			dup: true,
			qos: 2,
			retain: true,
			body: {
				topic: "test",
				packetIdentifier: 10,
				properties: {
					payloadFormatIndicator: 0,
					userProperty: {},
					subscriptionIdentifier: [128, 16384, 2097152]
				},
				payload: Bytes.ofString("test")
			}
		}, p);
	}

	public function testMaxSubscriptionIdentifier() {
		var p1 = [
			61, 22, // Header
			0, 4, // Topic length
			116, 101, 115, 116, // Topic (test)
			0, 10, // Message ID
			9, // properties length
			1, 0, // payloadFormatIndicator
			11, 1, // subscriptionIdentifier
			11, 255, 255, 255, 127, // subscriptionIdentifier (max value)
			116, 101, 115, 116 // Payload (test)
		];

		var p2 = [for (i in p1) StringTools.hex(i, 2)].join("");
		var p3 = Bytes.ofHex(p2);
		var r = new Reader(new haxe.io.BytesInput(p3));
		var p = r.read();
		trace(p);
		Assert.same({
			pktType: 3,
			dup: true,
			qos: 2,
			retain: true,
			body: {
				topic: "test",
				packetIdentifier: 10,
				properties: {
					payloadFormatIndicator: 0,
					userProperty: {},
					subscriptionIdentifier: [1, 268435455]
				},
				payload: Bytes.ofString("test")
			}
		}, p);
	}
}
