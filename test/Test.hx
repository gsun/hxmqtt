import utest.Runner;
import utest.ui.Report;
import utest.Assert;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.crypto.BaseCode;
import mqtt.Constants;
import mqtt.Reader;
import mqtt.Writer;
import mqtt.Data;

// test case from mqtt-packet, https://github.com/mqttjs/mqtt-packet/

class Test {
	public static function main() {
		utest.UTest.run([
			new ConnectTest(), new ConnackTest(), new PublishTest(), new PubackTest(), new PubrecTest(), new PubrelTest(), new PubcompTest(),
			new SubscribeTest(), new SubackTest(), new UnsubscribeTest(), new UnsubackTest(), new AuthTest(), new DisconnectTest(), new PingreqTest(),
			new PingrespTest()]);
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

		var bb = new BytesBuffer();
		for (i in p1)
			bb.addByte(i);

		var r = new Reader(new haxe.io.BytesInput(bb.getBytes()));
		var p = r.read();
		Assert.same({
			pktType: CtrlPktType.Connect,
			dup: false,
			qos: QoS.AtMostOnce,
			retain: false,
			body: {
				clientId: "test",
				protocolVersion: 5,
				protocolName: "MQTT",
				cleanStart: false,
				keepalive: 30
			}
		}, p);

		var o = new haxe.io.BytesOutput();
		var w = new Writer(o);
		w.write(p);
		Assert.same(bb.getBytes(), o.getBytes());
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

		var bb = new BytesBuffer();
		for (i in p1)
			bb.addByte(i);

		var r = new Reader(new haxe.io.BytesInput(bb.getBytes()));
		var p = r.read();

		Assert.same({
			pktType: CtrlPktType.Connect,
			dup: false,
			qos: QoS.AtMostOnce,
			retain: false,
			body: {
				clientId: "test",
				protocolVersion: 5,
				protocolName: "MQTT",
				cleanStart: true,
				keepalive: 30,
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
					requestResponseInformation: true,
					requestProblemInformation: true,
					authenticationMethod: "test",
					authenticationData: Bytes.ofHex("01020304"),
					userProperty: {
						test: "test"
					}
				}
			}
		}, p);

		var p2 = [
			16, 125, // Header
			0, 4, // Protocol ID length
			77, 81, 84, 84, // Protocol ID
			5, // Protocol version
			54, // Connect flags
			0, 30, // Keepalive
			47, // properties length
			17, 0, 0, 4, 210, // sessionExpiryInterval
			21, 0, 4, 116, 101, 115, 116, // authenticationMethod
			22, 0, 4, 1, 2, 3,
			4, // authenticationData
			23, 1, // requestProblemInformation,
			25, 1, // requestResponseInformation
			33, 1, 176, // receiveMaximum
			34, 1,
			200, // topicAliasMaximum
			39, 0, 0, 0, 100, // maximumPacketSize
			38, 0, 4, 116, 101, 115, 116, 0, 4, 116, 101, 115, 116, // userProperties,
			0,
			4, // Client ID length
			116, 101, 115, 116, // Client ID
			47, // will properties
			1, 0, // payload format indicator
			2, 0, 0, 16,
			225, // message expiry interval
			3, 0, 4, 116, 101, 115, 116, // content type
			8, 0, 5, 116, 111, 112, 105, 99, // response topic
			9, 0, 4, 1, 2, 3,
			4, // corelation data
			24, 0, 0, 4, 210, // will delay interval
			38, 0, 4, 116, 101, 115, 116, 0, 4, 116, 101, 115, 116, // user properties
			0,
			5, // Will topic length
			116, 111, 112, 105, 99, // Will topic
			0, 4, // Will payload length
			4, 3, 2, 1, // Will payload
		];

		var bb1 = new BytesBuffer();
		for (i in p2)
			bb1.addByte(i);

		var o = new haxe.io.BytesOutput();
		var w = new Writer(o);
		w.write(p);
		Assert.same(bb1.getBytes(), o.getBytes());
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

		var bb = new BytesBuffer();
		for (i in p1)
			bb.addByte(i);

		var r = new Reader(new haxe.io.BytesInput(bb.getBytes()));
		var p = r.read();

		Assert.same({
			pktType: CtrlPktType.Connect,
			dup: false,
			qos: QoS.AtMostOnce,
			retain: false,
			body: {
				clientId: "test",
				protocolVersion: 5,
				protocolName: "MQTT",
				cleanStart: true,
				keepalive: 30,
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
					requestResponseInformation: true,
					requestProblemInformation: true,
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

		var bb = new BytesBuffer();
		for (i in p1)
			bb.addByte(i);

		var r = new Reader(new haxe.io.BytesInput(bb.getBytes()));
		var p = r.read();

		Assert.same({
			pktType: CtrlPktType.Connect,
			dup: false,
			qos: QoS.AtMostOnce,
			retain: false,
			body: {
				clientId: "test",
				protocolVersion: 5,
				protocolName: "MQTT",
				cleanStart: true,
				keepalive: 30,
				will: {
					topic: "topic",
					payload: Bytes.ofHex("04030201"),
					qos: 2,
					retain: true,
				},
				properties: {
					sessionExpiryInterval: 1234,
					receiveMaximum: 432,
					maximumPacketSize: 100,
					topicAliasMaximum: 456,
					requestResponseInformation: true,
					requestProblemInformation: true,
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

		var bb = new BytesBuffer();
		for (i in p1)
			bb.addByte(i);

		var r = new Reader(new haxe.io.BytesInput(bb.getBytes()));
		var p = r.read();

		Assert.same({
			pktType: CtrlPktType.Connect,
			dup: false,
			qos: QoS.AtMostOnce,
			retain: false
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

		var bb = new BytesBuffer();
		for (i in p1)
			bb.addByte(i);

		var r = new Reader(new haxe.io.BytesInput(bb.getBytes()));
		var p = r.read();

		Assert.same({
			pktType: CtrlPktType.Connack,
			dup: false,
			qos: QoS.AtMostOnce,
			retain: false,
			body: {
				reasonCode: 0,
				sessionPresent: false,
				properties: {
					sessionExpiryInterval: 1234,
					receiveMaximum: 432,
					maximumQoS: 2,
					retainAvailable: true,
					maximumPacketSize: 100,
					assignedClientIdentifier: "test",
					topicAliasMaximum: 456,
					reasonString: "test",
					wildcardSubscriptionAvailable: true,
					subscriptionIdentifierAvailable: true,
					sharedSubscriptionAvailable: false,
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

		var p2 = [
			32, 87, 0, 0, 84, // properties length
			17, 0, 0, 4, 210, // sessionExpiryInterval
			18, 0, 4, 116, 101, 115, 116, // assignedClientIdentifier
			19, 4,
			210, // serverKeepAlive
			21, 0, 4, 116, 101, 115, 116, // authenticationMethod
			22, 0, 4, 1, 2, 3, 4, // authenticationData
			26, 0, 4, 116, 101, 115,
			116, // responseInformation
			28, 0, 4, 116, 101, 115, 116, // serverReference
			31, 0, 4, 116, 101, 115, 116, // reasonString
			33, 1,
			176, // receiveMaximum
			34, 1, 200, // topicAliasMaximum
			36, 2, // Maximum qos
			37, 1, // retainAvailable
			39, 0, 0, 0, 100, // maximumPacketSize
			40,
			1, // wildcardSubscriptionAvailable
			41, 1, // subscriptionIdentifiersAvailable
			42, 0, // sharedSubscriptionAvailable
			38, 0, 4, 116, 101, 115, 116, 0,
			4, 116, 101, 115, 116 // userProperties
		];
		var bb1 = new BytesBuffer();
		for (i in p2)
			bb1.addByte(i);

		var o = new haxe.io.BytesOutput();
		var w = new Writer(o);
		w.write(p);
		Assert.same(bb1.getBytes(), o.getBytes());
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

		var bb = new BytesBuffer();
		for (i in p1)
			bb.addByte(i);

		var r = new Reader(new haxe.io.BytesInput(bb.getBytes()));
		var p = r.read();

		Assert.same({
			pktType: CtrlPktType.Connack,
			dup: false,
			qos: QoS.AtMostOnce,
			retain: false,
			body: {
				reasonCode: 0,
				sessionPresent: false,
				properties: {
					sessionExpiryInterval: 1234,
					receiveMaximum: 432,
					maximumQoS: 2,
					retainAvailable: true,
					maximumPacketSize: 100,
					assignedClientIdentifier: "test",
					topicAliasMaximum: 456,
					reasonString: "test",
					wildcardSubscriptionAvailable: true,
					subscriptionIdentifierAvailable: true,
					sharedSubscriptionAvailable: false,
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
		var p1 = [32, 3, 1, 0, 0];

		var bb = new BytesBuffer();
		for (i in p1)
			bb.addByte(i);

		var r = new Reader(new haxe.io.BytesInput(bb.getBytes()));
		var p = r.read();

		Assert.same({
			pktType: CtrlPktType.Connack,
			dup: false,
			qos: QoS.AtMostOnce,
			retain: false,
			body: {
				reasonCode: 0,
				sessionPresent: true,
				properties: null
			}
		}, p);

		var o = new haxe.io.BytesOutput();
		var w = new Writer(o);
		w.write(p);
		Assert.same(bb.getBytes(), o.getBytes());
	}

	public function testReturuCode5() {
		var p1 = [32, 2, 1, 5, 0];

		var bb = new BytesBuffer();
		for (i in p1)
			bb.addByte(i);

		var r = new Reader(new haxe.io.BytesInput(bb.getBytes()));
		var p = r.read();

		Assert.same({
			pktType: CtrlPktType.Connack,
			dup: false,
			qos: QoS.AtMostOnce,
			retain: false
		}, p);
	}
}

class PublishTest extends utest.Test {
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

		var bb = new BytesBuffer();
		for (i in p1)
			bb.addByte(i);

		var r = new Reader(new haxe.io.BytesInput(bb.getBytes()));
		var p = r.read();

		Assert.same({
			pktType: CtrlPktType.Publish,
			dup: true,
			qos: QoS.ExactlyOnce,
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

		var p2 = [
			61, 60, // Header
			0, 4, // Topic length
			116, 101, 115, 116, // Topic (test)
			0, 10, // Message ID
			47, // properties length
			1,
			1, // payloadFormatIndicator
			2, 0, 0, 16, 225, // message expiry interval
			3, 0, 4, 116, 101, 115, 116, // content type
			8, 0, 5, 116, 111, 112, 105,
			99, // response topic
			9, 0, 4, 1, 2, 3, 4, // correlationData
			35, 0, 100, // topicAlias
			11, 120, // subscriptionIdentifier
			38, 0, 4, 116, 101, 115,
			116, 0, 4, 116, 101, 115, 116, // userProperties
			116, 101, 115, 116 // Payload (test)
		];

		var bb1 = new BytesBuffer();
		for (i in p2)
			bb1.addByte(i);

		var o = new haxe.io.BytesOutput();
		var w = new Writer(o);
		w.write(p);
		Assert.same(bb1.getBytes(), o.getBytes());
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
			3, 0, 4, 116, 101, 115, 116, // content type
			8, 0, 5, 116, 111, 112, 105,
			99, // response topic
			9, 0, 4, 1, 2, 3, 4, // correlationData
			35, 0, 100, // topicAlias
			11, 120, // subscriptionIdentifier
			11,
			121, // subscriptionIdentifier
			11, 122, // subscriptionIdentifier
			38, 0, 4, 116, 101, 115, 116, 0, 4, 116, 101, 115, 116, // userProperties
			116, 101,
			115, 116 // Payload (test)
		];

		var bb = new BytesBuffer();
		for (i in p1)
			bb.addByte(i);

		var r = new Reader(new haxe.io.BytesInput(bb.getBytes()));
		var p = r.read();

		Assert.same({
			pktType: CtrlPktType.Publish,
			dup: true,
			qos: QoS.ExactlyOnce,
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

		var o = new haxe.io.BytesOutput();
		var w = new Writer(o);
		w.write(p);
		Assert.same(bb.getBytes(), o.getBytes());
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

		var bb = new BytesBuffer();
		for (i in p1)
			bb.addByte(i);

		var r = new Reader(new haxe.io.BytesInput(bb.getBytes()));
		var p = r.read();

		Assert.same({
			pktType: CtrlPktType.Publish,
			dup: true,
			qos: QoS.ExactlyOnce,
			retain: true,
			body: {
				topic: "test",
				packetIdentifier: 10,
				properties: {
					payloadFormatIndicator: 0,
					subscriptionIdentifier: [128, 16384, 2097152]
				},
				payload: Bytes.ofString("test")
			}
		}, p);

		var o = new haxe.io.BytesOutput();
		var w = new Writer(o);
		w.write(p);
		Assert.same(bb.getBytes(), o.getBytes());
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

		var bb = new BytesBuffer();
		for (i in p1)
			bb.addByte(i);

		var r = new Reader(new haxe.io.BytesInput(bb.getBytes()));
		var p = r.read();

		Assert.same({
			pktType: CtrlPktType.Publish,
			dup: true,
			qos: QoS.ExactlyOnce,
			retain: true,
			body: {
				topic: "test",
				packetIdentifier: 10,
				properties: {
					payloadFormatIndicator: 0,
					subscriptionIdentifier: [1, 268435455]
				},
				payload: Bytes.ofString("test")
			}
		}, p);

		var o = new haxe.io.BytesOutput();
		var w = new Writer(o);
		w.write(p);
		Assert.same(bb.getBytes(), o.getBytes());
	}

	public function test2kPayload() {
		var p1 = [
			61, 146, 16, // Header
			0, 4, // Topic length
			116, 101, 115, 116, // Topic (test)
			0, 10, // Message ID
			9, // properties length
			1,
			0, // payloadFormatIndicator
			11, 1, // subscriptionIdentifier
			11, 255, 255, 255, 127, // subscriptionIdentifier (max value)
		];

		var bb1 = new BytesBuffer();
		for (i in p1)
			bb1.addByte(i);
		for (i in 0...2048)
			bb1.addByte(3);

		var bb2 = new BytesBuffer();
		for (i in 0...2048)
			bb2.addByte(3);

		var r = new Reader(new haxe.io.BytesInput(bb1.getBytes()));
		var p = r.read();

		Assert.same({
			pktType: CtrlPktType.Publish,
			dup: true,
			qos: QoS.ExactlyOnce,
			retain: true,
			body: {
				topic: "test",
				packetIdentifier: 10,
				properties: {
					payloadFormatIndicator: 0,
					subscriptionIdentifier: [1, 268435455]
				},
				payload: bb2.getBytes()
			}
		}, p);

		var o = new haxe.io.BytesOutput();
		var w = new Writer(o);
		w.write(p);
		Assert.same(bb1.getBytes(), o.getBytes());
	}
}

class PubackTest extends utest.Test {
	public function testV5() {
		var p1 = [
			64, 24, // Header
			0, 2, // Message ID
			16, // reason code
			20, // properties length
			31, 0, 4, 116, 101, 115, 116, // reasonString
			38, 0, 4, 116, 101,
			115, 116, 0, 4, 116, 101, 115, 116 // userProperties
		];

		var bb = new BytesBuffer();
		for (i in p1)
			bb.addByte(i);

		var r = new Reader(new haxe.io.BytesInput(bb.getBytes()));
		var p = r.read();

		Assert.same({
			pktType: CtrlPktType.Puback,
			dup: false,
			qos: QoS.AtMostOnce,
			retain: false,
			body: {
				packetIdentifier: 2,
				reasonCode: 16,
				properties: {
					reasonString: "test",
					userProperty: {
						test: "test"
					}
				}
			}
		}, p);

		var o = new haxe.io.BytesOutput();
		var w = new Writer(o);
		w.write(p);
		Assert.same(bb.getBytes(), o.getBytes());
	}
}

class PubrecTest extends utest.Test {
	public function testV5() {
		var p1 = [
			80, 24, // Header
			0, 2, // Message ID
			16, // reason code
			20, // properties length
			31, 0, 4, 116, 101, 115, 116, // reasonString
			38, 0, 4, 116, 101,
			115, 116, 0, 4, 116, 101, 115, 116 // userProperties
		];

		var bb = new BytesBuffer();
		for (i in p1)
			bb.addByte(i);

		var r = new Reader(new haxe.io.BytesInput(bb.getBytes()));
		var p = r.read();

		Assert.same({
			pktType: CtrlPktType.Pubrec,
			dup: false,
			qos: QoS.AtMostOnce,
			retain: false,
			body: {
				packetIdentifier: 2,
				reasonCode: 16,
				properties: {
					reasonString: "test",
					userProperty: {
						test: "test"
					}
				}
			}
		}, p);

		var o = new haxe.io.BytesOutput();
		var w = new Writer(o);
		w.write(p);
		Assert.same(bb.getBytes(), o.getBytes());
	}
}

class PubrelTest extends utest.Test {
	public function testV5() {
		var p1 = [
			98, 24, // Header
			0, 2, // Message ID
			146, // reason code
			20, // properties length
			31, 0, 4, 116, 101, 115, 116, // reasonString
			38, 0, 4, 116, 101,
			115, 116, 0, 4, 116, 101, 115, 116 // userProperties
		];

		var bb = new BytesBuffer();
		for (i in p1)
			bb.addByte(i);

		var r = new Reader(new haxe.io.BytesInput(bb.getBytes()));
		var p = r.read();

		Assert.same({
			pktType: CtrlPktType.Pubrel,
			dup: false,
			qos: QoS.AtLeastOnce,
			retain: false,
			body: {
				packetIdentifier: 2,
				reasonCode: 146,
				properties: {
					reasonString: "test",
					userProperty: {
						test: "test"
					}
				}
			}
		}, p);

		var o = new haxe.io.BytesOutput();
		var w = new Writer(o);
		w.write(p);
		Assert.same(bb.getBytes(), o.getBytes());
	}
}

class PubcompTest extends utest.Test {
	public function testV5() {
		var p1 = [
			112, 24, // Header
			0, 2, // Message ID
			146, // reason code
			20, // properties length
			31, 0, 4, 116, 101, 115, 116, // reasonString
			38, 0, 4, 116, 101,
			115, 116, 0, 4, 116, 101, 115, 116 // userProperties
		];

		var bb = new BytesBuffer();
		for (i in p1)
			bb.addByte(i);

		var r = new Reader(new haxe.io.BytesInput(bb.getBytes()));
		var p = r.read();

		Assert.same({
			pktType: CtrlPktType.Pubcomp,
			dup: false,
			qos: QoS.AtMostOnce,
			retain: false,
			body: {
				packetIdentifier: 2,
				reasonCode: 146,
				properties: {
					reasonString: "test",
					userProperty: {
						test: "test"
					}
				}
			}
		}, p);

		var o = new haxe.io.BytesOutput();
		var w = new Writer(o);
		w.write(p);
		Assert.same(bb.getBytes(), o.getBytes());
	}
}

class SubscribeTest extends utest.Test {
	public function testV5() {
		var p1 = [
			130, 26, // Header (subscribeqos=1length=9)
			0, 6, // Message ID (6)
			16, // properties length
			11, 145, 1, // subscriptionIdentifier
			38, 0, 4, 116, 101,
			115, 116, 0, 4, 116, 101, 115, 116, // userProperties
			0, 4, // Topic length,
			116, 101, 115, 116, // Topic (test)
			24 // settings(qos: 0, noLocal: false, Retain as Published: true, retain handling: 1)
		];

		var bb = new BytesBuffer();
		for (i in p1)
			bb.addByte(i);

		var r = new Reader(new haxe.io.BytesInput(bb.getBytes()));
		var p = r.read();

		Assert.same({
			pktType: CtrlPktType.Subscribe,
			dup: false,
			qos: QoS.AtLeastOnce,
			retain: false,
			body: {
				packetIdentifier: 6,
				subscriptions: [
					{
						topic: "test",
						rh: 1,
						rap: true,
						nl: false,
						qos: QoS.AtMostOnce
					}
				],
				properties: {
					subscriptionIdentifier: 145,
					userProperty: {
						test: "test"
					}
				}
			}
		}, p);

		var o = new haxe.io.BytesOutput();
		var w = new Writer(o);
		w.write(p);
		Assert.same(bb.getBytes(), o.getBytes());
	}

	public function testMultiTopics() {
		var p1 = [
			130, 40, // Header (subscribeqos=1length=9)
			0, 6, // Message ID (6)
			16, // properties length
			11, 145, 1, // subscriptionIdentifier
			38, 0, 4, 116, 101,
			115, 116, 0, 4, 116, 101, 115, 116, // userProperties
			0, 4, // Topic length,
			116, 101, 115, 116, // Topic (test)
			24, // settings(qos: 0, noLocal: false, Retain as Published: true, retain handling: 1)
			0, 4, // Topic length
			117, 101, 115, 116, // Topic (uest)
			1, // Qos (1)
			0, 4, // Topic length
			116, 102, 115, 116, // Topic (tfst)
			6 // Qos (2), No Local: true
		];

		var bb = new BytesBuffer();
		for (i in p1)
			bb.addByte(i);

		var r = new Reader(new haxe.io.BytesInput(bb.getBytes()));
		var p = r.read();

		Assert.same({
			pktType: CtrlPktType.Subscribe,
			dup: false,
			qos: QoS.AtLeastOnce,
			retain: false,
			body: {
				packetIdentifier: 6,
				subscriptions: [
					{
						topic: "test",
						rh: 1,
						rap: true,
						nl: false,
						qos: QoS.AtMostOnce
					},
					{
						topic: "uest",
						rh: 0,
						rap: false,
						nl: false,
						qos: QoS.AtLeastOnce
					},
					{
						topic: "tfst",
						rh: 0,
						rap: false,
						nl: true,
						qos: QoS.ExactlyOnce
					}
				],
				properties: {
					subscriptionIdentifier: 145,
					userProperty: {
						test: "test"
					}
				}
			}
		}, p);

		var o = new haxe.io.BytesOutput();
		var w = new Writer(o);
		w.write(p);
		Assert.same(bb.getBytes(), o.getBytes());
	}
}

class SubackTest extends utest.Test {
	public function testV5() {
		var p1 = [
			144, 27, // Header
			0, 6, // Message ID
			20, // properties length
			31, 0, 4, 116, 101, 115, 116, // reasonString
			38, 0, 4, 116, 101, 115, 116, 0, 4, 116,
			101, 115, 116, // userProperties
			0, 1, 2, 128 // Granted qos (0, 1, 2) and a rejected being 0x80
		];

		var bb = new BytesBuffer();
		for (i in p1)
			bb.addByte(i);

		var r = new Reader(new haxe.io.BytesInput(bb.getBytes()));
		var p = r.read();

		Assert.same({
			pktType: CtrlPktType.Suback,
			dup: false,
			qos: QoS.AtMostOnce,
			retain: false,
			body: {
				packetIdentifier: 6,
				properties: {
					reasonString: "test",
					userProperty: {
						test: "test"
					}
				},
				granted: [0, 1, 2, 128]
			}
		}, p);

		var o = new haxe.io.BytesOutput();
		var w = new Writer(o);
		w.write(p);
		Assert.same(bb.getBytes(), o.getBytes());
	}
}

class UnsubscribeTest extends utest.Test {
	public function testV5() {
		var p1 = [
			162, 28, 0, 7, // Message ID (7)
			13, // properties length
			38, 0, 4, 116, 101, 115, 116, 0, 4, 116, 101, 115, 116, // userProperties
			0,
			4, // Topic length
			116, 102, 115, 116, // Topic (tfst)
			0, 4, // Topic length,
			116, 101, 115, 116 // Topic (test)
		];

		var bb = new BytesBuffer();
		for (i in p1)
			bb.addByte(i);

		var r = new Reader(new haxe.io.BytesInput(bb.getBytes()));
		var p = r.read();

		Assert.same({
			pktType: CtrlPktType.Unsubscribe,
			dup: false,
			qos: QoS.AtLeastOnce,
			retain: false,
			body: {
				packetIdentifier: 7,
				properties: {
					userProperty: {
						test: "test"
					}
				},
				unsubscriptions: ["tfst", "test"]
			}
		}, p);

		var o = new haxe.io.BytesOutput();
		var w = new Writer(o);
		w.write(p);
		Assert.same(bb.getBytes(), o.getBytes());
	}
}

class UnsubackTest extends utest.Test {
	public function testV5() {
		var p1 = [
			176, 25, // Header
			0, 8, // Message ID
			20, // properties length
			31, 0, 4, 116, 101, 115, 116, // reasonString
			38, 0, 4, 116, 101, 115, 116, 0, 4, 116,
			101, 115, 116, // userProperties
			0, 128 // success and error
		];

		var bb = new BytesBuffer();
		for (i in p1)
			bb.addByte(i);

		var r = new Reader(new haxe.io.BytesInput(bb.getBytes()));
		var p = r.read();

		Assert.same({
			pktType: CtrlPktType.Unsuback,
			dup: false,
			qos: QoS.AtMostOnce,
			retain: false,
			body: {
				packetIdentifier: 8,
				properties: {
					reasonString: "test",
					userProperty: {
						test: "test"
					}
				},
				granted: [0, 128]
			}
		}, p);

		var o = new haxe.io.BytesOutput();
		var w = new Writer(o);
		w.write(p);
		Assert.same(bb.getBytes(), o.getBytes());
	}
}

class AuthTest extends utest.Test {
	public function testV5() {
		var p1 = [
			240, 36, // Header
			0, // reason code
			34, // properties length
			21, 0, 4, 116, 101, 115, 116, // auth method
			22, 0, 4, 0, 1, 2, 3, // auth data
			31, 0, 4,
			116, 101, 115, 116, // reasonString
			38, 0, 4, 116, 101, 115, 116, 0, 4, 116, 101, 115, 116 // userProperties
		];

		var bb = new BytesBuffer();
		for (i in p1)
			bb.addByte(i);

		var r = new Reader(new haxe.io.BytesInput(bb.getBytes()));
		var p = r.read();

		Assert.same({
			pktType: CtrlPktType.Auth,
			dup: false,
			qos: QoS.AtMostOnce,
			retain: false,
			body: {
				reasonCode: AuthReasonCode.Success,
				properties: {
					authenticationMethod: "test",
					authenticationData: Bytes.ofHex("00010203"),
					reasonString: "test",
					userProperty: {
						test: "test"
					}
				}
			}
		}, p);

		var o = new haxe.io.BytesOutput();
		var w = new Writer(o);
		w.write(p);
		Assert.same(bb.getBytes(), o.getBytes());
	}
}

class DisconnectTest extends utest.Test {
	public function testV5() {
		var p1 = [
			224, 34, // Header
			0, // reason code
			32, // properties length
			17, 0, 0, 0, 145, // sessionExpiryInterval
			28, 0, 4, 116, 101, 115,
			116, // serverReference
			31, 0, 4, 116, 101, 115, 116, // reasonString
			38, 0, 4, 116, 101, 115, 116, 0, 4, 116, 101, 115, 116 // userProperties
		];

		var bb = new BytesBuffer();
		for (i in p1)
			bb.addByte(i);

		var r = new Reader(new haxe.io.BytesInput(bb.getBytes()));
		var p = r.read();

		Assert.same({
			pktType: CtrlPktType.Disconnect,
			dup: false,
			qos: QoS.AtMostOnce,
			retain: false,
			body: {
				reasonCode: DisconnectReasonCode.NormalDisconnection,
				properties: {
					sessionExpiryInterval: 145,
					reasonString: "test",
					serverReference: "test",
					userProperty: {
						test: "test"
					}
				}
			}
		}, p);

		var o = new haxe.io.BytesOutput();
		var w = new Writer(o);
		w.write(p);
		Assert.same(bb.getBytes(), o.getBytes());
	}
}

class PingreqTest extends utest.Test {
	public function testV5() {
		var p1 = [192, 0 // Header
		];

		var bb = new BytesBuffer();
		for (i in p1)
			bb.addByte(i);

		var r = new Reader(new haxe.io.BytesInput(bb.getBytes()));
		var p = r.read();

		Assert.same({
			pktType: CtrlPktType.Pingreq,
			dup: false,
			qos: QoS.AtMostOnce,
			retain: false
		}, p);

		var o = new haxe.io.BytesOutput();
		var w = new Writer(o);
		w.write(p);
		Assert.same(bb.getBytes(), o.getBytes());
	}
}

class PingrespTest extends utest.Test {
	public function testV5() {
		var p1 = [208, 0 // Header
		];

		var bb = new BytesBuffer();
		for (i in p1)
			bb.addByte(i);

		var r = new Reader(new haxe.io.BytesInput(bb.getBytes()));
		var p = r.read();

		Assert.same({
			pktType: CtrlPktType.Pingresp,
			dup: false,
			qos: QoS.AtMostOnce,
			retain: false
		}, p);

		var o = new haxe.io.BytesOutput();
		var w = new Writer(o);
		w.write(p);
		Assert.same(bb.getBytes(), o.getBytes());
	}
}
