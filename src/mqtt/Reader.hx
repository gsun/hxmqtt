package mqtt;

class Reader {
	var i:haxe.io.Input;
	var bits:format.tools.BitsInput;

	public function new(i) {
		this.i = i;
		this.i.bigEndian = true;
		bits = new format.tools.BitsInput(i);
	}

	function readString() {
		var size = i.readUInt16();
		return i.readString(size, UTF8);
	}

	function readBody(t:CtrlPktType):Dynamic {
		return switch (t) {
			case Connect:
				readConnectBody();
			case Connack:
				readConnackBody();
			case Publish:
				readPublishBody();
			case Puback:
				readPubackBody();
			case Pubrec:
				readPubrecBody();
			case Pubrel:
				readPubrelBody();
			case Pubcomp:
				readPubcompBody();
			case Subscribe:
				readSubscribeBody();
			case Suback:
				readSubackBody();
			case Unsubscribe:
				readUnsubscribeBody();
			case Unsuback:
				readUnsubackBody();
			case Disconnect:
				readDisconnectBody();
			case Auth:
				readAuthBody();
		}
	}

	function readConnectBody():Connect {
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
	}

	function readConnackBody():Connack {}

	function readPublishBody():Publish {}

	function readPubackBody():Puback {}

	function readPubrecBody():Pubrec {}

	function readPubrelBody():Pubrel {}

	function readPubcompBody():Pubcomp {}

	function readSubscribeBody():Subscribe {}

	function readSubackBody():Suback {}

	function readUnsubscribeBody():Unsubscribe {}

	function readUnsubackBody():Unsuback {}

	function readDisconnectBody():Disconnect {}

	function readAuthBody():Auth {}

	public function read():MqttPacket {
		var pktType = bits.readBits(4);
		var dup = bits.readBit();
		var qos = bits.readBits(2);
		var retain = bits.readBit();
		if (pktType <= CtrlPktType.Reserved || pktType > CtrlPktType.Auth) {
			throw new MalformedPacketException('invalid packet type ${pktType}');
		}
		if (qos < Qos.AtMostOnce || qos > Qos.ExactlyOnce) {
			throw new MalformedPacketException('invalid Qos ${qos}');
		}
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
