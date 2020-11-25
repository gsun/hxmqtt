package mqtt;

import haxe.io.BytesBuffer;

typedef MqttPacket = {
	var ptype:CtrlPacketType;
	var qos:QoS;
	var dup:Bool;
	var retain:Bool;
	@:optional var messageId:Int;
	@:optional var length:Int;

	@:optional var connect:Connect;
	@:optional var publish:Publish;
	@:optional var connack:Connack;
	@:optional var subscribe:Subscribe;
	@:optional var suback:Suback;
	@:optional var unsubscribe:Unsubscribe;
	@:optional var unsuback:Unsuback;
	@:optional var puback:Puback;
	@:optional var pubcomp:Pubcomp;
	@:optional var pubrec:Pubrec;
	@:optional var pubrel:Pubrel;
	@:optional var disconnect:Disconnect;
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

typedef Connect = {
	var clientId:String;
	@:optional var protocolVersion:ProtocolVersion;
	@:optional var protocolName:ProtocolName;
	@:optional var clean:Bool;
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

typedef Publish = {
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

typedef Connack = {
	var returnCode:Int;
	var sessionPresent:Bool;
	@:optional var properties:ConnackProperties;
}

typedef Subscription = {
	var topic:String var qos:QoS;
	@:optional var nl:Bool;
	@:optional var rap:Bool;
	@:optional var rh:Int;
}

typedef SubscribeProperties = {
	@:optional var reasonString:String;
	@:optional var userProperties:Dynamic;
}

typedef Subscribe = {
	var subscriptions:Array<Subscription>;
	@:optional var properties:SubscribeProperties;
}

typedef SubackProperties = SubscribeProperties;

typedef Suback = {
	@:optional var properties:SubackProperties;
	var granted:Array<Int>;
}

typedef UnsubscribeProperties = SubscribeProperties;

typedef Unsubscribe = {
	@:optional var properties:UnsubscribeProperties;
	@:optional var unsubscriptions:Array<String>
}

typedef UnsubackProperties = SubscribeProperties;

typedef Unsuback = {
	@:optional var properties:UnsubackProperties;
}

typedef PubackProperties = SubscribeProperties;

typedef Puback = {
	@:optional var properties:PubackProperties;
}

typedef PubcompProperties = SubscribeProperties;

typedef Pubcomp = {
	@:optional var properties:PubcompProperties
}

typedef PubrelProperties = SubscribeProperties;

typedef Pubrel = {
	@:optional var properties:PubrelProperties;
}

typedef PubrecProperties = SubscribeProperties;

typedef Pubrec = {
	@:optional var properties:PubrecProperties
}

typedef DisconnectProperties = {
	@:optional var sessionExpiryInterval:Int;
	@:optional var reasonString:String;
	@:optional var userProperties:Dynamic;
	@:optional var serverReference:String;
}

typedef Disconnect = {
	@:optional var properties:DisconnectProperties;
}
