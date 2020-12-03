package mqtt;

class Reader {
	var i:haxe.io.Input;
	var bits:format.tools.BitsInput;

	static var cls:Map<CtrlPktType, String> = [
		Connect => "mqtt.ConnectReader", Connack => "mqtt.ConnackReader", Publish => "mqtt.PublishReader", Puback => "mqtt.PubackReader",
		Pubrec => "mqtt.PubrecReader", Pubrel => "mqtt.PubrelReader", Pubcomp => "mqtt.PubcompReader", Subscribe => "mqtt.SubscribeReader",
		Suback => "mqtt.SubackReader", Unsubscribe => "mqtt.UnsubscribeReader", Unsuback => "mqtt.UnsubackReader", Disconnect => "mqtt.DisconnectReader",
		Auth => "mqtt.ConnectReader"
	];

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
				throw new MqttReaderException('Invalid variable Byte Integer.');
			multiplier *= 128;
		} while ((byte & 128) != 0);
		return value;
	}

	function readBody(pktType:CtrlPktType) {
		var remainingLength = readVariableByteInteger();
		if (remainingLength == 0)
			return null;

		var bi = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(remainingLength));
		var cl = Type.resolveClass(cls[pktType]);
		if (cl == null)
			throw new MqttReaderException("resolveClass ${cls[pktType]} fail");
		var reader = Type.createInstance(cl, [bi]);
		return reader.read();
	}

	public function read():MqttPacket {
		var pktType = bits.readBits(4);
		var dup = bits.readBit();
		var qos = bits.readBits(2);
		var retain = bits.readBit();
		if (pktType <= CtrlPktType.Reserved || pktType > CtrlPktType.Auth)
			throw new MqttReaderException('invalid packet type ${pktType}');
		if (qos < Qos.AtMostOnce || qos > Qos.ExactlyOnce)
			throw new MqttReaderException('invalid Qos ${qos}');
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

class ConnectPropertiesReader extends Reader {
	function read():ConnectProperties {
		var p = {};
		while (i.pos < i.buf.length) {
			var propertyId = readVariableByteInteger();
			switch (propertyId) {
				case ConnectPropertyId.SessionExpiryInterval:
					Reflect.setField(p, "sessionExpiryInterval", i.readUInt32());
				case ConnectPropertyId.AuthenticationMethod:
					Reflect.setField(p, "authenticationMethod", readString());
				case ConnectPropertyId.AuthenticationData:
					Reflect.setField(p, "authenticationData", readBinary());
				case ConnectPropertyId.RequestProblemInformation:
					Reflect.setField(p, "requestProblemInformation", i.readByte());
				case ConnectPropertyId.RequestResponseInformation:
					Reflect.setField(p, "requestResponseInformation", i.readByte());
				case ConnectPropertyId.ReceiveMaximum:
					Reflect.setField(p, "receiveMaximum", i.readUInt16());
				case ConnectPropertyId.TopicAliasMaximum:
					Reflect.setField(p, "topicAliasMaximum", i.readUInt16());
				case ConnectPropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString());
				case ConnectPropertyId.MaximumPacketSize:
					Reflect.setField(p, "maximumPacketSize", i.readUInt32());
				default:
					throw new MqttReaderException('Invalid connect property id ${propertyId}.');
			}
		}
		return p;
	}
}

class WillPropertiesReader extends Reader {
	function read():WillProperties {
		var p = {};
		while (i.pos < i.buf.length) {
			var propertyId = readVariableByteInteger();
			switch (propertyId) {
				case WillPropertyId.PayloadFormatIndicator:
					Reflect.setField(p, "payloadFormatIndicator", i.readByte());
				case WillPropertyId.MessageExpiryInterval:
					Reflect.setField(p, "messageExpiryInterval", i.readUInt32());
				case WillPropertyId.ContentType:
					Reflect.setField(p, "contentType", readString());
				case WillPropertyId.ResponseTopic:
					Reflect.setField(p, "responseTopic", readString());
				case WillPropertyId.CorrelationData:
					Reflect.setField(p, "correlationData", readBinary());
				case WillPropertyId.WillDelayInterval:
					Reflect.setField(p, "willDelayInterval", i.readUInt32());
				case WillPropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString());
				default:
					throw new MqttReaderException('Invalid will property id ${propertyId}.');
			}
		}
		return p;
	}
}

class ConnectReader extends Reader {
	function readConnectProperties():ConnectProperties {
		var length = readVariableByteInteger();
		var bi = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var reader = new ConnectPropertiesReader(bi);
		return reader.read();
	}

	function readWillProperties():WillProperties {
		var length = readVariableByteInteger();
		var bi = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var reader = new WillPropertiesReader(bi);
		return reader.read();
	}

	public function read():AuthBody {
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
			throw new MqttReaderException('Invalid MQTT name ${protocolName}.');
		if (protocolVersion != ProtocolVersion.V5)
			throw new MqttReaderException('Invalid MQTT version ${protocolVersion}.');
		var connectPorperties = readConnectProperties();
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
}

class ConnackPropertiesReader extends Reader {
	function read():ConnackProperties {
		var p = {};
		while (i.pos < i.buf.length) {
			var propertyId = readVariableByteInteger();
			switch (propertyId) {
				case ConnackPropertyId.SessionExpiryInterval:
					Reflect.setField(p, "sessionExpiryInterval", i.readUInt32());
				case ConnackPropertyId.AssignedClientIdentifier:
					Reflect.setField(p, "assignedClientIdentifier", readString());
				case ConnackPropertyId.ServerKeepAlive:
					Reflect.setField(p, "serverKeepAlive", i.readUInt16());
				case ConnackPropertyId.AuthenticationMethod:
					Reflect.setField(p, "authenticationMethod", readString());
				case ConnackPropertyId.AuthenticationData:
					Reflect.setField(p, "authenticationData", readBinary());
				case ConnackPropertyId.ResponseInformation:
					Reflect.setField(p, "responseInformation", readString());
				case ConnackPropertyId.ServerReference:
					Reflect.setField(p, "serverReference", readString());
				case ConnackPropertyId.ReasonString:
					Reflect.setField(p, "reasonString", readString());
				case ConnackPropertyId.ReceiveMaximum:
					Reflect.setField(p, "receiveMaximum", i.readUInt16());
				case ConnackPropertyId.TopicAliasMaximum:
					Reflect.setField(p, "topicAliasMaximum", i.readUInt16());
				case ConnackPropertyId.MaximumQoS:
					Reflect.setField(p, "maximumQoS", i.readByte());
				case ConnackPropertyId.RetainAvailable:
					Reflect.setField(p, "retainAvailable", i.readByte());
				case ConnackPropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString());
				case ConnackPropertyId.MaximumPacketSize:
					Reflect.setField(p, "maximumPacketSize", i.readUInt32());
				case ConnackPropertyId.WildcardSubscriptionAvailable:
					Reflect.setField(p, "wildcardSubscriptionAvailable", i.readByte());
				case ConnackPropertyId.SubscriptionIdentifierAvailable:
					Reflect.setField(p, "subscriptionIdentifierAvailable", i.readByte());
				case ConnackPropertyId.SharedSubscriptionAvailabe:
					Reflect.setField(p, "sharedSubscriptionAvailabe", i.readByte());
				default:
					throw new MqttReaderException('Invalid connack property id ${propertyId}.');
			}
		}
		return p;
	}
}

class ConnackReader extends Reader {
	function readProperties():ConnackProperties {
		var length = readVariableByteInteger();
		var bi = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var reader = new ConnackPropertiesReader(bi);
		return reader.read();
	}

	public function read():ConnackBody {
		Bits.readBits(7);
		var sessionPresent = Bits.readBit();
		var reasonCode = i.readByte();
		if (!Type.allEnums(ConnackReasonCode).contains(reasonCode))
			throw new MqttReaderException('Invalid connack reason code ${reasonCode}.');
		var properties = readProperties();
		return {
			reasonCode: reasonCode,
			sessionPresent: sessionPresent,
			properties: properties
		};
	}
}

class PublishPropertiesReader extends Reader {
	function read():PublishProperties {
		var p = {};
		while (i.pos < i.buf.length) {
			var propertyId = readVariableByteInteger();
			switch (propertyId) {
				case PublishPropertyId.PayloadFormatIndicator:
					Reflect.setField(p, "payloadFormatIndicator", i.readByte());
				case PublishPropertyId.MessageExpiryInterval:
					Reflect.setField(p, "messageExpiryInterval", i.readUInt32());
				case PublishPropertyId.ContentType:
					Reflect.setField(p, "contentType", readString());
				case PublishPropertyId.ResponseTopic:
					Reflect.setField(p, "responseTopic", readString());
				case PublishPropertyId.CorrelationData:
					Reflect.setField(p, "correlationData", readBinary());
				case PublishPropertyId.SubscriptionIdentifier:
					Reflect.setField(p, "subscriptionIdentifier", readVariableByteInteger());
				case PublishPropertyId.TopicAlias:
					Reflect.setField(p, "topicAlias", i.readUInt16());
				case PublishPropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString());
				default:
					throw new MqttReaderException('Invalid publish property id ${propertyId}.');
			}
		}
		return p;
	}
}

class PublishReader extends Reader {
	function readProperties():PublishProperties {
		var length = readVariableByteInteger();
		var bi = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var reader = new PublishPropertiesReader(bi);
		return reader.read();
	}

	public function read():PublishBody {
		var topic = readString();
		var packetIdentifier = i.readUInt16();
		var properties = readProperties();
		var payload = i.readAll();
		return {
			topic: topic,
			packetIdentifier: packetIdentifier,
			properties: properties,
			payload: payload
		};
	}
}

class PubackPropertiesReader extends Reader {
	function read():PubackProperties {
		var p = {};
		while (i.pos < i.buf.length) {
			var propertyId = readVariableByteInteger();
			switch (propertyId) {
				case PubackPropertyId.ReasonString:
					Reflect.setField(p, "reasonString", readString());
				case PubackPropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString());
				default:
					throw new MqttReaderException('Invalid puback property id ${propertyId}.');
			}
		}
		return p;
	}
}

class PubackReader extends Reader {
	function readProperties():PubackProperties {
		var length = readVariableByteInteger();
		var bi = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var reader = new PubackPropertiesReader(bi);
		return reader.read();
	}

	public function read():PubackBody {
		Bits.readBits(7);
		var sessionPresent = Bits.readBit();
		var reasonCode = i.readByte();
		if (!Type.allEnums(ConnackReasonCode).contains(reasonCode))
			throw new MqttReaderException('Invalid connack reason code ${reasonCode}.');
		var properties = readProperties();
		return {
			reasonCode: reasonCode,
			sessionPresent: sessionPresent,
			properties: properties
		};
	}
}

class PubrecPropertiesReader extends Reader {
	function read():PubrecProperties {
		var p = {};
		while (i.pos < i.buf.length) {
			var propertyId = readVariableByteInteger();
			switch (propertyId) {
				case PubrecPropertyId.ReasonString:
					Reflect.setField(p, "reasonString", readString());
				case PubrecPropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString());
				default:
					throw new MqttReaderException('Invalid puback property id ${propertyId}.');
			}
		}
		return p;
	}
}

class PubrecReader extends Reader {
	function readProperties():PubrecProperties {
		var length = readVariableByteInteger();
		var bi = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var reader = new PubrecPropertiesReader(bi);
		return reader.read();
	}

	public function read():PubrecBody {
		return {};
	}
}

class PubrelPropertiesReader extends Reader {
	function read():PubrelProperties {
		var p = {};
		while (i.pos < i.buf.length) {
			var propertyId = readVariableByteInteger();
			switch (propertyId) {
				case PubrelPropertyId.ReasonString:
					Reflect.setField(p, "reasonString", readString());
				case PubrelPropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString());
				default:
					throw new MqttReaderException('Invalid puback property id ${propertyId}.');
			}
		}
		return p;
	}
}

class PubrelReader extends Reader {
	function readProperties():PubrelProperties {
		var length = readVariableByteInteger();
		var bi = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var reader = new PubrelPropertiesReader(bi);
		return reader.read();
	}

	public function read():PubrelBody {
		return {};
	}
}

class PubcompPropertiesReader extends Reader {
	function read():PubcompProperties {
		var p = {};
		while (i.pos < i.buf.length) {
			var propertyId = readVariableByteInteger();
			switch (propertyId) {
				case PubcompPropertyId.ReasonString:
					Reflect.setField(p, "reasonString", readString());
				case PubcompPropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString());
				default:
					throw new MqttReaderException('Invalid pubcomp property id ${propertyId}.');
			}
		}
		return p;
	}
}

class PubcompReader extends Reader {
	function readProperties():PubcompProperties {
		var length = readVariableByteInteger();
		var bi = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var reader = new PubcompPropertiesReader(bi);
		return reader.read();
	}

	public function read():PubcompBody {
		return {};
	}
}

class SubscribePropertiesReader extends Reader {
	function read():SubscribeProperties {
		var p = {};
		while (i.pos < i.buf.length) {
			var propertyId = readVariableByteInteger();
			switch (propertyId) {
				case SubscribePropertyId.SubscriptionIdentifier:
					Reflect.setField(p, "subscriptionIdentifier", readVariableByteInteger());
				case SubscribePropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString());
				default:
					throw new MqttReaderException('Invalid subscribe property id ${propertyId}.');
			}
		}
		return p;
	}
}

class SubscribeReader extends Reader {
	function readProperties():SubscribeProperties {
		var length = readVariableByteInteger();
		var bi = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var reader = new SubscribePropertiesReader(bi);
		return reader.read();
	}

	public function read():SubscribeBody {
		var packetIdentifier = i.readUInt16();
		var properties = readSubackProperties();
		var subscriptions:Array<Subscription> = [];
		return {};
	}
}

class SubackPropertiesReader extends Reader {
	function read():SubackProperties {
		var p = {};
		while (i.pos < i.buf.length) {
			var propertyId = readVariableByteInteger();
			switch (propertyId) {
				case SubackPropertyId.ReasonString:
					Reflect.setField(p, "reasonString", readString());
				case SubackPropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString());
				default:
					throw new MqttReaderException('Invalid suback property id ${propertyId}.');
			}
		}
		return p;
	}
}

class SubackReader extends Reader {
	function readProperties():SubackProperties {
		var length = readVariableByteInteger();
		var bi = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var reader = new SubackPropertiesReader(bi);
		return reader.read();
	}

	public function read():SubackBody {
		return {};
	}
}

class UnsubscribePropertiesReader extends Reader {
	function read():UnsubscribeProperties {
		var p = {};
		while (i.pos < i.buf.length) {
			var propertyId = readVariableByteInteger();
			switch (propertyId) {
				case UnsubscribePropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString());
				default:
					throw new MqttReaderException('Invalid unsubscribe property id ${propertyId}.');
			}
		}
		return p;
	}
}

class UnsubscribeReader extends Reader {
	function readProperties():UnsubscribeProperties {
		var length = readVariableByteInteger();
		var bi = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var reader = new UnsubscribePropertiesReader(bi);
		return reader.read();
	}

	public function read():UnsubscribeBody {
		return {};
	}
}

class UnsubackPropertiesReader extends Reader {
	function read():UnsubackProperties {
		var p = {};
		while (i.pos < i.buf.length) {
			var propertyId = readVariableByteInteger();
			switch (propertyId) {
				case UnsubackPropertyId.ReasonString:
					Reflect.setField(p, "reasonString", readString());
				case UnsubackPropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString());
				default:
					throw new MqttReaderException('Invalid unsuback property id ${propertyId}.');
			}
		}
		return p;
	}
}

class UnsubackReader extends Reader {
	function readProperties():UnsubackProperties {
		var length = readVariableByteInteger();
		var bi = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var reader = new UnsubackPropertiesReader(bi);
		return reader.read();
	}

	public function read():UnsubackBody {
		return {};
	}
}

class AuthPropertiesReader extends Reader {
	function read():AuthProperties {
		var p = {};
		while (i.pos < i.buf.length) {
			var propertyId = readVariableByteInteger();
			switch (propertyId) {
				case AuthPropertyId.SessionExpiryInterval:
					Reflect.setField(p, "sessionExpiryInterval", i.readUInt32());
				case AuthPropertyId.ServerReference:
					Reflect.setField(p, "serverReference", readString());
				case AuthPropertyId.ReasonString:
					Reflect.setField(p, "reasonString", readString());
				case AuthPropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString());
				default:
					throw new MqttReaderException('Invalid auth property id ${propertyId}.');
			}
		}
		return p;
	}
}

class AuthReader extends Reader {
	function readProperties():AuthProperties {
		var length = readVariableByteInteger();
		var bi = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var reader = new AuthPropertiesReader(bi);
		return reader.read();
	}

	public function read():AuthBody {
		return {};
	}
}

class DisconnectPropertiesReader extends Reader {
	public function read():DisconnectProperties {
		var p = {};
		while (i.pos < i.buf.length) {
			var propertyId = readVariableByteInteger();
			switch (propertyId) {
				case DisconnectPropertyId.AuthenticationMethod:
					Reflect.setField(p, "authenticationMethod", readString());
				case DisconnectPropertyId.AuthenticationData:
					Reflect.setField(p, "authenticationData", readBinary());
				case DisconnectPropertyId.ReasonString:
					Reflect.setField(p, "reasonString", readString());
				case DisconnectPropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString());
				default:
					throw new MqttReaderException('Invalid disconnect property id ${propertyId}.');
			}
		}
		return p;
	}
}

class DisconnectReader extends Reader {
	function readProperties():DisconnectProperties {
		var length = readVariableByteInteger();
		var bi = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var reader = new DisconnectPropertiesReader(bi);
		return reader.read();
	}

	public function read():DisconnectBody {
		return {};
	}
}
