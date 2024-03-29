package mqtt;

import mqtt.Constants;
import mqtt.Data;
import haxe.io.Bytes;

class Writer {
	var o:haxe.io.Output;
	var p:MqttPacket;
	var bits:format.tools.BitsOutput;

	static var ptCls:Map<CtrlPktType, String> = [
		Connect => "mqtt.ConnectWriter", Connack => "mqtt.ConnackWriter", Publish => "mqtt.PublishWriter", Puback => "mqtt.PubackWriter",
		Pubrec => "mqtt.PubrecWriter", Pubrel => "mqtt.PubrelWriter", Pubcomp => "mqtt.PubcompWriter", Subscribe => "mqtt.SubscribeWriter",
		Suback => "mqtt.SubackWriter", Unsubscribe => "mqtt.UnsubscribeWriter", Unsuback => "mqtt.UnsubackWriter", Disconnect => "mqtt.DisconnectWriter",
		Auth => "mqtt.AuthWriter", Pingreq => "mqtt.PingreqWriter", Pingresp => "mqtt.PingrespWriter"
	];

	public function new(o:haxe.io.Output) {
		this.o = o;
		o.bigEndian = true;
		bits = new format.tools.BitsOutput(o);
	}

	inline function writeString(s:String) {
		o.writeUInt16(s.length);
		o.writeString(s, UTF8);
	}

	inline function writeBinary(b:Bytes) {
		o.writeUInt16(b.length);
		o.write(b);
	}

	inline function writeByte(c:Int) {
		o.writeByte(c);
	}

	inline function writeUInt16(x:Int) {
		o.writeUInt16(x);
	}

	inline function writeInt32(x:Int) {
		o.writeInt32(x);
	}

	function writeVariableByteInteger(x:Int) {
		var y = x;
		do {
			var b = y % 128;
			y = Math.floor(y / 128);
			if (y > 0)
				b = b | 128;
			o.writeByte(b);
		} while (y > 0);
	}

	function writeHeader() {
		bits.writeBits(4, p.pktType);
		bits.writeBit(p.dup);
		bits.writeBits(2, p.qos);
		bits.writeBit(p.retain);
	}

	function writeProperties<T:Writer>(cl:Class<T>) {
		var bo = new haxe.io.BytesOutput();
		var writer = Type.createInstance(cl, [bo]);
		try {
			writer.write(p);
			writeVariableByteInteger(bo.length);
			if (bo.length > 0)
				o.write(bo.getBytes());
		} catch (e) {
			trace(e);
		}
	}

	function writeBody() {
		var cl = Type.resolveClass(ptCls[p.pktType]);
		if (cl == null)
			return;
		var bo = new haxe.io.BytesOutput();
		var writer = Type.createInstance(cl, [bo]);
		try {
			writer.write(p);
			writeVariableByteInteger(bo.length);
			if (bo.length > 0)
				o.write(bo.getBytes());
		} catch (e) {
			trace(e);
		}
	}

	public function write(p:MqttPacket) {
		this.p = p;
		writeHeader();
		writeBody();
	}
}

class ConnectPropertiesWriter extends Writer {
	override function write(p:MqttPacket) {
		if (p.body.properties == null)
			return;
		var properties = p.body.properties;
		if (properties.sessionExpiryInterval != null) {
			writeVariableByteInteger(ConnectPropertyId.SessionExpiryInterval);
			writeInt32(properties.sessionExpiryInterval);
		}
		if (properties.authenticationMethod != null) {
			writeVariableByteInteger(ConnectPropertyId.AuthenticationMethod);
			writeString(properties.authenticationMethod);
		}
		if (properties.authenticationData != null) {
			writeVariableByteInteger(ConnectPropertyId.AuthenticationData);
			writeBinary(properties.authenticationData);
		}
		if (properties.requestProblemInformation != null) {
			writeVariableByteInteger(ConnectPropertyId.RequestProblemInformation);
			writeByte(properties.requestProblemInformation);
		}
		if (properties.requestResponseInformation != null) {
			writeVariableByteInteger(ConnectPropertyId.RequestResponseInformation);
			writeByte(properties.requestResponseInformation);
		}
		if (properties.receiveMaximum != null) {
			writeVariableByteInteger(ConnectPropertyId.ReceiveMaximum);
			writeUInt16(properties.receiveMaximum);
		}
		if (properties.topicAliasMaximum != null) {
			writeVariableByteInteger(ConnectPropertyId.TopicAliasMaximum);
			writeUInt16(properties.topicAliasMaximum);
		}
		if (properties.maximumPacketSize != null) {
			writeVariableByteInteger(ConnectPropertyId.MaximumPacketSize);
			writeInt32(properties.maximumPacketSize);
		}
		if (properties.userProperty != null) {
			var userProperty = properties.userProperty;
			for (f in Reflect.fields(userProperty)) {
				writeVariableByteInteger(ConnectPropertyId.UserProperty);
				writeString(f);
				writeString(Reflect.field(userProperty, f));
			}
		}
	}
}

class WillPropertiesWriter extends Writer {
	override function write(p:MqttPacket) {
		if (p.body.will.properties == null)
			return;
		var properties = p.body.will.properties;
		if (properties.payloadFormatIndicator != null) {
			writeVariableByteInteger(WillPropertyId.PayloadFormatIndicator);
			writeByte(properties.payloadFormatIndicator);
		}
		if (properties.messageExpiryInterval != null) {
			writeVariableByteInteger(WillPropertyId.MessageExpiryInterval);
			writeInt32(properties.messageExpiryInterval);
		}
		if (properties.contentType != null) {
			writeVariableByteInteger(WillPropertyId.ContentType);
			writeString(properties.contentType);
		}
		if (properties.responseTopic != null) {
			writeVariableByteInteger(WillPropertyId.ResponseTopic);
			writeString(properties.responseTopic);
		}
		if (properties.correlationData != null) {
			writeVariableByteInteger(WillPropertyId.CorrelationData);
			writeBinary(properties.correlationData);
		}
		if (properties.willDelayInterval != null) {
			writeVariableByteInteger(WillPropertyId.WillDelayInterval);
			writeInt32(properties.willDelayInterval);
		}
		if (properties.userProperty != null) {
			var userProperty = properties.userProperty;
			for (f in Reflect.fields(userProperty)) {
				writeVariableByteInteger(WillPropertyId.UserProperty);
				writeString(f);
				writeString(Reflect.field(userProperty, f));
			}
		}
	}
}

class ConnectWriter extends Writer {
	override public function write(p:MqttPacket) {
		if (p.body == null)
			return;
		this.p = p;
		var b:ConnectBody = cast p.body;
		var userNameFlag = b.username != null ? true : false;
		var passwordFlag = b.password != null ? true : false;
		var willFlag = b.will != null ? true : false;
		writeString(b.protocolName);
		writeByte(b.protocolVersion);
		bits.writeBit(userNameFlag);
		bits.writeBit(passwordFlag);
		bits.writeBit(willFlag ? b.will.retain : false);
		bits.writeBits(2, willFlag ? b.will.qos : 0);
		bits.writeBit(willFlag ? true : false);
		bits.writeBit(b.cleanStart);
		bits.writeBit(false);
		writeUInt16(b.keepalive);
		writeProperties(ConnectPropertiesWriter);
		writeString(b.clientId);
		if (willFlag)
			writeProperties(WillPropertiesWriter);
		if (willFlag)
			writeString(b.will.topic);
		if (willFlag)
			writeBinary(b.will.payload);
		if (userNameFlag)
			writeString(b.username);
		if (passwordFlag)
			writeBinary(b.password);
	}
}

class ConnackPropertiesWriter extends Writer {
	override function write(p:MqttPacket) {
		if (p.body.properties == null)
			return;
		var properties = p.body.properties;
		if (properties.sessionExpiryInterval != null) {
			writeVariableByteInteger(ConnackPropertyId.SessionExpiryInterval);
			writeInt32(properties.sessionExpiryInterval);
		}
		if (properties.assignedClientIdentifier != null) {
			writeVariableByteInteger(ConnackPropertyId.AssignedClientIdentifier);
			writeString(properties.assignedClientIdentifier);
		}
		if (properties.serverKeepAlive != null) {
			writeVariableByteInteger(ConnackPropertyId.ServerKeepAlive);
			writeUInt16(properties.serverKeepAlive);
		}
		if (properties.authenticationMethod != null) {
			writeVariableByteInteger(ConnackPropertyId.AuthenticationMethod);
			writeString(properties.authenticationMethod);
		}
		if (properties.authenticationData != null) {
			writeVariableByteInteger(ConnackPropertyId.AuthenticationData);
			writeBinary(properties.authenticationData);
		}
		if (properties.responseInformation != null) {
			writeVariableByteInteger(ConnackPropertyId.ResponseInformation);
			writeString(properties.responseInformation);
		}
		if (properties.serverReference != null) {
			writeVariableByteInteger(ConnackPropertyId.ServerReference);
			writeString(properties.serverReference);
		}
		if (properties.reasonString != null) {
			writeVariableByteInteger(ConnackPropertyId.ReasonString);
			writeString(properties.reasonString);
		}
		if (properties.receiveMaximum != null) {
			writeVariableByteInteger(ConnackPropertyId.ReceiveMaximum);
			writeUInt16(properties.receiveMaximum);
		}
		if (properties.topicAliasMaximum != null) {
			writeVariableByteInteger(ConnackPropertyId.TopicAliasMaximum);
			writeUInt16(properties.topicAliasMaximum);
		}
		if (properties.maximumQoS != null) {
			writeVariableByteInteger(ConnackPropertyId.MaximumQoS);
			writeByte(properties.maximumQoS);
		}
		if (properties.retainAvailable != null) {
			writeVariableByteInteger(ConnackPropertyId.RetainAvailable);
			writeByte(properties.retainAvailable);
		}
		if (properties.maximumPacketSize != null) {
			writeVariableByteInteger(ConnackPropertyId.MaximumPacketSize);
			writeInt32(properties.maximumPacketSize);
		}
		if (properties.wildcardSubscriptionAvailable != null) {
			writeVariableByteInteger(ConnackPropertyId.WildcardSubscriptionAvailable);
			writeByte(properties.wildcardSubscriptionAvailable);
		}
		if (properties.subscriptionIdentifierAvailable != null) {
			writeVariableByteInteger(ConnackPropertyId.SubscriptionIdentifierAvailable);
			writeByte(properties.subscriptionIdentifierAvailable);
		}
		if (properties.sharedSubscriptionAvailable != null) {
			writeVariableByteInteger(ConnackPropertyId.SharedSubscriptionAvailable);
			writeByte(properties.sharedSubscriptionAvailable);
		}
		if (properties.userProperty != null) {
			var userProperty = properties.userProperty;
			for (f in Reflect.fields(userProperty)) {
				writeVariableByteInteger(ConnackPropertyId.UserProperty);
				writeString(f);
				writeString(Reflect.field(userProperty, f));
			}
		}
	}
}

class ConnackWriter extends Writer {
	override public function write(p:MqttPacket) {
		if (p.body == null)
			return;
		this.p = p;
		var b:ConnackBody = cast p.body;
		bits.writeBits(7, 0);
		bits.writeBit(b.sessionPresent);
		writeByte(b.reasonCode);
		writeProperties(ConnackPropertiesWriter);
	}
}

class PublishPropertiesWriter extends Writer {
	override function write(p:MqttPacket) {
		if (p.body.properties == null)
			return;
		var properties:PublishProperties = cast p.body.properties;
		if (properties.payloadFormatIndicator != null) {
			writeVariableByteInteger(PublishPropertyId.PayloadFormatIndicator);
			writeByte(properties.payloadFormatIndicator);
		}
		if (properties.messageExpiryInterval != null) {
			writeVariableByteInteger(PublishPropertyId.MessageExpiryInterval);
			writeInt32(properties.messageExpiryInterval);
		}
		if (properties.contentType != null) {
			writeVariableByteInteger(PublishPropertyId.ContentType);
			writeString(properties.contentType);
		}
		if (properties.responseTopic != null) {
			writeVariableByteInteger(PublishPropertyId.ResponseTopic);
			writeString(properties.responseTopic);
		}
		if (properties.correlationData != null) {
			writeVariableByteInteger(PublishPropertyId.CorrelationData);
			writeBinary(properties.correlationData);
		}
		if (properties.topicAlias != null) {
			writeVariableByteInteger(PublishPropertyId.TopicAlias);
			writeUInt16(properties.topicAlias);
		}
		if (properties.subscriptionIdentifier != null) {
			for (i in properties.subscriptionIdentifier) {
				writeVariableByteInteger(PublishPropertyId.SubscriptionIdentifier);
				writeVariableByteInteger(i);
			}
		}
		if (properties.userProperty != null) {
			var userProperty = properties.userProperty;
			for (f in Reflect.fields(userProperty)) {
				writeVariableByteInteger(PublishPropertyId.UserProperty);
				writeString(f);
				writeString(Reflect.field(userProperty, f));
			}
		}
	}
}

class PublishWriter extends Writer {
	override public function write(p:MqttPacket) {
		if (p.body == null)
			return;
		this.p = p;
		var b:PublishBody = cast p.body;
		writeString(b.topic);
		writeUInt16(b.packetIdentifier);
		writeProperties(PublishPropertiesWriter);
		o.write(b.payload);
	}
}

class PubackPropertiesWriter extends Writer {
	override function write(p:MqttPacket) {
		if (p.body.properties == null)
			return;
		var properties = p.body.properties;
		if (properties.reasonString != null) {
			writeVariableByteInteger(PubackPropertyId.ReasonString);
			writeString(properties.reasonString);
		}
		if (properties.userProperty != null) {
			var userProperty = properties.userProperty;
			for (f in Reflect.fields(userProperty)) {
				writeVariableByteInteger(PubackPropertyId.UserProperty);
				writeString(f);
				writeString(Reflect.field(userProperty, f));
			}
		}
	}
}

class PubackWriter extends Writer {
	override public function write(p:MqttPacket) {
		if (p.body == null)
			return;
		this.p = p;
		var b:PubackBody = cast p.body;
		writeUInt16(b.packetIdentifier);
		writeByte(b.reasonCode);
		writeProperties(PubackPropertiesWriter);
	}
}

class PubrecPropertiesWriter extends Writer {
	override function write(p:MqttPacket) {
		if (p.body.properties == null)
			return;
		var properties = p.body.properties;
		if (properties.reasonString != null) {
			writeVariableByteInteger(PubrecPropertyId.ReasonString);
			writeString(properties.reasonString);
		}
		if (properties.userProperty != null) {
			var userProperty = properties.userProperty;
			for (f in Reflect.fields(userProperty)) {
				writeVariableByteInteger(PubrecPropertyId.UserProperty);
				writeString(f);
				writeString(Reflect.field(userProperty, f));
			}
		}
	}
}

class PubrecWriter extends Writer {
	override public function write(p:MqttPacket) {
		if (p.body == null)
			return;
		this.p = p;
		var b:PubrecBody = cast p.body;
		writeUInt16(b.packetIdentifier);
		writeByte(b.reasonCode);
		writeProperties(PubrecPropertiesWriter);
	}
}

class PubrelPropertiesWriter extends Writer {
	override function write(p:MqttPacket) {
		if (p.body.properties == null)
			return;
		var properties = p.body.properties;
		if (properties.reasonString != null) {
			writeVariableByteInteger(PubrelPropertyId.ReasonString);
			writeString(properties.reasonString);
		}
		if (properties.userProperty != null) {
			var userProperty = properties.userProperty;
			for (f in Reflect.fields(userProperty)) {
				writeVariableByteInteger(PubrelPropertyId.UserProperty);
				writeString(f);
				writeString(Reflect.field(userProperty, f));
			}
		}
	}
}

class PubrelWriter extends Writer {
	override public function write(p:MqttPacket) {
		if (p.body == null)
			return;
		this.p = p;
		var b:PubrelBody = cast p.body;
		writeUInt16(b.packetIdentifier);
		writeByte(b.reasonCode);
		writeProperties(PubrelPropertiesWriter);
	}
}

class PubcompPropertiesWriter extends Writer {
	override function write(p:MqttPacket) {
		if (p.body.properties == null)
			return;
		var properties = p.body.properties;
		if (properties.reasonString != null) {
			writeVariableByteInteger(PubcompPropertyId.ReasonString);
			writeString(properties.reasonString);
		}
		if (properties.userProperty != null) {
			var userProperty = properties.userProperty;
			for (f in Reflect.fields(userProperty)) {
				writeVariableByteInteger(PubcompPropertyId.UserProperty);
				writeString(f);
				writeString(Reflect.field(userProperty, f));
			}
		}
	}
}

class PubcompWriter extends Writer {
	override public function write(p:MqttPacket) {
		if (p.body == null)
			return;
		this.p = p;
		var b:PubcompBody = cast p.body;
		writeUInt16(b.packetIdentifier);
		writeByte(b.reasonCode);
		writeProperties(PubcompPropertiesWriter);
	}
}

class SubscribePropertiesWriter extends Writer {
	override function write(p:MqttPacket) {
		if (p.body.properties == null)
			return;
		var properties = p.body.properties;
		if (properties.subscriptionIdentifier != null) {
			writeVariableByteInteger(SubscribePropertyId.SubscriptionIdentifier);
			writeVariableByteInteger(properties.subscriptionIdentifier);
		}
		if (properties.userProperty != null) {
			var userProperty = properties.userProperty;
			for (f in Reflect.fields(userProperty)) {
				writeVariableByteInteger(SubscribePropertyId.UserProperty);
				writeString(f);
				writeString(Reflect.field(userProperty, f));
			}
		}
	}
}

class SubscribeWriter extends Writer {
	override public function write(p:MqttPacket) {
		if (p.body == null)
			return;
		this.p = p;
		var b:SubscribeBody = cast p.body;
		writeUInt16(b.packetIdentifier);
		writeProperties(SubscribePropertiesWriter);
		for (s in b.subscriptions) {
			writeString(s.topic);
			bits.writeBits(2, 0);
			bits.writeBits(2, s.rh);
			bits.writeBit(s.rap);
			bits.writeBit(s.nl);
			bits.writeBits(2, s.qos);
		}
	}
}

class SubackPropertiesWriter extends Writer {
	override function write(p:MqttPacket) {
		if (p.body.properties == null)
			return;
		var properties = p.body.properties;
		if (properties.reasonString != null) {
			writeVariableByteInteger(SubackPropertyId.ReasonString);
			writeString(properties.reasonString);
		}
		if (properties.userProperty != null) {
			writeVariableByteInteger(SubackPropertyId.UserProperty);
			var userProperty = properties.userProperty;
			for (f in Reflect.fields(userProperty)) {
				writeString(f);
				writeString(Reflect.field(userProperty, f));
			}
		}
	}
}

class SubackWriter extends Writer {
	override public function write(p:MqttPacket) {
		if (p.body == null)
			return;
		this.p = p;
		var b:SubackBody = cast p.body;
		writeUInt16(b.packetIdentifier);
		writeProperties(SubackPropertiesWriter);
		for (g in b.granted) {
			writeByte(g);
		}
	}
}

class UnsubscribePropertiesWriter extends Writer {
	override function write(p:MqttPacket) {
		if (p.body.properties == null)
			return;
		var properties = p.body.properties;
		if (properties.userProperty != null) {
			var userProperty = properties.userProperty;
			for (f in Reflect.fields(userProperty)) {
				writeVariableByteInteger(UnsubscribePropertyId.UserProperty);
				writeString(f);
				writeString(Reflect.field(userProperty, f));
			}
		}
	}
}

class UnsubscribeWriter extends Writer {
	override public function write(p:MqttPacket) {
		if (p.body == null)
			return;
		this.p = p;
		var b:UnsubscribeBody = cast p.body;
		writeUInt16(b.packetIdentifier);
		writeProperties(UnsubscribePropertiesWriter);
		for (g in b.unsubscriptions) {
			writeString(g);
		}
	}
}

class UnsubackPropertiesWriter extends Writer {
	override function write(p:MqttPacket) {
		if (p.body.properties == null)
			return;
		var properties = p.body.properties;
		if (properties.reasonString != null) {
			writeVariableByteInteger(UnsubackPropertyId.ReasonString);
			writeString(properties.reasonString);
		}
		if (properties.userProperty != null) {
			var userProperty = properties.userProperty;
			for (f in Reflect.fields(userProperty)) {
				writeVariableByteInteger(UnsubackPropertyId.UserProperty);
				writeString(f);
				writeString(Reflect.field(userProperty, f));
			}
		}
	}
}

class UnsubackWriter extends Writer {
	override public function write(p:MqttPacket) {
		if (p.body == null)
			return;
		this.p = p;
		var b:UnsubackBody = cast p.body;
		writeUInt16(b.packetIdentifier);
		writeProperties(UnsubackPropertiesWriter);
		for (g in b.granted) {
			writeByte(g);
		}
	}
}

class AuthPropertiesWriter extends Writer {
	override function write(p:MqttPacket) {
		if (p.body.properties == null)
			return;
		var properties = p.body.properties;
		if (properties.authenticationMethod != null) {
			writeVariableByteInteger(AuthPropertyId.AuthenticationMethod);
			writeString(properties.authenticationMethod);
		}
		if (properties.authenticationData != null) {
			writeVariableByteInteger(AuthPropertyId.AuthenticationData);
			writeBinary(properties.authenticationData);
		}
		if (properties.reasonString != null) {
			writeVariableByteInteger(AuthPropertyId.ReasonString);
			writeString(properties.reasonString);
		}
		if (properties.userProperty != null) {
			var userProperty = properties.userProperty;
			for (f in Reflect.fields(userProperty)) {
				writeVariableByteInteger(AuthPropertyId.UserProperty);
				writeString(f);
				writeString(Reflect.field(userProperty, f));
			}
		}
	}
}

class AuthWriter extends Writer {
	override public function write(p:MqttPacket) {
		if (p.body == null)
			return;
		this.p = p;
		var b:AuthBody = cast p.body;
		writeByte(b.reasonCode);
		writeProperties(AuthPropertiesWriter);
	}
}

class DisconnectPropertiesWriter extends Writer {
	override function write(p:MqttPacket) {
		if (p.body.properties == null)
			return;
		var properties:DisconnectProperties = cast p.body.properties;
		if (properties.sessionExpiryInterval != null) {
			writeVariableByteInteger(DisconnectPropertyId.SessionExpiryInterval);
			writeInt32(properties.sessionExpiryInterval);
		}
		if (properties.serverReference != null) {
			writeVariableByteInteger(DisconnectPropertyId.ServerReference);
			writeString(properties.serverReference);
		}
		if (properties.reasonString != null) {
			writeVariableByteInteger(DisconnectPropertyId.ReasonString);
			writeString(properties.reasonString);
		}
		if (properties.userProperty != null) {
			var userProperty = properties.userProperty;
			for (f in Reflect.fields(userProperty)) {
				writeVariableByteInteger(DisconnectPropertyId.UserProperty);
				writeString(f);
				writeString(Reflect.field(userProperty, f));
			}
		}
	}
}

class DisconnectWriter extends Writer {
	override public function write(p:MqttPacket) {
		if (p.body == null)
			return;
		this.p = p;
		var b:DisconnectBody = cast p.body;
		writeByte(b.reasonCode);
		writeProperties(DisconnectPropertiesWriter);
	}
}

class PingrespWriter extends Writer {
	override public function write(p:MqttPacket) {}
}

class PingreqWriter extends Writer {
	override public function write(p:MqttPacket) {}
}
