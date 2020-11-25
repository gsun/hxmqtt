package mqtt;

@:enum
abstract CtrlPacketType(Int) to Int {
	var Reserved = 0;
	var Connect = 1;
	var Connack = 2;
	var Publish = 3;
	var Puback = 4;
	var Pubrec = 5;
	var Pubrel = 6;
	var Pubcomp = 7;
	var Subscribe = 8;
	var Suback = 9;
	var Unsubscribe = 10;
	var Unsuback = 11;
	var Pingreq = 12;
	var Pingresp = 13;
	var Disconnect = 14;
	var Auth = 15;
}

@:enum
abstract QoS(Int) to Int {
	var AtMostOnce = 0;
	var AtLeastOnce = 1;
	var ExactlyOnce = 2;
}

@:enum
abstract ProtocolVersion(Int) to Int {
	var V3 = 3;
	var V4 = 4;
	var V5 = 5;
}

@:enum
abstract ProtocolName(String) to String {
	var Mqtt = 'MQTT';
}

@:enum
abstract ProtocolProperty(Int) to Int = {
	var payloadFormatIndicator = 1;
	var messageExpiryInterval = 2;
	var contentType = 3;
	var responseTopic = 8;
	var correlationData = 9;
	var subscriptionIdentifier = 11;
	var sessionExpiryInterval = 17;
	var assignedClientIdentifier = 18;
	var serverKeepAlive = 19;
	var authenticationMethod = 21;
	var authenticationData = 22;
	var requestProblemInformation = 23;
	var willDelayInterval = 24;
	var requestResponseInformation = 25;
	var responseInformation = 26;
	var serverReference = 28;
	var reasonString = 31;
	var receiveMaximum = 33;
	var topicAliasMaximum = 34;
	var topicAlias = 35;
	var maximumQoS = 36;
	var retainAvailable = 37;
	var userProperties = 38;
	var maximumPacketSize = 39;
	var wildcardSubscriptionAvailable = 40;
	var subscriptionIdentifiersAvailable = 41;
	var sharedSubscriptionAvailable = 42;
}

@:enum
abstract ConnackReason(Int) to Int = {
	var Success = 0;
	var UnspecifiedError = 128;
	var MalformedPacket = 129;
	var ProtocolError = 130;
	var ImplementationSpecificError = 131;
	var UnsupportedProtocolVersion = 132;
	var ClientIIdentifierInValid = 133;
	var BadUserNameorPassword = 134;
	var NotAuthorized = 135;
	var ServerUnavailable = 136;
	var ServerBusy = 137;
	var Banned = 138;
	var BadAuthenticationMethod = 140;
	var TopicNameInvalid = 144;
	var PacketTooLarge = 149;
	var QuotaExceeded = 151;
	var PayloadFormatInvalid = 153;
	var RetainNotSupported = 154;
	var QoSNotSupported = 155;
	var UseAnotherServer = 156;
	var ServerMoved = 157;
	var ConnectionRateExceeded = 159;
}

@:enum
abstract PubackReason(Int) to Int = {
	var Success = 0;
	var NoMatchingSubscribers = 16;
	var UnspecifiedError = 128;
	var ImplementationSpecificError = 131;
	var NotAuthorized = 135;
	var TopicNameInvalid = 144;
	var PacketIdentifierInUse = 145;
	var QuotaExceeded = 151;
	var PayloadFormatInvalid = 153;
}

@:enum
abstract PubrecReason(Int) to Int = {
	var Success = 0;
	var NoMatchingSubscribers = 16;
	var UnspecifiedError = 128;
	var ImplementationSpecificError = 131;
	var NotAuthorized = 135;
	var TopicNameInvalid = 144;
	var PacketIdentifierInUse = 145;
	var QuotaExceeded = 151;
	var PayloadFormatInvalid = 153;
}

@:enum
abstract PubrelReason(Int) to Int = {
	var Success = 0;
	var PacketIdentifierNotFound = 146;
}

@:enum
abstract PubcompReason(Int) to Int = {
	var Success = 0;
	var PacketIdentifierNotFound = 146;
}

@:enum
abstract UnsubackReason(Int) to Int = {
	var Success = 0;
	var NoSubscriptionExisted = 17;
	var UnspecifiedError = 128;
	var ImplementationSpecificError = 131;
	var NotAuthorized = 135;
	var TopicFilterInvalid = 143;
	var PacketIdentifierInUse = 145;
}

@:enum
abstract AuthReason(Int) to Int = {
	var Success = 0;
	var ContinueAuthentication = 24;
	var Reauthenticate = 25;
	var NotAuthorized = 135;
	var BadAuthenticationMethod = 140;
}

@:enum
abstract DisconnectReason(Int) to Int = {
	var NormalDisconnection = 0;
	var DisconnectWithWill = 4;
	var UnspecifiedError = 128;
	var MalformedPacket = 129;
	var ProtocolError = 130;
	var ImplementationSpecificError = 131;
	var NotAuthorized = 135;
	var ServerBusy = 137;
	var ServerShuttingDown = 139;
	var BadAuthenticationMethod = 140;
	var KeepAliveTimeout = 141;
	var SessionTakenOver = 142;
	var TopicFilterInvalid = 143;
	var TopicNameInvalid = 144;
	var ReceiveMaximumExceeded = 147;
	var TopicAliasInvalid = 148;
	var PacketTooLarge = 149;
	var MessageRateTooHigh = 150;
	var QuotaExceeded = 151;
	var AdministrativeAction = 152;
	var PayloadFormatInvalid = 153;
	var RetainNotSupported = 154;
	var QoSNotSupported = 155;
	var UseAnotherServer = 156;
	var ServerMoved = 157;
	var SharedSubscriptionsNotSupported = 158;
	var ConnectionRateExceeded = 159;
	var MaximumConnectTime = 160;
	var SubscriptionIdentifiersNotSupported = 161;
	var WildcardSubscriptionsNotSupported = 162;
}

@:enum
abstract SubackReason(Int) to Int = {
	var GrantedQoS0 = 0;
	var GrantedQoS1 = 1 var GrantedQoS2 = 2;
	var UnspecifiedError = 128;
	var ImplementationSpecificError = 131;
	var NotAuthorized = 135;
	var TopicFilterInvalid = 143;
	var PacketIdentifierInUse = 145;
	var QuotaExceeded = 151;
	var SharedSubscriptionsNotSupported = 158;
	var SubscriptionIdentifiersNotSupported = 161;
	var WildcardSubscriptionsNotSupported = 162;
}

@:enum
abstract PublishProperty(Int) to Int = {
	var PayloadFormatIndicator = 1;
	var MessageExpiryInterval = 2;
	var ContentType = 3;
	var ResponseTopic = 8;
	var CorrelationData = 9;
	var SubscriptionIdentifier = 11;
	var TopicAlias = 35;
	var UserProperty = 38;
}

@:enum
abstract ConnectProperty(Int) to Int = {
	var SessionExpiryInterval = 17;
	var AuthenticationMethod = 21;
	var AuthenticationData = 22;
	var RequestProblemInformation = 23;
	var RequestResponseInformation = 25;
	var ReceiveMaximum = 33;
	var TopicAliasMaximum = 34;
	var UserProperty = 38;
	var MaximumPacketSize = 39;
}

@:enum
abstract ConnackProperty(Int) to Int = {
	var SessionExpiryInterval = 17;
	var AssignedClientIdentifier = 18;
	var ServerKeepAlive = 19;
	var AuthenticationMethod = 21;
	var AuthenticationData = 22;
	var ResponseInformation = 26;
	var ServerReference = 28;
	var ReasonString = 31;
	var ReceiveMaximum = 33;
	var TopicAliasMaximum = 34;
	var MaximumQoS = 36;
	var RetainAvailable = 37;
	var UserProperty = 38;
	var MaximumPacketSize = 39;
	var WildcardSubscriptionAvailable = 40;
	var SubscriptionIdentifierAvailable = 41;
	var SharedSubscriptionAvailabe = 42;
}

@:enum
abstract SubscribeProperty(Int) to Int = {
	var SubscriptionIdentifier = 11;
	var UserProperty = 38;
}

@:enum
abstract DisconnectProperty(Int) to Int = {
	var AuthenticationMethod = 21;
	var AuthenticationData = 22;
	var ReasonString = 31;
	var UserProperty = 38;
}

@:enum
abstract WillProperty(Int) to Int = {
	var PayloadFormatIndicator = 1;
	var MessageExpiryInterval = 2;
	var ContentType = 3;
	var ResponseTopic = 8;
	var CorrelationData = 9;
	var WillDelayInterval = 24;
	var UserProperty = 38;
}

@:enum
abstract AuthProperty(Int) to Int = {
	var SessionExpiryInterval = 17;
	var ServerReference = 28;
	var ReasonString = 31;
	var UserProperty = 38;
}

@:enum
abstract PubackProperty(Int) to Int = {
	var ReasonString = 31;
	var UserProperty = 38;
}

@:enum
abstract PubrecProperty(Int) to Int = {
	var ReasonString = 31;
	var UserProperty = 38;
}

@:enum
abstract PubrelProperty(Int) to Int = {
	var ReasonString = 31;
	var UserProperty = 38;
}

@:enum
abstract PubcompProperty(Int) to Int = {
	var ReasonString = 31;
	var UserProperty = 38;
}

@:enum
abstract SubackProperty(Int) to Int = {
	var ReasonString = 31;
	var UserProperty = 38;
}

@:enum
abstract UnsubscribeProperty(Int) to Int = {
	var UserProperty = 38;
}

@:enum
abstract UnsubackProperty(Int) to Int = {
	var ReasonString = 31;
	var UserProperty = 38;
}
