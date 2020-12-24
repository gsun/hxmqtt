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
		try {
			if (p.body.properties != null) {
				var properties = p.body.properties;
				if (Reflect.hasField(properties, "sessionExpiryInterval")) {
					writeVariableByteInteger(ConnectPropertyId.SessionExpiryInterval);
					writeInt32(properties.sessionExpiryInterval);
				}
				if (Reflect.hasField(properties, "authenticationMethod")) {
					writeVariableByteInteger(ConnectPropertyId.AuthenticationMethod);
					writeString(properties.authenticationMethod);
				}
				if (Reflect.hasField(properties, "authenticationData")) {
					writeVariableByteInteger(ConnectPropertyId.AuthenticationData);
					writeBinary(properties.authenticationData);
				}
				if (Reflect.hasField(properties, "requestProblemInformation")) {
					writeVariableByteInteger(ConnectPropertyId.RequestProblemInformation);
					writeByte(properties.requestProblemInformation);
				}
				if (Reflect.hasField(properties, "requestResponseInformation")) {
					writeVariableByteInteger(ConnectPropertyId.RequestResponseInformation);
					writeByte(properties.requestResponseInformation);
				}
				if (Reflect.hasField(properties, "receiveMaximum")) {
					writeVariableByteInteger(ConnectPropertyId.ReceiveMaximum);
					writeUInt16(properties.receiveMaximum);
				}
				if (Reflect.hasField(properties, "topicAliasMaximum")) {
					writeVariableByteInteger(ConnectPropertyId.TopicAliasMaximum);
					writeUInt16(properties.topicAliasMaximum);
				}
				if (Reflect.hasField(properties, "maximumPacketSize")) {
					writeVariableByteInteger(ConnectPropertyId.MaximumPacketSize);
					writeInt32(properties.maximumPacketSize);
				}
				if (Reflect.hasField(properties, "userProperty")) {
					var userProperty = properties.userProperty;
					for (f in Reflect.fields(userProperty)) {
						writeVariableByteInteger(ConnectPropertyId.UserProperty);
						writeString(f);
						writeString(Reflect.field(userProperty, f));
					}
				}
			}
		} catch (e) {
			trace(e);
		}
	}
}

class WillPropertiesWriter extends Writer {
	override function write(p:MqttPacket) {
		try {
			if (p.body.will.properties != null) {
				var properties = p.body.will.properties;
				if (Reflect.hasField(properties, "payloadFormatIndicator")) {
					writeVariableByteInteger(WillPropertyId.PayloadFormatIndicator);
					writeByte(properties.payloadFormatIndicator);
				}
				if (Reflect.hasField(properties, "messageExpiryInterval")) {
					writeVariableByteInteger(WillPropertyId.MessageExpiryInterval);
					writeInt32(properties.messageExpiryInterval);
				}
				if (Reflect.hasField(properties, "contentType")) {
					writeVariableByteInteger(WillPropertyId.ContentType);
					writeString(properties.contentType);
				}
				if (Reflect.hasField(properties, "responseTopic")) {
					writeVariableByteInteger(WillPropertyId.ResponseTopic);
					writeString(properties.responseTopic);
				}
				if (Reflect.hasField(properties, "correlationData")) {
					writeVariableByteInteger(WillPropertyId.CorrelationData);
					writeBinary(properties.correlationData);
				}
				if (Reflect.hasField(properties, "willDelayInterval")) {
					writeVariableByteInteger(WillPropertyId.WillDelayInterval);
					writeInt32(properties.willDelayInterval);
				}
				if (Reflect.hasField(properties, "userProperty")) {
					var userProperty = properties.userProperty;
					for (f in Reflect.fields(userProperty)) {
						writeVariableByteInteger(WillPropertyId.UserProperty);
						writeString(f);
						writeString(Reflect.field(userProperty, f));
					}
				}
			}
		} catch (e) {
			trace(e);
		}
	}
}

class ConnectWriter extends Writer {
	override public function write(p:MqttPacket) {
		this.p = p;
		var b:ConnectBody = cast p.body;
		var userNameFlag = Reflect.hasField(b, "username");
		var passwordFlag = Reflect.hasField(b, "password");
		var willFlag = Reflect.hasField(b, "will");
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
		try {
			if (p.body.properties != null) {
				var properties = p.body.properties;
				if (Reflect.hasField(properties, "sessionExpiryInterval")) {
					writeVariableByteInteger(ConnackPropertyId.SessionExpiryInterval);
					writeInt32(properties.sessionExpiryInterval);
				}
				if (Reflect.hasField(properties, "assignedClientIdentifier")) {
					writeVariableByteInteger(ConnackPropertyId.AssignedClientIdentifier);
					writeString(properties.assignedClientIdentifier);
				}
				if (Reflect.hasField(properties, "serverKeepAlive")) {
					writeVariableByteInteger(ConnackPropertyId.ServerKeepAlive);
					writeUInt16(properties.serverKeepAlive);
				}
				if (Reflect.hasField(properties, "authenticationMethod")) {
					writeVariableByteInteger(ConnackPropertyId.AuthenticationMethod);
					writeString(properties.authenticationMethod);
				}
				if (Reflect.hasField(properties, "authenticationData")) {
					writeVariableByteInteger(ConnackPropertyId.AuthenticationData);
					writeBinary(properties.authenticationData);
				}
				if (Reflect.hasField(properties, "responseInformation")) {
					writeVariableByteInteger(ConnackPropertyId.ResponseInformation);
					writeString(properties.responseInformation);
				}
				if (Reflect.hasField(properties, "serverReference")) {
					writeVariableByteInteger(ConnackPropertyId.ServerReference);
					writeString(properties.serverReference);
				}
				if (Reflect.hasField(properties, "reasonString")) {
					writeVariableByteInteger(ConnackPropertyId.ReasonString);
					writeString(properties.reasonString);
				}
				if (Reflect.hasField(properties, "receiveMaximum")) {
					writeVariableByteInteger(ConnackPropertyId.ReceiveMaximum);
					writeUInt16(properties.receiveMaximum);
				}
				if (Reflect.hasField(properties, "topicAliasMaximum")) {
					writeVariableByteInteger(ConnackPropertyId.TopicAliasMaximum);
					writeUInt16(properties.topicAliasMaximum);
				}
				if (Reflect.hasField(properties, "maximumQoS")) {
					writeVariableByteInteger(ConnackPropertyId.MaximumQoS);
					writeByte(properties.maximumQoS);
				}
				if (Reflect.hasField(properties, "retainAvailable")) {
					writeVariableByteInteger(ConnackPropertyId.RetainAvailable);
					writeByte(properties.retainAvailable);
				}
				if (Reflect.hasField(properties, "maximumPacketSize")) {
					writeVariableByteInteger(ConnackPropertyId.MaximumPacketSize);
					writeInt32(properties.maximumPacketSize);
				}
				if (Reflect.hasField(properties, "wildcardSubscriptionAvailable")) {
					writeVariableByteInteger(ConnackPropertyId.WildcardSubscriptionAvailable);
					writeByte(properties.wildcardSubscriptionAvailable);
				}
				if (Reflect.hasField(properties, "subscriptionIdentifierAvailable")) {
					writeVariableByteInteger(ConnackPropertyId.SubscriptionIdentifierAvailable);
					writeByte(properties.subscriptionIdentifierAvailable);
				}
				if (Reflect.hasField(properties, "sharedSubscriptionAvailable")) {
					writeVariableByteInteger(ConnackPropertyId.SharedSubscriptionAvailable);
					writeByte(properties.sharedSubscriptionAvailable);
				}
				if (Reflect.hasField(properties, "userProperty")) {
					var userProperty = properties.userProperty;
					for (f in Reflect.fields(userProperty)) {
						writeVariableByteInteger(ConnackPropertyId.UserProperty);
						writeString(f);
						writeString(Reflect.field(userProperty, f));
					}
				}
			}
		} catch (e) {
			trace(e);
		}
	}
}

class ConnackWriter extends Writer {
	override public function write(p:MqttPacket) {
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
		try {
			if (p.body.properties != null) {
				var properties:PublishProperties = cast p.body.properties;
				if (Reflect.hasField(properties, "payloadFormatIndicator")) {
					writeVariableByteInteger(PublishPropertyId.PayloadFormatIndicator);
					writeByte(properties.payloadFormatIndicator);
				}
				if (Reflect.hasField(properties, "messageExpiryInterval")) {
					writeVariableByteInteger(PublishPropertyId.MessageExpiryInterval);
					writeInt32(properties.messageExpiryInterval);
				}
				if (Reflect.hasField(properties, "contentType")) {
					writeVariableByteInteger(PublishPropertyId.ContentType);
					writeString(properties.contentType);
				}
				if (Reflect.hasField(properties, "responseTopic")) {
					writeVariableByteInteger(PublishPropertyId.ResponseTopic);
					writeString(properties.responseTopic);
				}
				if (Reflect.hasField(properties, "correlationData")) {
					writeVariableByteInteger(PublishPropertyId.CorrelationData);
					writeBinary(properties.correlationData);
				}
				if (Reflect.hasField(properties, "topicAlias")) {
					writeVariableByteInteger(PublishPropertyId.TopicAlias);
					writeUInt16(properties.topicAlias);
				}
				if (Reflect.hasField(properties, "subscriptionIdentifier")) {
					for (i in properties.subscriptionIdentifier) {
						writeVariableByteInteger(PublishPropertyId.SubscriptionIdentifier);
						writeVariableByteInteger(i);
					}
				}
				if (Reflect.hasField(properties, "userProperty")) {
					var userProperty = properties.userProperty;
					for (f in Reflect.fields(userProperty)) {
						writeVariableByteInteger(PublishPropertyId.UserProperty);
						writeString(f);
						writeString(Reflect.field(userProperty, f));
					}
				}
			}
		} catch (e) {
			trace(e);
		}
	}
}

class PublishWriter extends Writer {
	override public function write(p:MqttPacket) {
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
		try {
			if (p.body.properties != null) {
				var properties = p.body.properties;
				if (Reflect.hasField(properties, "reasonString")) {
					writeVariableByteInteger(PubackPropertyId.ReasonString);
					writeString(properties.reasonString);
				}
				if (Reflect.hasField(properties, "userProperty")) {
					var userProperty = properties.userProperty;
					for (f in Reflect.fields(userProperty)) {
						writeVariableByteInteger(PubackPropertyId.UserProperty);
						writeString(f);
						writeString(Reflect.field(userProperty, f));
					}
				}
			}
		} catch (e) {
			trace(e);
		}
	}
}

class PubackWriter extends Writer {
	override public function write(p:MqttPacket) {
		this.p = p;
		var b:PubackBody = cast p.body;
		writeUInt16(b.packetIdentifier);
		writeByte(b.reasonCode);
		writeProperties(PubackPropertiesWriter);
	}
}

class PubrecPropertiesWriter extends Writer {
	override function write(p:MqttPacket) {
		try {
			if (p.body.properties != null) {
				var properties = p.body.properties;
				if (Reflect.hasField(properties, "reasonString")) {
					writeVariableByteInteger(PubrecPropertyId.ReasonString);
					writeString(properties.reasonString);
				}
				if (Reflect.hasField(properties, "userProperty")) {
					var userProperty = properties.userProperty;
					for (f in Reflect.fields(userProperty)) {
						writeVariableByteInteger(PubrecPropertyId.UserProperty);
						writeString(f);
						writeString(Reflect.field(userProperty, f));
					}
				}
			}
		} catch (e) {
			trace(e);
		}
	}
}

class PubrecWriter extends Writer {
	override public function write(p:MqttPacket) {
		this.p = p;
		var b:PubrecBody = cast p.body;
		writeUInt16(b.packetIdentifier);
		writeByte(b.reasonCode);
		writeProperties(PubrecPropertiesWriter);
	}
}

class PubrelPropertiesWriter extends Writer {
	override function write(p:MqttPacket) {
		try {
			if (p.body.properties != null) {
				var properties = p.body.properties;
				if (Reflect.hasField(properties, "reasonString")) {
					writeVariableByteInteger(PubrelPropertyId.ReasonString);
					writeString(properties.reasonString);
				}
				if (Reflect.hasField(properties, "userProperty")) {
					var userProperty = properties.userProperty;
					for (f in Reflect.fields(userProperty)) {
						writeVariableByteInteger(PubrelPropertyId.UserProperty);
						writeString(f);
						writeString(Reflect.field(userProperty, f));
					}
				}
			}
		} catch (e) {
			trace(e);
		}
	}
}

class PubrelWriter extends Writer {
	override public function write(p:MqttPacket) {
		this.p = p;
		var b:PubrelBody = cast p.body;
		writeUInt16(b.packetIdentifier);
		writeByte(b.reasonCode);
		writeProperties(PubrelPropertiesWriter);
	}
}

class PubcompPropertiesWriter extends Writer {
	override function write(p:MqttPacket) {
		try {
			if (p.body.properties != null) {
				var properties = p.body.properties;
				if (Reflect.hasField(properties, "reasonString")) {
					writeVariableByteInteger(PubcompPropertyId.ReasonString);
					writeString(properties.reasonString);
				}
				if (Reflect.hasField(properties, "userProperty")) {
					var userProperty = properties.userProperty;
					for (f in Reflect.fields(userProperty)) {
						writeVariableByteInteger(PubcompPropertyId.UserProperty);
						writeString(f);
						writeString(Reflect.field(userProperty, f));
					}
				}
			}
		} catch (e) {
			trace(e);
		}
	}
}

class PubcompWriter extends Writer {
	override public function write(p:MqttPacket) {
		this.p = p;
		var b:PubcompBody = cast p.body;
		writeUInt16(b.packetIdentifier);
		writeByte(b.reasonCode);
		writeProperties(PubcompPropertiesWriter);
	}
}

class SubscribePropertiesWriter extends Writer {
	override function write(p:MqttPacket) {
		try {
			if (p.body.properties != null) {
				var properties = p.body.properties;
				if (Reflect.hasField(properties, "subscriptionIdentifier")) {
					writeVariableByteInteger(SubscribePropertyId.SubscriptionIdentifier);
					writeVariableByteInteger(properties.subscriptionIdentifier);
				}
				if (Reflect.hasField(properties, "userProperty")) {
					var userProperty = properties.userProperty;
					for (f in Reflect.fields(userProperty)) {
						writeVariableByteInteger(SubscribePropertyId.UserProperty);
						writeString(f);
						writeString(Reflect.field(userProperty, f));
					}
				}
			}
		} catch (e) {
			trace(e);
		}
	}
}

class SubscribeWriter extends Writer {
	override public function write(p:MqttPacket) {
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
		try {
			if (p.body.properties != null) {
				var properties = p.body.properties;
				if (Reflect.hasField(properties, "reasonString")) {
					writeVariableByteInteger(SubackPropertyId.ReasonString);
					writeString(properties.reasonString);
				}
				if (Reflect.hasField(properties, "userProperty")) {
					writeVariableByteInteger(SubackPropertyId.UserProperty);
					var userProperty = properties.userProperty;
					for (f in Reflect.fields(userProperty)) {
						writeString(f);
						writeString(Reflect.field(userProperty, f));
					}
				}
			}
		} catch (e) {
			trace(e);
		}
	}
}

class SubackWriter extends Writer {
	override public function write(p:MqttPacket) {
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
		try {
			if (p.body.properties != null) {
				var properties = p.body.properties;
				if (Reflect.hasField(properties, "userProperty")) {
					var userProperty = properties.userProperty;
					for (f in Reflect.fields(userProperty)) {
						writeVariableByteInteger(UnsubscribePropertyId.UserProperty);
						writeString(f);
						writeString(Reflect.field(userProperty, f));
					}
				}
			}
		} catch (e) {
			trace(e);
		}
	}
}

class UnsubscribeWriter extends Writer {
	override public function write(p:MqttPacket) {
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
		try {
			if (p.body.properties != null) {
				var properties = p.body.properties;
				if (Reflect.hasField(properties, "reasonString")) {
					writeVariableByteInteger(UnsubackPropertyId.ReasonString);
					writeString(properties.reasonString);
				}
				if (Reflect.hasField(properties, "userProperty")) {
					var userProperty = properties.userProperty;
					for (f in Reflect.fields(userProperty)) {
						writeVariableByteInteger(UnsubackPropertyId.UserProperty);
						writeString(f);
						writeString(Reflect.field(userProperty, f));
					}
				}
			}
		} catch (e) {
			trace(e);
		}
	}
}

class UnsubackWriter extends Writer {
	override public function write(p:MqttPacket) {
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
		try {
			if (p.body.properties != null) {
				var properties = p.body.properties;
				if (Reflect.hasField(properties, "authenticationMethod")) {
					writeVariableByteInteger(AuthPropertyId.AuthenticationMethod);
					writeString(properties.authenticationMethod);
				}
				if (Reflect.hasField(properties, "authenticationData")) {
					writeVariableByteInteger(AuthPropertyId.AuthenticationData);
					writeBinary(properties.authenticationData);
				}
				if (Reflect.hasField(properties, "reasonString")) {
					writeVariableByteInteger(AuthPropertyId.ReasonString);
					writeString(properties.reasonString);
				}
				if (Reflect.hasField(properties, "userProperty")) {
					var userProperty = properties.userProperty;
					for (f in Reflect.fields(userProperty)) {
						writeVariableByteInteger(AuthPropertyId.UserProperty);
						writeString(f);
						writeString(Reflect.field(userProperty, f));
					}
				}
			}
		} catch (e) {
			trace(e);
		}
	}
}

class AuthWriter extends Writer {
	override public function write(p:MqttPacket) {
		this.p = p;
		var b:AuthBody = cast p.body;
		writeByte(b.reasonCode);
		writeProperties(AuthPropertiesWriter);
	}
}

class DisconnectPropertiesWriter extends Writer {
	override function write(p:MqttPacket) {
		try {
			if (p.body.properties != null) {
				var properties:DisconnectProperties = cast p.body.properties;
				if (Reflect.hasField(properties, "sessionExpiryInterval")) {
					writeVariableByteInteger(DisconnectPropertyId.SessionExpiryInterval);
					writeInt32(properties.sessionExpiryInterval);
				}
				if (Reflect.hasField(properties, "serverReference")) {
					writeVariableByteInteger(DisconnectPropertyId.ServerReference);
					writeString(properties.serverReference);
				}
				if (Reflect.hasField(properties, "reasonString")) {
					writeVariableByteInteger(DisconnectPropertyId.ReasonString);
					writeString(properties.reasonString);
				}
				if (Reflect.hasField(properties, "userProperty")) {
					var userProperty = properties.userProperty;
					for (f in Reflect.fields(userProperty)) {
						writeVariableByteInteger(DisconnectPropertyId.UserProperty);
						writeString(f);
						writeString(Reflect.field(userProperty, f));
					}
				}
			}
		} catch (e) {
			trace(e);
		}
	}
}

class DisconnectWriter extends Writer {
	override public function write(p:MqttPacket) {
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
