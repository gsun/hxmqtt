package mqtt;

class Reader {
	var i:haxe.io.Input;
	var bits:format.tools.BitsInput;

	public function new(i) {
		this.i = i;
		this.i.bigEndian = true;
		bits = new format.tools.BitsInput(i);
	}

	function readString(i:haxe.io.Input) {
		var size = i.readUInt16();
		return i.readString(size, UTF8);
	}

	function readBinary(i:haxe.io.Input) {
		var size = i.readUInt16();
		return i.read(size);
	}

	function readVariableByteInteger(i:haxe.io.Input) {
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
		var length = readVariableByteInteger(i);
		var buffer = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var connectPorperties:ConnackProperties = {};
		while (buffer.pos < length) {
			var propertyId:ConnectPropertyId = readVariableByteInteger(buffer);
			switch (propertyId) {
				case SessionExpiryInterval:
					Reflect.setField(connectPorperties, "sessionExpiryInterval", buffer.readUInt32());
				case AuthenticationMethod:
					Reflect.setField(connectPorperties, "authenticationMethod", readString(buffer));
				case AuthenticationData:
					Reflect.setField(connectPorperties, "authenticationData", readBinary(buffer));
				case RequestProblemInformation:
					Reflect.setField(connectPorperties, "requestProblemInformation", buffer.readByte());
				case RequestResponseInformation:
					Reflect.setField(connectPorperties, "requestResponseInformation", buffer.readByte());
				case ReceiveMaximum:
					Reflect.setField(connectPorperties, "receiveMaximum", buffer.readUInt16());
				case TopicAliasMaximum:
					Reflect.setField(connectPorperties, "topicAliasMaximum", buffer.readUInt16());
				case UserProperty:
					Reflect.setField(connectPorperties, "userProperty", readString(buffer));
				case MaximumPacketSize:
					Reflect.setField(connectPorperties, "maximumPacketSize", buffer.readUInt32());
				default:
					throw new MalformedPacketException('Invalid connect property id ${propertyId}.');
			}
		}
		return connectPorperties;
	}

	function readWillProperties():WillProperties {
		var length = readVariableByteInteger(i);
		var buffer = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var willPorperties:willPorperties = {};
		while (buffer.pos < length) {
			var propertyId:WillPropertyId = readVariableByteInteger(buffer);
			switch (propertyId) {
				case PayloadFormatIndicator:
					Reflect.setField(willPorperties, "payloadFormatIndicator", buffer.readByte());
				case MessageExpiryInterval:
					Reflect.setField(willPorperties, "messageExpiryInterval", buffer.readUInt32());
				case ContentType:
					Reflect.setField(willPorperties, "contentType", readString(buffer));
				case ResponseTopic:
					Reflect.setField(willPorperties, "responseTopic", readString(buffer));
				case CorrelationData:
					Reflect.setField(willPorperties, "correlationData", readBinary(buffer));
				case WillDelayInterval:
					Reflect.setField(willPorperties, "willDelayInterval", buffer.readUInt32());
				case UserProperty:
					Reflect.setField(willPorperties, "userProperty", readString(buffer));
				default:
					throw new MalformedPacketException('Invalid will property id ${propertyId}.');
			}
		}
		return willPorperties;
	}

	function readConnectBody():ConnectBody {
		var protocolName = readString(i);
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
		var clientId = readString(i);
		var willProperties = (willFlag) ? readWillProperties() : null;
		var willTopic = (willFlag) ? readString(i) : null;
		var willPayload = (willFlag) ? readBinary(i) : null;
		var userName = (userNameFlag) ? readString(i) : null;
		var password = (passwordFlag) ? readBinary(i) : null;
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
		var length = readVariableByteInteger(i);
		var buffer = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var connackPorperties:ConnackPorperties = {};
		while (buffer.pos < length) {
			var propertyId:ConnackPropertyId = readVariableByteInteger(buffer);
			switch (propertyId) {
				case SessionExpiryInterval:
					Reflect.setField(connackPorperties, "sessionExpiryInterval", buffer.readUInt32());
				case AssignedClientIdentifier:
					Reflect.setField(connackPorperties, "assignedClientIdentifier", readString(buffer));
				case ServerKeepAlive:
					Reflect.setField(connackPorperties, "serverKeepAlive", buffer.readUInt16());
				case AuthenticationMethod:
					Reflect.setField(connackPorperties, "authenticationMethod", readString(buffer));
				case AuthenticationData:
					Reflect.setField(connackPorperties, "authenticationData", readBinary(buffer));
				case ResponseInformation:
					Reflect.setField(connackPorperties, "responseInformation", readString(buffer));
				case ServerReference:
					Reflect.setField(connackPorperties, "serverReference", readString(buffer));
				case ReasonString:
					Reflect.setField(connackPorperties, "reasonString", readString(buffer));
				case ReceiveMaximum:
					Reflect.setField(connackPorperties, "receiveMaximum", buffer.readUInt16());
				case TopicAliasMaximum:
					Reflect.setField(connackPorperties, "topicAliasMaximum", buffer.readUInt16());
				case MaximumQoS:
					Reflect.setField(connackPorperties, "maximumQoS", buffer.readByte());
				case RetainAvailable:
					Reflect.setField(connackPorperties, "retainAvailable", buffer.readByte());
				case UserProperty:
					Reflect.setField(connackPorperties, "userProperty", readString(buffer));
				case MaximumPacketSize:
					Reflect.setField(connackPorperties, "maximumPacketSize", buffer.readUInt32());
				case WildcardSubscriptionAvailable:
					Reflect.setField(connackPorperties, "wildcardSubscriptionAvailable", buffer.readByte());
				case SubscriptionIdentifierAvailable:
					Reflect.setField(connackPorperties, "subscriptionIdentifierAvailable", buffer.readByte());
				case SharedSubscriptionAvailabe:
					Reflect.setField(connackPorperties, "sharedSubscriptionAvailabe", buffer.readByte());
				default:
					throw new MalformedPacketException('Invalid connack property id ${propertyId}.');
			}
		}
		return connackPorperties;
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
