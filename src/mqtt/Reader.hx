package mqtt;

class Reader {
	var i:haxe.io.Input;

	public function new(i) {
		this.i = i;
		this.i.bigEndian = true;
	}

	function readPktType():CtrlPktType {
		return Reserved;
	}

	function readPayload(t:CtrlPktType):Dynamic {
		return switch (t) {
			case Connect:
				readConnect();
			case Connack:
				readConnack();
			case Publish:
				readPublish();
			case Puback:
				readPuback();
			case Pubrec:
				readPubrec();
			case Pubrel:
				readPubrel();
			case Pubcomp:
				readPubcomp();
			case Subscribe:
				readSubscribe();
			case Suback:
				readSuback();
			case Unsubscribe:
				readUnsubscribe();
			case Unsuback:
				readUnsuback();
			case Disconnect:
				readDisconnect();
			case Auth:
				readAuth();
		}
	}

	function readConnect():Connect {}

	function readConnack():Connack {}

	function readPublish():Publish {}

	function readPuback():Puback {}

	function readPubrec():Pubrec {}

	function readPubrel():Pubrel {}

	function readPubcomp():Pubcomp {}

	function readSubscribe():Subscribe {}

	function readSuback():Suback {}

	function readUnsubscribe():Unsubscribe {}

	function readUnsuback():Unsuback {}

	function readDisconnect():Disconnect {}

	function readAuth():Auth {}

	public function read():MqttPacket {
		var pktType = readPktType();
		var payload = readPayload(pktType);
		return {
			pktType: pktType,
			payload: payload
		};
	}
}
