package mqtt;

class Writer {
	var o:haxe.io.Output;
	var p:MqttPacket;

	public function new(o:haxe.io.Output) {
		this.o = o;
		o.bigEndian = true;
	}

	function writeHeader() {}

	function writeBody() {
		switch (p.pktType) {
			case Connect:
				writeConnectBody();
			case Connack:
				writeConnackBody();
			case Publish:
				writePublishBody();
			case Puback:
				writePubackBody();
			case Pubrec:
				writePubrecBody();
			case Pubrel:
				writePubrelBody();
			case Pubcomp:
				writePubcompBody();
			case Subscribe:
				writeSubscribeBody();
			case Suback:
				writeSubackBody();
			case Unsubscribe:
				writeUnsubscribeBody();
			case Unsuback:
				writeUnsubackBody();
			case Disconnect:
				writeDisconnectBody();
			case Auth:
				writeAuthBody();
		}
	}

	function writeConnectBody() {}

	function writeConnackBody() {}

	function writePublishBody() {}

	function writePubackBody() {}

	function writePubrecBody() {}

	function writePubrelBody() {}

	function writePubcompBody() {}

	function writeSubscribeBody() {}

	function writeSubackBody() {}

	function writeUnsubscribeBody() {}

	function writeUnsubackBody() {}

	function writeDisconnectBody() {}

	function writeAuthBody() {}

	public function write(p:MqttPacket) {
		this.p = p;
		writeHeader();
		writeBody();
	}
}
