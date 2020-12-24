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
		Auth => "mqtt.AuthReader"
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
			return null;

		var remainingLength = readVariableByteInteger();
		if (remainingLength == 0)
			return null;

		var bi = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(remainingLength));
		var reader = Type.createInstance(cl, [bi]);
		try {
			return reader.read();
		} catch (e) {
			return null;
		}
	}

	function readProperties<T:Reader>(cl:Class<T>) {
		var length = readVariableByteInteger();
		if (length == 0)
			return null;

		var bi = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(length));
		var reader = Type.createInstance(cl, [bi]);
		try {
			return reader.read();
		} catch (e) {
			return null;
		}
	}

	public function read():Dynamic {
		var pktType = bits.readBits(4);
		var dup = bits.readBit();
		var qos = bits.readBits(2);
		var retain = bits.readBit();
		if (!AbstractEnumTools.getValues(CtrlPktType).contains(pktType))
			throw new MqttReaderException('invalid packet type ${pktType}');
		if (!AbstractEnumTools.getValues(QoS).contains(qos))
			throw new MqttReaderException('invalid Qos ${qos}');
		var body = readBody(pktType);
		var p:MqttPacket = {
			pktType: pktType,
			dup: dup,
			qos: qos,
			retain: retain
		};
		if (body != null)
			p.body = body;
		return p;
	}
}

class ConnectPropertiesReader extends Reader {
	override function read():ConnectProperties {
		var p:ConnectProperties = {};
		var u = {};
		try {
			while (!eof()) {
				var propertyId = readVariableByteInteger();
				switch (propertyId) {
					case ConnectPropertyId.SessionExpiryInterval:
						p.sessionExpiryInterval = readInt32();
					case ConnectPropertyId.AuthenticationMethod:
						p.authenticationMethod = readString();
					case ConnectPropertyId.AuthenticationData:
						p.authenticationData = readBinary();
					case ConnectPropertyId.RequestProblemInformation:
						p.requestProblemInformation = (readByte() == 0) ? false : true;
					case ConnectPropertyId.RequestResponseInformation:
						p.requestResponseInformation = (readByte() == 0) ? false : true;
					case ConnectPropertyId.ReceiveMaximum:
						p.receiveMaximum = readUInt16();
					case ConnectPropertyId.TopicAliasMaximum:
						p.topicAliasMaximum = readUInt16();
					case ConnectPropertyId.UserProperty:
						Reflect.setField(u, readString(), readString());
					case ConnectPropertyId.MaximumPacketSize:
						p.maximumPacketSize = readInt32();
					default:
						throw new MqttReaderException('Invalid connect property id ${propertyId}.');
				}
			}
		} catch (e) {
			trace(e);
			return null;
		}
		if (Reflect.fields(u).length > 0)
			p.userProperty = u;
		return p;
	}
}

class WillPropertiesReader extends Reader {
	override function read():WillProperties {
		var p:WillProperties = {};
		var u = {};
		try {
			while (!eof()) {
				var propertyId = readVariableByteInteger();
				switch (propertyId) {
					case WillPropertyId.PayloadFormatIndicator:
						p.payloadFormatIndicator = readByte();
					case WillPropertyId.MessageExpiryInterval:
						p.messageExpiryInterval = readInt32();
					case WillPropertyId.ContentType:
						p.contentType = readString();
					case WillPropertyId.ResponseTopic:
						p.responseTopic = readString();
					case WillPropertyId.CorrelationData:
						p.correlationData = readBinary();
					case WillPropertyId.WillDelayInterval:
						p.willDelayInterval = readInt32();
					case WillPropertyId.UserProperty:
						Reflect.setField(u, readString(), readString());
					default:
						throw new MqttReaderException('Invalid will property id ${propertyId}.');
				}
			}
		} catch (e) {
			trace(e);
			return null;
		}
		if (Reflect.fields(u).length > 0)
			p.userProperty = u;
		return p;
	}
}

class ConnectReader extends Reader {
	override public function read():ConnectBody {
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
		var connectPorperties:ConnectProperties = cast readProperties(ConnectPropertiesReader);
		var clientId = readString();
		var willProperties:WillProperties = (willFlag) ? cast readProperties(WillPropertiesReader) : null;
		var willTopic = (willFlag) ? readString() : null;
		var willPayload = (willFlag) ? readBinary() : null;
		var userName = (userNameFlag) ? readString() : null;
		var password = (passwordFlag) ? readBinary() : null;
		var will:Will = {
			topic: willTopic,
			payload: willPayload,
			qos: willQos,
			retain: willRetainFlag
		};
		if (willProperties != null)
			will.properties = willProperties;
		var p:ConnectBody = {
			clientId: clientId,
			protocolVersion: protocolVersion,
			protocolName: protocolName,
			cleanStart: cleanStart,
			keepalive: keepAlive
		};
		if (willFlag)
			p.will = will;
		if (userNameFlag)
			p.username = userName;
		if (passwordFlag)
			p.password = password;
		if (connectPorperties != null)
			p.properties = connectPorperties;
		return p;
	}
}

class ConnackPropertiesReader extends Reader {
	override function read():ConnackProperties {
		var p:ConnackProperties = {};
		var u = {};
		try {
			while (!eof()) {
				var propertyId = readVariableByteInteger();
				switch (propertyId) {
					case ConnackPropertyId.SessionExpiryInterval:
						p.sessionExpiryInterval = readInt32();
					case ConnackPropertyId.AssignedClientIdentifier:
						p.assignedClientIdentifier = readString();
					case ConnackPropertyId.ServerKeepAlive:
						p.serverKeepAlive = readUInt16();
					case ConnackPropertyId.AuthenticationMethod:
						p.authenticationMethod = readString();
					case ConnackPropertyId.AuthenticationData:
						p.authenticationData = readBinary();
					case ConnackPropertyId.ResponseInformation:
						p.responseInformation = readString();
					case ConnackPropertyId.ServerReference:
						p.serverReference = readString();
					case ConnackPropertyId.ReasonString:
						p.reasonString = readString();
					case ConnackPropertyId.ReceiveMaximum:
						p.receiveMaximum = readUInt16();
					case ConnackPropertyId.TopicAliasMaximum:
						p.topicAliasMaximum = readUInt16();
					case ConnackPropertyId.MaximumQoS:
						p.maximumQoS = readByte();
					case ConnackPropertyId.RetainAvailable:
						p.retainAvailable = (readByte() == 0) ? false : true;
					case ConnackPropertyId.UserProperty:
						Reflect.setField(u, readString(), readString());
					case ConnackPropertyId.MaximumPacketSize:
						p.maximumPacketSize = readInt32();
					case ConnackPropertyId.WildcardSubscriptionAvailable:
						p.wildcardSubscriptionAvailable = (readByte() == 0) ? false : true;
					case ConnackPropertyId.SubscriptionIdentifierAvailable:
						p.subscriptionIdentifierAvailable = (readByte() == 0) ? false : true;
					case ConnackPropertyId.SharedSubscriptionAvailable:
						p.sharedSubscriptionAvailable = (readByte() == 0) ? false : true;
					default:
						throw new MqttReaderException('Invalid connack property id ${propertyId}.');
				}
			}
		} catch (e) {
			trace(e);
			return null;
		}
		if (Reflect.fields(u).length > 0)
			p.userProperty = u;
		return p;
	}
}

class ConnackReader extends Reader {
	override public function read():ConnackBody {
		bits.readBits(7);
		var sessionPresent = bits.readBit();
		var reasonCode = readByte();
		var ea = AbstractEnumTools.getValues(ConnackReasonCode);
		if (!ea.contains(reasonCode))
			throw new MqttReaderException('Invalid connack reason code ${reasonCode}.');
		var properties:ConnackProperties = cast readProperties(ConnackPropertiesReader);
		return {
			reasonCode: reasonCode,
			sessionPresent: sessionPresent,
			properties: properties
		};
	}
}

class PublishPropertiesReader extends Reader {
	override function read():PublishProperties {
		var p:PublishProperties = {};
		var u = {};
		var i = new Array<Int>();
		try {
			while (!eof()) {
				var propertyId = readVariableByteInteger();
				switch (propertyId) {
					case PublishPropertyId.PayloadFormatIndicator:
						p.payloadFormatIndicator = readByte();
					case PublishPropertyId.MessageExpiryInterval:
						p.messageExpiryInterval = readInt32();
					case PublishPropertyId.ContentType:
						p.contentType = readString();
					case PublishPropertyId.ResponseTopic:
						p.responseTopic = readString();
					case PublishPropertyId.CorrelationData:
						p.correlationData = readBinary();
					case PublishPropertyId.SubscriptionIdentifier:
						i.push(readVariableByteInteger());
					case PublishPropertyId.TopicAlias:
						p.topicAlias = readUInt16();
					case PublishPropertyId.UserProperty:
						Reflect.setField(u, readString(), readString());
					default:
						throw new MqttReaderException('Invalid publish property id ${propertyId}.');
				}
			}
		} catch (e) {
			trace(e);
			return null;
		}
		if (Reflect.fields(u).length > 0)
			p.userProperty = u;
		if (i.length > 0)
			p.subscriptionIdentifier = i;
		return p;
	}
}

class PublishReader extends Reader {
	override public function read():PublishBody {
		var topic = readString();
		var packetIdentifier = readUInt16();
		var properties:PublishProperties = cast readProperties(PublishPropertiesReader);
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
	override public function read():PubackProperties {
		var p:PubackProperties = {};
		var u = {};
		try {
			while (!eof()) {
				var propertyId = readVariableByteInteger();
				switch (propertyId) {
					case PubackPropertyId.ReasonString:
						p.reasonString = readString();
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
			p.userProperty = u;
		return p;
	}
}

class PubackReader extends Reader {
	override public function read():PubackBody {
		var packetIdentifier = readUInt16();
		var reasonCode = readByte();
		var ea = AbstractEnumTools.getValues(PubackReasonCode);
		if (!ea.contains(reasonCode))
			throw new MqttReaderException('Invalid puback reason code ${reasonCode}.');
		var properties:PubackProperties = cast readProperties(PubackPropertiesReader);
		return {
			packetIdentifier: packetIdentifier,
			reasonCode: reasonCode,
			properties: properties
		};
	}
}

class PubrecPropertiesReader extends Reader {
	override public function read():PubrecProperties {
		var p:PubrecProperties = {};
		var u = {};
		try {
			while (!eof()) {
				var propertyId = readVariableByteInteger();
				switch (propertyId) {
					case PubrecPropertyId.ReasonString:
						p.reasonString = readString();
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
			p.userProperty = u;
		return p;
	}
}

class PubrecReader extends Reader {
	override public function read():PubrecBody {
		var packetIdentifier = readUInt16();
		var reasonCode = readByte();
		var ea = AbstractEnumTools.getValues(PubrecReasonCode);
		if (!ea.contains(reasonCode))
			throw new MqttReaderException('Invalid pubrec reason code ${reasonCode}.');
		var properties:PubrecProperties = cast readProperties(PubrecPropertiesReader);
		return {
			packetIdentifier: packetIdentifier,
			reasonCode: reasonCode,
			properties: properties
		};
	}
}

class PubrelPropertiesReader extends Reader {
	override public function read():PubrelProperties {
		var p:PubrelProperties = {};
		var u = {};
		try {
			while (!eof()) {
				var propertyId = readVariableByteInteger();
				switch (propertyId) {
					case PubrelPropertyId.ReasonString:
						p.reasonString = readString();
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
			p.userProperty = u;
		return p;
	}
}

class PubrelReader extends Reader {
	override public function read():PubrelBody {
		var packetIdentifier = readUInt16();
		var reasonCode = readByte();
		var ea = AbstractEnumTools.getValues(PubrelReasonCode);
		if (!ea.contains(reasonCode))
			throw new MqttReaderException('Invalid pubrel reason code ${reasonCode}.');
		var properties:PubrelProperties = cast readProperties(PubrelPropertiesReader);
		return {
			packetIdentifier: packetIdentifier,
			reasonCode: reasonCode,
			properties: properties
		};
	}
}

class PubcompPropertiesReader extends Reader {
	override public function read():PubcompProperties {
		var p:PubcompProperties = {};
		var u = {};
		try {
			while (!eof()) {
				var propertyId = readVariableByteInteger();
				switch (propertyId) {
					case PubcompPropertyId.ReasonString:
						p.reasonString = readString();
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
			p.userProperty = u;
		return p;
	}
}

class PubcompReader extends Reader {
	override public function read():PubcompBody {
		var packetIdentifier = readUInt16();
		var reasonCode = readByte();
		var ea = AbstractEnumTools.getValues(PubcompReasonCode);
		if (!ea.contains(reasonCode))
			throw new MqttReaderException('Invalid pubcomp reason code ${reasonCode}.');
		var properties:PubcompProperties = cast readProperties(PubcompPropertiesReader);
		return {
			packetIdentifier: packetIdentifier,
			reasonCode: reasonCode,
			properties: properties
		};
	}
}

class SubscribePropertiesReader extends Reader {
	override public function read():SubscribeProperties {
		var p:SubscribeProperties = {};
		var u = {};
		try {
			while (!eof()) {
				var propertyId = readVariableByteInteger();
				switch (propertyId) {
					case SubscribePropertyId.SubscriptionIdentifier:
						p.subscriptionIdentifier = readVariableByteInteger();
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
			p.userProperty = u;
		return p;
	}
}

class SubscribeReader extends Reader {
	override public function read():SubscribeBody {
		var packetIdentifier = readUInt16();
		var properties:SubscribeProperties = cast readProperties(SubscribePropertiesReader);
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
	override public function read():SubackProperties {
		var p:SubackProperties = {};
		var u = {};
		try {
			while (!eof()) {
				var propertyId = readVariableByteInteger();
				switch (propertyId) {
					case SubackPropertyId.ReasonString:
						p.reasonString = readString();
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
			p.userProperty = u;
		return p;
	}
}

class SubackReader extends Reader {
	override public function read():SubackBody {
		var packetIdentifier = readUInt16();
		var properties:SubackProperties = cast readProperties(SubackPropertiesReader);
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
	override public function read():UnsubscribeProperties {
		var p:UnsubscribeProperties = {};
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
			p.userProperty = u;
		return p;
	}
}

class UnsubscribeReader extends Reader {
	override public function read():UnsubscribeBody {
		var packetIdentifier = readUInt16();
		var properties:UnsubscribeProperties = cast readProperties(UnsubscribePropertiesReader);
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
	override public function read():UnsubackProperties {
		var p:UnsubackProperties = {};
		var u = {};
		try {
			while (!eof()) {
				var propertyId = readVariableByteInteger();
				switch (propertyId) {
					case UnsubackPropertyId.ReasonString:
						p.reasonString = readString();
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
			p.userProperty = u;
		return p;
	}
}

class UnsubackReader extends Reader {
	override public function read():UnsubackBody {
		var packetIdentifier = readUInt16();
		var properties:UnsubackProperties = cast readProperties(UnsubackPropertiesReader);
		var granted:Array<UnsubackReasonCode> = [];
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
	override public function read():AuthProperties {
		var p:AuthProperties = {};
		var u = {};
		try {
			while (!eof()) {
				var propertyId = readVariableByteInteger();
				switch (propertyId) {
					case AuthPropertyId.AuthenticationMethod:
						p.authenticationMethod = readString();
					case AuthPropertyId.AuthenticationData:
						p.authenticationData = readBinary();
					case AuthPropertyId.ReasonString:
						p.reasonString = readString();
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
			p.userProperty = u;
		return p;
	}
}

class AuthReader extends Reader {
	override public function read():Dynamic {
		var reasonCode = readByte();
		var ea = AbstractEnumTools.getValues(AuthReasonCode);
		if (!ea.contains(reasonCode))
			throw new MqttReaderException('Invalid auth reason code ${reasonCode}.');
		var properties:AuthProperties = cast readProperties(AuthPropertiesReader);
		return {reasonCode: reasonCode, properties: properties};
	}
}

class DisconnectPropertiesReader extends Reader {
	override public function read():DisconnectProperties {
		var p:DisconnectProperties = {};
		var u = {};
		try {
			while (!eof()) {
				var propertyId = readVariableByteInteger();
				switch (propertyId) {
					case DisconnectPropertyId.SessionExpiryInterval:
						p.sessionExpiryInterval = readInt32();
					case DisconnectPropertyId.ServerReference:
						p.serverReference = readString();
					case DisconnectPropertyId.ReasonString:
						p.reasonString = readString();
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
			p.userProperty = u;
		return p;
	}
}

class DisconnectReader extends Reader {
	override public function read():DisconnectBody {
		var reasonCode = readByte();
		var ea = AbstractEnumTools.getValues(DisconnectReasonCode);
		if (!ea.contains(reasonCode))
			throw new MqttReaderException('Invalid disconnect reason code ${reasonCode}.');
		var properties:DisconnectProperties = cast readProperties(DisconnectPropertiesReader);
		return {reasonCode: reasonCode, properties: properties};
	}
}
