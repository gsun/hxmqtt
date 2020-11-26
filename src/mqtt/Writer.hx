package mqtt;

class Writer {
	var o:haxe.io.Output;
	var p:MqttPacket;

	public function new(o:haxe.io.Output) {
		this.o = o;
		o.bigEndian = true;
	}

	function writeHeader() {}

	function writePayload() {
		switch (p.pktType) {
			case Connect:
				writeConnect();
			case Connack:
				writeConnack();
			case Publish:
				writePublish();
			case Puback:
				writePuback();
			case Pubrec:
				writePubrec();
			case Pubrel:
				writePubrel();
			case Pubcomp:
				writePubcomp();
			case Subscribe:
				writeSubscribe();
			case Suback:
				writeSuback();
			case Unsubscribe:
				writeUnsubscribe();
			case Unsuback:
				writeUnsuback();
			case Disconnect:
				writeDisconnect();
			case Auth:
				writeAuth();
		}
	}

	function writeConnect() {}

	function writeConnack() {}

	function writePublish() {}

	function writePuback() {}

	function writePubrec() {}

	function writePubrel() {}

	function writePubcomp() {}

	function writeSubscribe() {}

	function writeSuback() {}

	function writeUnsubscribe() {}

	function writeUnsuback() {}

	function writeDisconnect() {}

	function writeAuth() {}

	public function write(p:MqttPacket) {
		this.p = p;
		writeHeader();
		writePayload();
	}
}
