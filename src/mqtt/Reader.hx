package mqtt;

class Reader {
	var i:haxe.io.Input;
	var bits:format.tools.BitsInput;

	public function new(i) {
		this.i = i;
		this.i.bigEndian = true;
		bits = new format.tools.BitsInput(i);
	}

	function readString() {
		var size = i.readUInt16();
		return i.readString(size, UTF8);
	}

	function readBinary() {
		var size = i.readUInt16();
		return i.read(size);
	}

	function readVariableByteInteger() {
		var value = 0;
		var multiplier = 1;
		do {
			var byte = i.readByte();
			value += ((byte & 127) * multiplier);
			if (multiplier > 2097152)
				throw new MalformedPacketException('Invalid variable Byte Integer.');
			multiplier *= 128;
		} while ((byte & 128) != 0);
		return value;
	}

	function readBody(t:CtrlPktType):Dynamic {
		return switch (t) {
			case Connect:
				readConnectBody();
			case Connack:
				readConnackBody();
			case Publish:
				readPublishBody();
			case Puback:
				readPubackBody();
			case Pubrec:
				readPubrecBody();
			case Pubrel:
				readPubrelBody();
			case Pubcomp:
				readPubcompBody();
			case Subscribe:
				readSubscribeBody();
			case Suback:
				readSubackBody();
			case Unsubscribe:
				readUnsubscribeBody();
			case Unsuback:
				readUnsubackBody();
			case Disconnect:
				readDisconnectBody();
			case Auth:
				readAuthBody();
		}
	}

	function readConnectProperties():ConnectProperties {
		return {};
	}

	function readWillProperties():WillProperties {
		return {};
	}

	function readConnectBody():ConnectBody {
		var protocolName = readString();
		var protocolVersion = i.readByte();
		var userNameFlag = Bits.readBit();
		var passwordFlag = Bits.readBit();
		var willRetainFlag = Bits.readBit();
		var willQos = Bits.readBits(2);
		var willFlag = Bits.readBit();
		var cleanStart = Bits.readBit();
		var reserved = Bits.readBit();
		var keepAlive = i.readUInt16();
		if (protocolName != ProtocolName.Mqtt)
			throw new MalformedPacketException('Invalid MQTT name ${protocolName}.');
		if (protocolVersion != ProtocolVersion.V5)
			throw new MalformedPacketException('Invalid MQTT version ${protocolVersion}.');
		var connectPorperties = readConnackProperties();
		var clientId = readString();
		var willProperties = (willFlag) ? readWillProperties() : null;
		var willTopic = (willFlag) ? readString() : null;
		var willPayload = (willFlag) ? readBinary() : null;
		var userName = (userNameFlag) ? readString() : null;
		var password = (passwordFlag) ? readBinary() : null;
		var will = {
			topic: willTopic,
			payload: willPayload;
			qos: willQos,
			retain: willRetainFlag,
			properties: willProperties
		};
		return {
			clientId: clientId,
			protocolVersion: protocolVersion,
			protocolName: protocolName,
			cleanStart: cleanStart,
			keepalive: keepAlive,
			username: userName,
			password: password,
			will: will,
			properties: connectPorperties
		};
	}

	function readConnackProperties():ConnackProperties {
		return {};
	}

	function readConnackBody():ConnackBody {
		return {};
	}

	function readPublishBody():PublishBody {
		return {};
	}

	function readPubackProperties():PubackProperties {
		return {};
	}

	function readPubackBody():PubackBody {
		return {};
	}

	function readPubrecProperties():PubrecProperties {
		return {};
	}

	function readPubrecBody():PubrecBody {
		return {};
	}

	function readPubrelProperties():PubrelProperties {
		return {};
	}

	function readPubrelBody():PubrelBody {
		return {};
	}

	function readPubcompProperties():PubcompProperties {
		return {};
	}

	function readPubcompBody():PubcompBody {
		return {};
	}

	function readSubscribeProperties():SubscribeProperties {
		return {};
	}

	function readSubscribeBody():SubscribeBody {
		return {};
	}

	function readSubackProperties():SubackProperties {
		return {};
	}

	function readSubackBody():SubackBody {
		return {};
	}

	function readUnsubscribeProperties():UnsubscribeProperties {
		return {};
	}

	function readUnsubscribeBody():UnsubscribeBody {
		return {};
	}

	function readUnsubackProperties():UnsubackProperties {
		return {};
	}

	function readUnsubackBody():UnsubackBody {
		return {};
	}

	function readDisconnectProperties():DisconnectProperties {
		return {};
	}

	function readDisconnectBody():DisconnectBody {
		return {};
	}

	function readAuthBody():AuthBody {
		return {};
	}

	public function read():MqttPacket {
		var pktType = bits.readBits(4);
		var dup = bits.readBit();
		var qos = bits.readBits(2);
		var retain = bits.readBit();
		if (pktType <= CtrlPktType.Reserved || pktType > CtrlPktType.Auth)
			throw new MalformedPacketException('invalid packet type ${pktType}');
		if (qos < Qos.AtMostOnce || qos > Qos.ExactlyOnce)
			throw new MalformedPacketException('invalid Qos ${qos}');
		var body = readBody(pktType);
		return {
			pktType: pktType,
			dup: dup,
			qos: qos,
			retain: retain,
			body: body
		};
	}
}
