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

	function readConnectProperties():ConnectProperties {
		var length = readVariableByteInteger(i);
		var buffer = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var p = {};
		while (buffer.pos < length) {
			var propertyId = readVariableByteInteger(buffer);
			switch (propertyId) {
				case ConnectPropertyId.SessionExpiryInterval:
					Reflect.setField(p, "sessionExpiryInterval", buffer.readUInt32());
				case ConnectPropertyId.AuthenticationMethod:
					Reflect.setField(p, "authenticationMethod", readString(buffer));
				case ConnectPropertyId.AuthenticationData:
					Reflect.setField(p, "authenticationData", readBinary(buffer));
				case ConnectPropertyId.RequestProblemInformation:
					Reflect.setField(p, "requestProblemInformation", buffer.readByte());
				case ConnectPropertyId.RequestResponseInformation:
					Reflect.setField(p, "requestResponseInformation", buffer.readByte());
				case ConnectPropertyId.ReceiveMaximum:
					Reflect.setField(p, "receiveMaximum", buffer.readUInt16());
				case ConnectPropertyId.TopicAliasMaximum:
					Reflect.setField(p, "topicAliasMaximum", buffer.readUInt16());
				case ConnectPropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString(buffer));
				case ConnectPropertyId.MaximumPacketSize:
					Reflect.setField(p, "maximumPacketSize", buffer.readUInt32());
				default:
					throw new MalformedPacketException('Invalid connect property id ${propertyId}.');
			}
		}
		return p;
	}

	function readWillProperties():WillProperties {
		var length = readVariableByteInteger(i);
		var buffer = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var p = {};
		while (buffer.pos < length) {
			var propertyId = readVariableByteInteger(buffer);
			switch (propertyId) {
				case WillPropertyId.PayloadFormatIndicator:
					Reflect.setField(p, "payloadFormatIndicator", buffer.readByte());
				case WillPropertyId.MessageExpiryInterval:
					Reflect.setField(p, "messageExpiryInterval", buffer.readUInt32());
				case WillPropertyId.ContentType:
					Reflect.setField(p, "contentType", readString(buffer));
				case WillPropertyId.ResponseTopic:
					Reflect.setField(p, "responseTopic", readString(buffer));
				case WillPropertyId.CorrelationData:
					Reflect.setField(p, "correlationData", readBinary(buffer));
				case WillPropertyId.WillDelayInterval:
					Reflect.setField(p, "willDelayInterval", buffer.readUInt32());
				case WillPropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString(buffer));
				default:
					throw new MalformedPacketException('Invalid will property id ${propertyId}.');
			}
		}
		return p;
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
		var p = {};
		while (buffer.pos < length) {
			var propertyId = readVariableByteInteger(buffer);
			switch (propertyId) {
				case ConnackPropertyId.SessionExpiryInterval:
					Reflect.setField(p, "sessionExpiryInterval", buffer.readUInt32());
				case ConnackPropertyId.AssignedClientIdentifier:
					Reflect.setField(p, "assignedClientIdentifier", readString(buffer));
				case ConnackPropertyId.ServerKeepAlive:
					Reflect.setField(p, "serverKeepAlive", buffer.readUInt16());
				case ConnackPropertyId.AuthenticationMethod:
					Reflect.setField(p, "authenticationMethod", readString(buffer));
				case ConnackPropertyId.AuthenticationData:
					Reflect.setField(p, "authenticationData", readBinary(buffer));
				case ConnackPropertyId.ResponseInformation:
					Reflect.setField(p, "responseInformation", readString(buffer));
				case ConnackPropertyId.ServerReference:
					Reflect.setField(p, "serverReference", readString(buffer));
				case ConnackPropertyId.ReasonString:
					Reflect.setField(p, "reasonString", readString(buffer));
				case ConnackPropertyId.ReceiveMaximum:
					Reflect.setField(p, "receiveMaximum", buffer.readUInt16());
				case ConnackPropertyId.TopicAliasMaximum:
					Reflect.setField(p, "topicAliasMaximum", buffer.readUInt16());
				case ConnackPropertyId.MaximumQoS:
					Reflect.setField(p, "maximumQoS", buffer.readByte());
				case ConnackPropertyId.RetainAvailable:
					Reflect.setField(p, "retainAvailable", buffer.readByte());
				case ConnackPropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString(buffer));
				case ConnackPropertyId.MaximumPacketSize:
					Reflect.setField(p, "maximumPacketSize", buffer.readUInt32());
				case ConnackPropertyId.WildcardSubscriptionAvailable:
					Reflect.setField(p, "wildcardSubscriptionAvailable", buffer.readByte());
				case ConnackPropertyId.SubscriptionIdentifierAvailable:
					Reflect.setField(p, "subscriptionIdentifierAvailable", buffer.readByte());
				case ConnackPropertyId.SharedSubscriptionAvailabe:
					Reflect.setField(p, "sharedSubscriptionAvailabe", buffer.readByte());
				default:
					throw new MalformedPacketException('Invalid connack property id ${propertyId}.');
			}
		}
		return p;
	}

	function readConnackBody():ConnackBody {
		Bits.readBits(7);
		var sessionPresent = Bits.readBit();
		var reasonCode = i.readByte();
		if (!Type.allEnums(ConnackReasonCode).contains(reasonCode))
			throw new MalformedPacketException('Invalid connack reason code ${reasonCode}.');
		var properties = readConnackProperties();
		return {
			reasonCode: reasonCode,
			sessionPresent: sessionPresent,
			properties: properties
		};
	}

	function readPublishProperties():PublishProperties {
		var length = readVariableByteInteger(i);
		var buffer = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var p = {};
		while (buffer.pos < length) {
			var propertyId = readVariableByteInteger(buffer);
			switch (propertyId) {
				case PublishPropertyId.PayloadFormatIndicator:
					Reflect.setField(p, "payloadFormatIndicator", buffer.readByte());
				case PublishPropertyId.MessageExpiryInterval:
					Reflect.setField(p, "messageExpiryInterval", buffer.readUInt32());
				case PublishPropertyId.ContentType:
					Reflect.setField(p, "contentType", readString(buffer));
				case PublishPropertyId.ResponseTopic:
					Reflect.setField(p, "responseTopic", readString(buffer));
				case PublishPropertyId.CorrelationData:
					Reflect.setField(p, "correlationData", readBinary(buffer));
				case PublishPropertyId.SubscriptionIdentifier:
					Reflect.setField(p, "subscriptionIdentifier", readVariableByteInteger(buffer));
				case PublishPropertyId.TopicAlias:
					Reflect.setField(p, "topicAlias", buffer.readUInt16());
				case PublishPropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString(buffer));
				default:
					throw new MalformedPacketException('Invalid publish property id ${propertyId}.');
			}
		}
		return p;
	}

	function readPublishBody():PublishBody {
		var topic = readString(i);
		var packetIdentifier = i.readUInt16();
		var properties = readPublishProperties();
		var payload = i.readAll();
		return {
			topic: topic,
			packetIdentifier:packetIdentifier,
			properties: properties,
			payload: payload
		};
	}

	function readPubackProperties():PubackProperties {
		var length = readVariableByteInteger(i);
		var buffer = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var p = {};
		while (buffer.pos < length) {
			var propertyId = readVariableByteInteger(buffer);
			switch (propertyId) {
				case PubackPropertyId.ReasonString:
					Reflect.setField(p, "reasonString", readString(buffer));
				case PubackPropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString(buffer));
				default:
					throw new MalformedPacketException('Invalid puback property id ${propertyId}.');
			}
		}
		return p;
	}

	function readPubackBody():PubackBody {
		Bits.readBits(7);
		var sessionPresent = Bits.readBit();
		var reasonCode = i.readByte();
		if (!Type.allEnums(ConnackReasonCode).contains(reasonCode))
			throw new MalformedPacketException('Invalid connack reason code ${reasonCode}.');
		var properties = readConnackProperties();
		return {
			reasonCode: reasonCode,
			sessionPresent: sessionPresent,
			properties: properties
		};
	}

	function readPubrecProperties():PubrecProperties {
		var length = readVariableByteInteger(i);
		var buffer = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var p = {};
		while (buffer.pos < length) {
			var propertyId = readVariableByteInteger(buffer);
			switch (propertyId) {
				case PubrecPropertyId.ReasonString:
					Reflect.setField(p, "reasonString", readString(buffer));
				case PubrecPropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString(buffer));
				default:
					throw new MalformedPacketException('Invalid puback property id ${propertyId}.');
			}
		}
		return p;
	}

	function readPubrecBody():PubrecBody {
		return {};
	}

	function readPubrelProperties():PubrelProperties {
		var length = readVariableByteInteger(i);
		var buffer = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var p: = {};
		while (buffer.pos < length) {
			var propertyId = readVariableByteInteger(buffer);
			switch (propertyId) {
				case PubrelPropertyId.ReasonString:
					Reflect.setField(p, "reasonString", readString(buffer));
				case PubrelPropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString(buffer));
				default:
					throw new MalformedPacketException('Invalid puback property id ${propertyId}.');
			}
		}
		return p;
	}

	function readPubrelBody():PubrelBody {
		return {};
	}

	function readPubcompProperties():PubcompProperties {
		var length = readVariableByteInteger(i);
		var buffer = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var p = {};
		while (buffer.pos < length) {
			var propertyId = readVariableByteInteger(buffer);
			switch (propertyId) {
				case PubcompPropertyId.ReasonString:
					Reflect.setField(p, "reasonString", readString(buffer));
				case PubcompPropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString(buffer));
				default:
					throw new MalformedPacketException('Invalid pubcomp property id ${propertyId}.');
			}
		}
		return p;
	}

	function readPubcompBody():PubcompBody {
		return {};
	}

	function readSubscribeProperties():SubscribeProperties {
		var length = readVariableByteInteger(i);
		var buffer = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var p = {};
		while (buffer.pos < length) {
			var propertyId = readVariableByteInteger(buffer);
			switch (propertyId) {
				case SubscribePropertyId.SubscriptionIdentifier:
					Reflect.setField(p, "subscriptionIdentifier", readVariableByteInteger(buffer));
				case SubscribePropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString(buffer));
				default:
					throw new MalformedPacketException('Invalid subscribe property id ${propertyId}.');
			}
		}
		return p;
	}

	function readSubscribeBody():SubscribeBody {
		var packetIdentifier = i.readUInt16();
		var properties = readSubackProperties();
		var subscriptions:Array<Subscription> = [];
		return {};
	}

	function readSubackProperties():SubackProperties {
		var length = readVariableByteInteger(i);
		var buffer = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var p = {};
		while (buffer.pos < length) {
			var propertyId = readVariableByteInteger(buffer);
			switch (propertyId) {
				case SubackPropertyId.ReasonString:
					Reflect.setField(p, "reasonString", readString(buffer));
				case SubackPropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString(buffer));
				default:
					throw new MalformedPacketException('Invalid suback property id ${propertyId}.');
			}
		}
		return p;
	}

	function readSubackBody():SubackBody {
		return {};
	}

	function readUnsubscribeProperties():UnsubscribeProperties {
		var length = readVariableByteInteger(i);
		var buffer = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var p = {};
		while (buffer.pos < length) {
			var propertyId = readVariableByteInteger(buffer);
			switch (propertyId) {
				case UnsubscribePropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString(buffer));
				default:
					throw new MalformedPacketException('Invalid unsubscribe property id ${propertyId}.');
			}
		}
		return p;
	}

	function readUnsubscribeBody():UnsubscribeBody {
		return {};
	}

	function readUnsubackProperties():UnsubackProperties {
		var length = readVariableByteInteger(i);
		var buffer = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var p = {};
		while (buffer.pos < length) {
			var propertyId = readVariableByteInteger(buffer);
			switch (propertyId) {
				case UnsubackPropertyId.ReasonString:
					Reflect.setField(p, "reasonString", readString(buffer));
				case UnsubackPropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString(buffer));
				default:
					throw new MalformedPacketException('Invalid unsuback property id ${propertyId}.');
			}
		}
		return p;
	}

	function readUnsubackBody():UnsubackBody {
		return {};
	}

	function readDisconnectProperties():DisconnectProperties {
		var length = readVariableByteInteger(i);
		var buffer = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var p = {};
		while (buffer.pos < length) {
			var propertyId = readVariableByteInteger(buffer);
			switch (propertyId) {
				case DisconnectPropertyId.AuthenticationMethod:
					Reflect.setField(p, "authenticationMethod", readString(buffer));
				case DisconnectPropertyId.AuthenticationData:
					Reflect.setField(p, "authenticationData", readBinary(buffer));
				case DisconnectPropertyId.ReasonString:
					Reflect.setField(p, "reasonString", readString(buffer));
				case DisconnectPropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString(buffer));
				default:
					throw new MalformedPacketException('Invalid disconnect property id ${propertyId}.');
			}
		}
		return p;
	}

	function readDisconnectBody():DisconnectBody {
		return {};
	}

	function readAuthProperties():AuthProperties {
		var length = readVariableByteInteger(i);
		var buffer = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var p = {};
		while (buffer.pos < length) {
			var propertyId = readVariableByteInteger(buffer);
			switch (propertyId) {
				case AuthPropertyId.SessionExpiryInterval:
					Reflect.setField(p, "sessionExpiryInterval", buffer.readUInt32());
				case AuthPropertyId.ServerReference:
					Reflect.setField(p, "serverReference", readString(buffer));
				case AuthPropertyId.ReasonString:
					Reflect.setField(p, "reasonString", readString(buffer));
				case AuthPropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString(buffer));
				default:
					throw new MalformedPacketException('Invalid auth property id ${propertyId}.');
			}
		}
		return p;
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
		var remainingLength = readVariableByteInteger(i);
		var body = switch (pktType) {
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
		return {
			pktType: pktType,
			dup: dup,
			qos: qos,
			retain: retain,
			body: body
		};
	}
}
