package mqtt;

import haxe.io.Bytes;
import mqtt.Constants;

typedef MqttPacket = {
	var pktType:CtrlPktType;
	var qos:QoS;
	var dup:Bool;
	var retain:Bool;

	@:optional var body:Dynamic;
}

typedef WillProperties = {
	@:optional var willDelayInterval:Int;
	@:optional var payloadFormatIndicator:Int;
	@:optional var messageExpiryInterval:Int;
	@:optional var contentType:String;
	@:optional var responseTopic:String;
	@:optional var correlationData:Bytes;
	@:optional var userProperty:Dynamic;
}

typedef Will = {
	var topic:String;
	var payload:Bytes;
	@:optional var qos:QoS;
	@:optional var retain:Bool;
	@:optional var properties:WillProperties;
}

typedef ConnectProperties = {
	@:optional var sessionExpiryInterval:Int;
	@:optional var receiveMaximum:Int;
	@:optional var maximumPacketSize:Int;
	@:optional var topicAliasMaximum:Int;
	@:optional var requestResponseInformation:Bool;
	@:optional var requestProblemInformation:Bool;
	@:optional var userProperty:Dynamic;
	@:optional var authenticationMethod:String;
	@:optional var authenticationData:Bytes;
}

typedef ConnectBody = {
	var clientId:String;
	@:optional var protocolVersion:ProtocolVersion;
	@:optional var protocolName:ProtocolName;
	@:optional var cleanStart:Bool;
	@:optional var keepalive:Int;
	@:optional var username:String;
	@:optional var password:Bytes;
	@:optional var will:Will;
	@:optional var properties:ConnectProperties;
}

typedef PublishProperties = {
	@:optional var payloadFormatIndicator:Int;
	@:optional var messageExpiryInterval:Int;
	@:optional var topicAlias:Int;
	@:optional var responseTopic:String;
	@:optional var correlationData:Bytes;
	@:optional var userProperty:Dynamic;
	@:optional var subscriptionIdentifier:Array<Int>;
	@:optional var contentType:String;
}

typedef PublishBody = {
	var topic:String;
	@:optional var packetIdentifier:Int;
	var payload:Bytes;
	@:optional var properties:PublishProperties;
}

typedef ConnackProperties = {
	@:optional var sessionExpiryInterval:Int;
	@:optional var receiveMaximum:Int;
	@:optional var maximumQoS:Int;
	@:optional var retainAvailable:Bool;
	@:optional var maximumPacketSize:Int;
	@:optional var assignedClientIdentifier:String;
	@:optional var topicAliasMaximum:Int;
	@:optional var reasonString:String;
	@:optional var userProperty:Dynamic;
	@:optional var wildcardSubscriptionAvailable:Bool;
	@:optional var subscriptionIdentifiersAvailable:Bool;
	@:optional var sharedSubscriptionAvailable:Bool;
	@:optional var serverKeepAlive:Int;
	@:optional var responseInformation:String;
	@:optional var serverReference:String;
	@:optional var authenticationMethod:String;
	@:optional var authenticationData:Bytes;
}

typedef ConnackBody = {
	var reasonCode:ConnackReasonCode;
	var sessionPresent:Bool;
	@:optional var properties:ConnackProperties;
}

typedef Subscription = {
	var topic:String;
	var qos:QoS;
	@:optional var nl:Bool;
	@:optional var rap:Bool;
	@:optional var rh:Int;
}

typedef SubscribeProperties = {
	@:optional var subscriptionIdentifier:Int;
	@:optional var userProperty:Dynamic;
}

typedef SubscribeBody = {
	var packetIdentifier:Int;
	var subscriptions:Array<Subscription>;
	@:optional var properties:SubscribeProperties;
}

typedef SubackProperties = SubscribeProperties;

typedef SubackBody = {
	var packetIdentifier:Int;
	@:optional var properties:SubackProperties;
	var granted:Array<Int>;
}

typedef UnsubscribeProperties = SubscribeProperties;

typedef UnsubscribeBody = {
	var packetIdentifier:Int;
	@:optional var properties:UnsubscribeProperties;
	@:optional var unsubscriptions:Array<String>;
}

typedef UnsubackProperties = SubscribeProperties;

typedef UnsubackBody = {
	var packetIdentifier:Int;
	@:optional var properties:UnsubackProperties;
	var granted:Array<Int>;
}

typedef PubackProperties = SubscribeProperties;

typedef PubackBody = {
	var packetIdentifier:Int;
	var reasonCode:PubackReasonCode;
	@:optional var properties:PubackProperties;
}

typedef PubcompProperties = SubscribeProperties;

typedef PubcompBody = {
	@:optional var properties:PubcompProperties;
}

typedef PubrelProperties = SubscribeProperties;

typedef PubrelBody = {
	@:optional var properties:PubrelProperties;
}

typedef PubrecProperties = SubscribeProperties;

typedef PubrecBody = {
	@:optional var properties:PubrecProperties;
}

typedef DisconnectProperties = {
	@:optional var sessionExpiryInterval:Int;
	@:optional var reasonString:String;
	@:optional var userProperty:Dynamic;
	@:optional var serverReference:String;
}

typedef DisconnectBody = {
	@:optional var reasonCode:DisconnectReasonCode;
	@:optional var properties:DisconnectProperties;
}

typedef AuthProperties = {
	@:optional var authenticationMethod:String;
	@:optional var authenticationData:Bytes;
	@:optional var userProperty:Dynamic;
	@:optional var reasonString:String;
}

typedef AuthBody = {
	@:optional var reasonCode:AuthReasonCode;
	@:optional var properties:AuthProperties;
}

class MqttReaderException extends haxe.Exception {}
class MqttWriterException extends haxe.Exception {}
