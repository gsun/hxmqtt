package mqtt;

import haxe.io.BytesBuffer;

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
	@:optional var correlationData:BytesBuffer;
	@:optional var userProperties:Dynamic;
}

typedef Will = {
	var topic:String;
	var payload:BytesBuffer;
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
	@:optional var userProperties:Dynamic;
	@:optional var authenticationMethod:String;
	@:optional var authenticationData:BytesBuffer;
}

typedef ConnectBody = {
	var clientId:String;
	@:optional var protocolVersion:ProtocolVersion;
	@:optional var protocolName:ProtocolName;
	@:optional var cleanStart:Bool;
	@:optional var keepalive:Int;
	@:optional var username:String;
	@:optional var password:BytesBuffer;
	@:optional var will:Will;
	@:optional var properties:ConnectProperties;
}

typedef PublishProperties = {
	@:optional var payloadFormatIndicator:Bool;
	@:optional var messageExpiryInterval:Int;
	@:optional var topicAlias:Int;
	@:optional var responseTopic:String;
	@:optional var correlationData:BytesBuffer;
	@:optional var userProperties:Dynamic;
	@:optional var subscriptionIdentifier:Int;
	@:optional var contentType:String;
}

typedef PublishBody = {
	var topic:String;
	var payload:BytesBuffer;
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
	@:optional var userProperties:Dynamic;
	@:optional var wildcardSubscriptionAvailable:Bool;
	@:optional var subscriptionIdentifiersAvailable:Bool;
	@:optional var sharedSubscriptionAvailable:Bool;
	@:optional var serverKeepAlive:Int;
	@:optional var responseInformation:String;
	@:optional var serverReference:String;
	@:optional var authenticationMethod:String;
	@:optional var authenticationData:BytesBuffer;
}

typedef ConnackBody = {
	var returnCode:Int;
	var sessionPresent:Bool;
	@:optional var properties:ConnackProperties;
}

typedef SubscriptionBody = {
	var topic:String var qos:QoS;
	@:optional var nl:Bool;
	@:optional var rap:Bool;
	@:optional var rh:Int;
}

typedef SubscribeProperties = {
	@:optional var reasonString:String;
	@:optional var userProperties:Dynamic;
}

typedef SubscribeBody = {
	var subscriptions:Array<Subscription>;
	@:optional var properties:SubscribeProperties;
}

typedef SubackProperties = SubscribeProperties;

typedef Suback = {
	@:optional var properties:SubackProperties;
	var granted:Array<Int>;
}

typedef UnsubscribeProperties = SubscribeProperties;

typedef UnsubscribeBody = {
	@:optional var properties:UnsubscribeProperties;
	@:optional var unsubscriptions:Array<String>
}

typedef UnsubackProperties = SubscribeProperties;

typedef UnsubackBody = {
	@:optional var properties:UnsubackProperties;
}

typedef PubackProperties = SubscribeProperties;

typedef PubackBody = {
	@:optional var properties:PubackProperties;
}

typedef PubcompProperties = SubscribeProperties;

typedef PubcompBody = {
	@:optional var properties:PubcompProperties
}

typedef PubrelProperties = SubscribeProperties;

typedef PubrelBody = {
	@:optional var properties:PubrelProperties;
}

typedef PubrecProperties = SubscribeProperties;

typedef PubrecBody = {
	@:optional var properties:PubrecProperties
}

typedef DisconnectProperties = {
	@:optional var sessionExpiryInterval:Int;
	@:optional var reasonString:String;
	@:optional var userProperties:Dynamic;
	@:optional var serverReference:String;
}

typedef DisconnectBody = {
	@:optional var properties:DisconnectProperties;
}
