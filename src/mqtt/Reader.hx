package mqtt;

import mqtt.Constants;
import mqtt.Data;
import mqtt.AbstractEnumTools;

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
		if (eof())
			throw new MqttReaderException('eof');
		var size = i.readUInt16();
		return i.readString(size, UTF8);
	}

	inline function readBinary() {
		if (eof())
			throw new MqttReaderException('eof');
		var size = i.readUInt16();
		return i.read(size);
	}

	inline function readByte() {
		if (eof())
			throw new MqttReaderException('eof');
		return i.readByte();
	}

	inline function readUInt16() {
		if (eof())
			throw new MqttReaderException('eof');
		return i.readUInt16();
	}

	inline function readInt32() {
		if (eof())
			throw new MqttReaderException('eof');
		return i.readInt32();
	}

	inline function eof() {
		var b = cast(i, haxe.io.BufferInput);
		if (b != null)
			return (b.pos >= b.buf.length) ? true : false;
		return false;
	}

	function readVariableByteInteger() {
		var value = 0;
		var multiplier = 1;
		var byte;
		do {
			byte = i.readByte();
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
		var bo = {};
		try {
			bo = reader.read();
		} catch (e) {
			trace(e);
		}
		return bo;
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
		var bo = {};
		try {
			bo = reader.read();
		} catch (e) {
			trace(e);
		}
		return bo;
	}

	public function read():Dynamic {
		var pktType = bits.readBits(4);
		var dup = bits.readBit();
		var qos = bits.readBits(2);
		var retain = bits.readBit();
		if (pktType <= cast(CtrlPktType.Reserved, Int) || pktType > cast(CtrlPktType.Auth, Int))
			throw new MqttReaderException('invalid packet type ${pktType}');
		if (qos < cast(QoS.AtMostOnce, Int) || qos > cast(QoS.ExactlyOnce, Int))
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
		var u = {};
		try {
			while (!eof()) {
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
						Reflect.setField(u, readString(), readString());
					case ConnectPropertyId.MaximumPacketSize:
						Reflect.setField(p, "maximumPacketSize", readInt32());
					default:
						throw new MqttReaderException('Invalid connect property id ${propertyId}.');
				}
			}
		} catch (e) {
			trace(e);
		}
		if (Reflect.fields(u).length > 0)
			Reflect.setField(p, "userProperty", u);
		return p;
	}
}

class WillPropertiesReader extends Reader {
	override function read():Dynamic {
		var p = {};
		var u = {};
		try {
			while (!eof()) {
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
						Reflect.setField(u, readString(), readString());
					default:
						throw new MqttReaderException('Invalid will property id ${propertyId}.');
				}
			}
		} catch (e) {
			trace(e);
		}
		if (Reflect.fields(u).length > 0)
			Reflect.setField(p, "userProperty", u);
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
		var u = {};
		try {
			while (!eof()) {
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
						Reflect.setField(u, readString(), readString());
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
		} catch (e) {
			trace(e);
		}
		if (Reflect.fields(u).length > 0)
			Reflect.setField(p, "userProperty", u);
		return p;
	}
}

class ConnackReader extends Reader {
	override public function read():Dynamic {
		bits.readBits(7);
		var sessionPresent = bits.readBit();
		var reasonCode = readByte();
		var ea = AbstractEnumTools.getValues(ConnackReasonCode);
		if (!ea.contains(reasonCode))
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
		var u = {};
		var i = new Array<Int>();
		try {
			while (!eof()) {
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
						i.push(readVariableByteInteger());
					case PublishPropertyId.TopicAlias:
						Reflect.setField(p, "topicAlias", readUInt16());
					case PublishPropertyId.UserProperty:
						Reflect.setField(u, readString(), readString());

					default:
						throw new MqttReaderException('Invalid publish property id ${propertyId}.');
				}
			}
		} catch (e) {
			trace(e);
		}
		if (Reflect.fields(u).length > 0)
			Reflect.setField(p, "userProperty", u);
		if (i.length > 0)
			Reflect.setField(p, "subscriptionIdentifier", i);
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
		var u = {};
		try {
			while (!eof()) {
				var propertyId = readVariableByteInteger();
				switch (propertyId) {
					case PubackPropertyId.ReasonString:
						Reflect.setField(p, "reasonString", readString());
					case PubackPropertyId.UserProperty:
						Reflect.setField(u, readString(), readString());

					default:
						throw new MqttReaderException('Invalid puback property id ${propertyId}.');
				}
			}
		} catch (e) {
			trace(e);
		}
		if (Reflect.fields(u).length > 0)
			Reflect.setField(p, "userProperty", u);
		return p;
	}
}

class PubackReader extends Reader {
	override public function read():Dynamic {
		var packetIdentifier = readUInt16();
		var reasonCode = readByte();
		var ea = AbstractEnumTools.getValues(PubackReasonCode);
		if (!ea.contains(reasonCode))
			throw new MqttReaderException('Invalid puback reason code ${reasonCode}.');
		var properties = readProperties(PropertyKind.Puback);
		return {
			packetIdentifier: packetIdentifier,
			reasonCode: reasonCode,
			properties: properties
		};
	}
}

class PubrecPropertiesReader extends Reader {
	override public function read():Dynamic {
		var p = {};
		var u = {};
		try {
			while (!eof()) {
				var propertyId = readVariableByteInteger();
				switch (propertyId) {
					case PubrecPropertyId.ReasonString:
						Reflect.setField(p, "reasonString", readString());
					case PubrecPropertyId.UserProperty:
						Reflect.setField(u, readString(), readString());
					default:
						throw new MqttReaderException('Invalid puback property id ${propertyId}.');
				}
			}
		} catch (e) {
			trace(e);
		}
		if (Reflect.fields(u).length > 0)
			Reflect.setField(p, "userProperty", u);
		return p;
	}
}

class PubrecReader extends Reader {
	override public function read():Dynamic {
		var packetIdentifier = readUInt16();
		var reasonCode = readByte();
		var ea = AbstractEnumTools.getValues(PubrecReasonCode);
		if (!ea.contains(reasonCode))
			throw new MqttReaderException('Invalid pubrec reason code ${reasonCode}.');
		var properties = readProperties(PropertyKind.Pubrec);
		return {
			packetIdentifier: packetIdentifier,
			reasonCode: reasonCode,
			properties: properties
		};
	}
}

class PubrelPropertiesReader extends Reader {
	override public function read():Dynamic {
		var p = {};
		var u = {};
		try {
			while (!eof()) {
				var propertyId = readVariableByteInteger();
				switch (propertyId) {
					case PubrelPropertyId.ReasonString:
						Reflect.setField(p, "reasonString", readString());
					case PubrelPropertyId.UserProperty:
						Reflect.setField(u, readString(), readString());

					default:
						throw new MqttReaderException('Invalid puback property id ${propertyId}.');
				}
			}
		} catch (e) {
			trace(e);
		}
		if (Reflect.fields(u).length > 0)
			Reflect.setField(p, "userProperty", u);
		return p;
	}
}

class PubrelReader extends Reader {
	override public function read():Dynamic {
		var packetIdentifier = readUInt16();
		var reasonCode = readByte();
		var ea = AbstractEnumTools.getValues(PubrelReasonCode);
		if (!ea.contains(reasonCode))
			throw new MqttReaderException('Invalid pubrel reason code ${reasonCode}.');
		var properties = readProperties(PropertyKind.Pubrel);
		return {
			packetIdentifier: packetIdentifier,
			reasonCode: reasonCode,
			properties: properties
		};
	}
}

class PubcompPropertiesReader extends Reader {
	override public function read():Dynamic {
		var p = {};
		var u = {};
		try {
			while (!eof()) {
				var propertyId = readVariableByteInteger();
				switch (propertyId) {
					case PubcompPropertyId.ReasonString:
						Reflect.setField(p, "reasonString", readString());
					case PubcompPropertyId.UserProperty:
						Reflect.setField(u, readString(), readString());
					default:
						throw new MqttReaderException('Invalid pubcomp property id ${propertyId}.');
				}
			}
		} catch (e) {
			trace(e);
		}
		if (Reflect.fields(u).length > 0)
			Reflect.setField(p, "userProperty", u);
		return p;
	}
}

class PubcompReader extends Reader {
	override public function read():Dynamic {
		var packetIdentifier = readUInt16();
		var reasonCode = readByte();
		var ea = AbstractEnumTools.getValues(PubcompReasonCode);
		if (!ea.contains(reasonCode))
			throw new MqttReaderException('Invalid pubcomp reason code ${reasonCode}.');
		var properties = readProperties(PropertyKind.Pubcomp);
		return {
			packetIdentifier: packetIdentifier,
			reasonCode: reasonCode,
			properties: properties
		};
	}
}

class SubscribePropertiesReader extends Reader {
	override public function read():Dynamic {
		var p = {};
		var u = {};
		try {
			while (!eof()) {
				var propertyId = readVariableByteInteger();
				switch (propertyId) {
					case SubscribePropertyId.SubscriptionIdentifier:
						Reflect.setField(p, "subscriptionIdentifier", readVariableByteInteger());
					case SubscribePropertyId.UserProperty:
						Reflect.setField(u, readString(), readString());
					default:
						throw new MqttReaderException('Invalid subscribe property id ${propertyId}.');
				}
			}
		} catch (e) {
			trace(e);
		}
		if (Reflect.fields(u).length > 0)
			Reflect.setField(p, "userProperty", u);
		return p;
	}
}

class SubscribeReader extends Reader {
	override public function read():Dynamic {
		var packetIdentifier = readUInt16();
		var properties = readProperties(PropertyKind.Subscribe);
		var subscriptions:Array<Subscription> = [];
		try {
			while (!eof()) {
				var topic = readString();
				bits.readBits(2);
				var rh = bits.readBits(2);
				var rap = bits.readBit();
				var nl = bits.readBit();
				var qos = bits.readBits(2);
				subscriptions.push({
					topic: topic,
					rh: rh,
					rap: rap,
					nl: nl,
					qos: qos
				});
			}
		} catch (e) {
			trace(e);
		}
		return {
			packetIdentifier: packetIdentifier,
			subscriptions: subscriptions,
			properties: properties
		};
	}
}

class SubackPropertiesReader extends Reader {
	override public function read():Dynamic {
		var p = {};
		var u = {};
		try {
			while (!eof()) {
				var propertyId = readVariableByteInteger();
				switch (propertyId) {
					case SubackPropertyId.ReasonString:
						Reflect.setField(p, "reasonString", readString());
					case SubackPropertyId.UserProperty:
						Reflect.setField(u, readString(), readString());
					default:
						throw new MqttReaderException('Invalid suback property id ${propertyId}.');
				}
			}
		} catch (e) {
			trace(e);
		}
		if (Reflect.fields(u).length > 0)
			Reflect.setField(p, "userProperty", u);
		return p;
	}
}

class SubackReader extends Reader {
	override public function read():Dynamic {
		var packetIdentifier = readUInt16();
		var properties = readProperties(PropertyKind.Suback);
		var granted:Array<SubackReasonCode> = [];
		try {
			while (!eof()) {
				var reasonCode = readByte();
				var ea = AbstractEnumTools.getValues(SubackReasonCode);
				if (!ea.contains(reasonCode))
					throw new MqttReaderException('Invalid suback reason code ${reasonCode}.');
				granted.push(reasonCode);
			}
		} catch (e) {
			trace(e);
		}
		return {
			packetIdentifier: packetIdentifier,
			properties: properties,
			granted: granted
		};
	}
}

class UnsubscribePropertiesReader extends Reader {
	override public function read():Dynamic {
		var p = {};
		var u = {};
		try {
			while (!eof()) {
				var propertyId = readVariableByteInteger();
				switch (propertyId) {
					case UnsubscribePropertyId.UserProperty:
						Reflect.setField(u, readString(), readString());
					default:
						throw new MqttReaderException('Invalid unsubscribe property id ${propertyId}.');
				}
			}
		} catch (e) {
			trace(e);
		}
		if (Reflect.fields(u).length > 0)
			Reflect.setField(p, "userProperty", u);
		return p;
	}
}

class UnsubscribeReader extends Reader {
	override public function read():Dynamic {
		var packetIdentifier = readUInt16();
		var properties = readProperties(PropertyKind.Unsubscribe);
		var unsubscriptions:Array<String> = [];
		try {
			while (!eof()) {
				var topic = readString();
				unsubscriptions.push(topic);
			}
		} catch (e) {
			trace(e);
		}
		return {
			packetIdentifier: packetIdentifier,
			properties: properties,
			unsubscriptions: unsubscriptions
		};
	}
}

class UnsubackPropertiesReader extends Reader {
	override public function read():Dynamic {
		var p = {};
		var u = {};
		try {
			while (!eof()) {
				var propertyId = readVariableByteInteger();
				switch (propertyId) {
					case UnsubackPropertyId.ReasonString:
						Reflect.setField(p, "reasonString", readString());
					case UnsubackPropertyId.UserProperty:
						Reflect.setField(u, readString(), readString());
					default:
						throw new MqttReaderException('Invalid unsuback property id ${propertyId}.');
				}
			}
		} catch (e) {
			trace(e);
		}
		if (Reflect.fields(u).length > 0)
			Reflect.setField(p, "userProperty", u);
		return p;
	}
}

class UnsubackReader extends Reader {
	override public function read():Dynamic {
		var packetIdentifier = readUInt16();
		var properties = readProperties(PropertyKind.Unsuback);
		var granted:Array<SubackReasonCode> = [];
		try {
			while (!eof()) {
				var reasonCode = readByte();
				var ea = AbstractEnumTools.getValues(UnsubackReasonCode);
				if (!ea.contains(reasonCode))
					throw new MqttReaderException('Invalid unsuback reason code ${reasonCode}.');
				granted.push(reasonCode);
			}
		} catch (e) {
			trace(e);
		}
		return {
			packetIdentifier: packetIdentifier,
			properties: properties,
			granted: granted
		};
	}
}

class AuthPropertiesReader extends Reader {
	override public function read():Dynamic {
		var p = {};
		var u = {};
		try {
			while (!eof()) {
				var propertyId = readVariableByteInteger();
				switch (propertyId) {
					case AuthPropertyId.SessionExpiryInterval:
						Reflect.setField(p, "sessionExpiryInterval", readInt32());
					case AuthPropertyId.ServerReference:
						Reflect.setField(p, "serverReference", readString());
					case AuthPropertyId.ReasonString:
						Reflect.setField(p, "reasonString", readString());
					case AuthPropertyId.UserProperty:
						Reflect.setField(u, readString(), readString());

					default:
						throw new MqttReaderException('Invalid auth property id ${propertyId}.');
				}
			}
		} catch (e) {
			trace(e);
		}
		if (Reflect.fields(u).length > 0)
			Reflect.setField(p, "userProperty", u);
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
		var u = {};
		try {
			while (!eof()) {
				var propertyId = readVariableByteInteger();
				switch (propertyId) {
					case DisconnectPropertyId.AuthenticationMethod:
						Reflect.setField(p, "authenticationMethod", readString());
					case DisconnectPropertyId.AuthenticationData:
						Reflect.setField(p, "authenticationData", readBinary());
					case DisconnectPropertyId.ReasonString:
						Reflect.setField(p, "reasonString", readString());
					case DisconnectPropertyId.UserProperty:
						Reflect.setField(u, readString(), readString());
					default:
						throw new MqttReaderException('Invalid disconnect property id ${propertyId}.');
				}
			}
		} catch (e) {
			trace(e);
		}
		if (Reflect.fields(u).length > 0)
			Reflect.setField(p, "userProperty", u);
		return p;
	}
}

class DisconnectReader extends Reader {
	override public function read():Dynamic {
		return {};
	}
}
