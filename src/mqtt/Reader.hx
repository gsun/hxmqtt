package mqtt;
import mqtt.Constants;
import mqtt.Data;

class Reader {
	var i:haxe.io.Input;
	var bits:format.tools.BitsInput;

	static var ptCls:Map<CtrlPktType, String> = [
		Connect => "mqtt.ConnectReader", Connack => "mqtt.ConnackReader", Publish => "mqtt.PublishReader", Puback => "mqtt.PubackReader",
		Pubrec => "mqtt.PubrecReader", Pubrel => "mqtt.PubrelReader", Pubcomp => "mqtt.PubcompReader", Subscribe => "mqtt.SubscribeReader",
		Suback => "mqtt.SubackReader", Unsubscribe => "mqtt.UnsubscribeReader", Unsuback => "mqtt.UnsubackReader", Disconnect => "mqtt.DisconnectReader",
		Auth => "mqtt.ConnectReader"
	];
	static var pkCls:Map<PropertyKind, String> = [
		Connect => "mqtt.ConnectPropertiesReader", Connack => "mqtt.ConnackPropertiesReader", Publish => "mqtt.PublishPropertiesReader",
		Puback => "mqtt.PubackPropertiesReader", Pubrec => "mqtt.PubrecPropertiesReader", Pubrel => "mqtt.PubrelPropertiesReader",
		Pubcomp => "mqtt.PubcompPropertiesReader", Subscribe => "mqtt.SubscribePropertiesReader", Suback => "mqtt.SubackPropertiesReader",
		Unsubscribe => "mqtt.UnsubscribePropertiesReader", Unsuback => "mqtt.UnsubackPropertiesReader", Disconnect => "mqtt.DisconnectPropertiesReader",
		Auth => "mqtt.ConnectPropertiesReader", Will => "mqtt.WillPropertiesReader"
	];

	public function new(i) {
		this.i = i;
		this.i.bigEndian = true;
		bits = new format.tools.BitsInput(i);
	}

	inline function readString() {
		var size = i.readUInt16();
		return i.readString(size, UTF8);
	}

	inline function readBinary() {
		var size = i.readUInt16();
		return i.read(size);
	}

	inline function readByte() {
		return i.readByte();
	}

	inline function readUInt16() {
		return i.readUInt16();
	}

	inline function readInt32() {
		return i.readInt32();
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

	function readBody(t:CtrlPktType) {
		var cl = Type.resolveClass(ptCls[t]);
		if (cl == null)
			throw new MqttReaderException("pkt reader ${t} resolveClass ${ptCls[t]} fail");

		var remainingLength = readVariableByteInteger();
		if (remainingLength == 0)
			return null;

		var bi = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(remainingLength));
		var reader = Type.createInstance(cl, [bi]);
		return reader.read();
	}

	function readProperties(pc:PropertyKind) {
		var cl = Type.resolveClass(pkCls[pc]);
		if (cl == null)
			throw new MqttReaderException("property reader ${pc} resolveClass ${pkCls[pc]} fail");

		var length = readVariableByteInteger();
		if (length == 0)
			return null;

		var bi = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var reader = Type.createInstance(cl, [bi]);
		return reader.read();
	}

	public function read():Dynamic {
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
	override function read():Dynamic {
		var p = {};
		while (i.pos < i.buf.length) {
			var propertyId = readVariableByteInteger();
			switch (propertyId) {
				case ConnectPropertyId.SessionExpiryInterval:
					Reflect.setField(p, "sessionExpiryInterval", readInt32());
				case ConnectPropertyId.AuthenticationMethod:
					Reflect.setField(p, "authenticationMethod", readString());
				case ConnectPropertyId.AuthenticationData:
					Reflect.setField(p, "authenticationData", readBinary());
				case ConnectPropertyId.RequestProblemInformation:
					Reflect.setField(p, "requestProblemInformation", readByte());
				case ConnectPropertyId.RequestResponseInformation:
					Reflect.setField(p, "requestResponseInformation", readByte());
				case ConnectPropertyId.ReceiveMaximum:
					Reflect.setField(p, "receiveMaximum", readUInt16());
				case ConnectPropertyId.TopicAliasMaximum:
					Reflect.setField(p, "topicAliasMaximum", readUInt16());
				case ConnectPropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString());
				case ConnectPropertyId.MaximumPacketSize:
					Reflect.setField(p, "maximumPacketSize", readInt32());
				default:
					throw new MqttReaderException('Invalid connect property id ${propertyId}.');
			}
		}
		return p;
	}
}

class WillPropertiesReader extends Reader {
	override function read():Dynamic {
		var p = {};
		while (i.pos < i.buf.length) {
			var propertyId = readVariableByteInteger();
			switch (propertyId) {
				case WillPropertyId.PayloadFormatIndicator:
					Reflect.setField(p, "payloadFormatIndicator", readByte());
				case WillPropertyId.MessageExpiryInterval:
					Reflect.setField(p, "messageExpiryInterval", readInt32());
				case WillPropertyId.ContentType:
					Reflect.setField(p, "contentType", readString());
				case WillPropertyId.ResponseTopic:
					Reflect.setField(p, "responseTopic", readString());
				case WillPropertyId.CorrelationData:
					Reflect.setField(p, "correlationData", readBinary());
				case WillPropertyId.WillDelayInterval:
					Reflect.setField(p, "willDelayInterval", readInt32());
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
	override public function read():Dynamic {
		var protocolName = readString();
		var protocolVersion = readByte();
		var userNameFlag = bits.readBit();
		var passwordFlag = bits.readBit();
		var willRetainFlag = bits.readBit();
		var willQos = bits.readBits(2);
		var willFlag = bits.readBit();
		var cleanStart = bits.readBit();
		var reserved = bits.readBit();
		var keepAlive = readUInt16();
		if (protocolName != ProtocolName.Mqtt)
			throw new MqttReaderException('Invalid MQTT name ${protocolName}.');
		if (protocolVersion != ProtocolVersion.V5)
			throw new MqttReaderException('Invalid MQTT version ${protocolVersion}.');
		var connectPorperties = readProperties(PropertyKind.Connect);
		var clientId = readString();
		var willProperties = (willFlag) ? readProperties(PropertyKind.Will) : null;
		var willTopic = (willFlag) ? readString() : null;
		var willPayload = (willFlag) ? readBinary() : null;
		var userName = (userNameFlag) ? readString() : null;
		var password = (passwordFlag) ? readBinary() : null;
		var will = {
			topic: willTopic,
			payload: willPayload,
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
	override function read():Dynamic {
		var p = {};
		while (i.pos < i.buf.length) {
			var propertyId = readVariableByteInteger();
			switch (propertyId) {
				case ConnackPropertyId.SessionExpiryInterval:
					Reflect.setField(p, "sessionExpiryInterval", readInt32());
				case ConnackPropertyId.AssignedClientIdentifier:
					Reflect.setField(p, "assignedClientIdentifier", readString());
				case ConnackPropertyId.ServerKeepAlive:
					Reflect.setField(p, "serverKeepAlive", readUInt16());
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
					Reflect.setField(p, "receiveMaximum", readUInt16());
				case ConnackPropertyId.TopicAliasMaximum:
					Reflect.setField(p, "topicAliasMaximum", readUInt16());
				case ConnackPropertyId.MaximumQoS:
					Reflect.setField(p, "maximumQoS", readByte());
				case ConnackPropertyId.RetainAvailable:
					Reflect.setField(p, "retainAvailable", readByte());
				case ConnackPropertyId.UserProperty:
					Reflect.setField(p, "userProperty", readString());
				case ConnackPropertyId.MaximumPacketSize:
					Reflect.setField(p, "maximumPacketSize", readInt32());
				case ConnackPropertyId.WildcardSubscriptionAvailable:
					Reflect.setField(p, "wildcardSubscriptionAvailable", readByte());
				case ConnackPropertyId.SubscriptionIdentifierAvailable:
					Reflect.setField(p, "subscriptionIdentifierAvailable", readByte());
				case ConnackPropertyId.SharedSubscriptionAvailabe:
					Reflect.setField(p, "sharedSubscriptionAvailabe", readByte());
				default:
					throw new MqttReaderException('Invalid connack property id ${propertyId}.');
			}
		}
		return p;
	}
}

class ConnackReader extends Reader {
	override public function read():Dynamic {
		bits.readBits(7);
		var sessionPresent = bits.readBit();
		var reasonCode = readByte();
		if (!Type.allEnums(ConnackReasonCode).contains(reasonCode))
			throw new MqttReaderException('Invalid connack reason code ${reasonCode}.');
		var properties = readProperties(PropertyKind.Connack);
		return {
			reasonCode: reasonCode,
			sessionPresent: sessionPresent,
			properties: properties
		};
	}
}

class PublishPropertiesReader extends Reader {
	override function read():Dynamic {
		var p = {};
		while (i.pos < i.buf.length) {
			var propertyId = readVariableByteInteger();
			switch (propertyId) {
				case PublishPropertyId.PayloadFormatIndicator:
					Reflect.setField(p, "payloadFormatIndicator", readByte());
				case PublishPropertyId.MessageExpiryInterval:
					Reflect.setField(p, "messageExpiryInterval", readInt32());
				case PublishPropertyId.ContentType:
					Reflect.setField(p, "contentType", readString());
				case PublishPropertyId.ResponseTopic:
					Reflect.setField(p, "responseTopic", readString());
				case PublishPropertyId.CorrelationData:
					Reflect.setField(p, "correlationData", readBinary());
				case PublishPropertyId.SubscriptionIdentifier:
					Reflect.setField(p, "subscriptionIdentifier", readVariableByteInteger());
				case PublishPropertyId.TopicAlias:
					Reflect.setField(p, "topicAlias", readUInt16());
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
	override public function read():Dynamic {
		var topic = readString();
		var packetIdentifier = readUInt16();
		var properties = readProperties(PropertyKind.Publish);
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
	override public function read():Dynamic {
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
	override public function read():Dynamic {
		bits.readBits(7);
		var sessionPresent = bits.readBit();
		var reasonCode = readByte();
		if (!Type.allEnums(ConnackReasonCode).contains(reasonCode))
			throw new MqttReaderException('Invalid connack reason code ${reasonCode}.');
		var properties = readProperties(PropertyKind.Puback);
		return {
			reasonCode: reasonCode,
			sessionPresent: sessionPresent,
			properties: properties
		};
	}
}

class PubrecPropertiesReader extends Reader {
	override public function read():Dynamic {
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
	override public function read():Dynamic {
		return {};
	}
}

class PubrelPropertiesReader extends Reader {
	override public function read():Dynamic {
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
	override public function read():Dynamic {
		return {};
	}
}

class PubcompPropertiesReader extends Reader {
	override public function read():Dynamic {
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
	override public function read():Dynamic {
		return {};
	}
}

class SubscribePropertiesReader extends Reader {
	override public function read():Dynamic {
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
	override public function read():Dynamic {
		var packetIdentifier = readUInt16();
		var properties = readSubackProperties(PropertyKind.Subscribe);
		var subscriptions:Array<Subscription> = [];
		return {};
	}
}

class SubackPropertiesReader extends Reader {
	override public function read():Dynamic {
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
	override public function read():Dynamic {
		return {};
	}
}

class UnsubscribePropertiesReader extends Reader {
	override public function read():Dynamic {
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
	override public function read():Dynamic {
		return {};
	}
}

class UnsubackPropertiesReader extends Reader {
	override public function read():Dynamic {
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
	override public function read():Dynamic {
		return {};
	}
}

class AuthPropertiesReader extends Reader {
	override public function read():Dynamic {
		var p = {};
		while (i.pos < i.buf.length) {
			var propertyId = readVariableByteInteger();
			switch (propertyId) {
				case AuthPropertyId.SessionExpiryInterval:
					Reflect.setField(p, "sessionExpiryInterval", readInt32());
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
	override public function read():Dynamic {
		return {};
	}
}

class DisconnectPropertiesReader extends Reader {
	override public function read():Dynamic {
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
	override public function read():Dynamic {
		return {};
	}
}
