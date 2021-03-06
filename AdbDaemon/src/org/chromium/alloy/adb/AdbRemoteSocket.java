package org.chromium.alloy.adb;

class AdbRemoteSocket extends AdbSocket {
  private final Transport mTransport;

  public AdbRemoteSocket(int id, Transport transport) {
    super(id);
    mTransport = transport;
  }

  @Override
  public void ready() {
    AdbMessage message = new AdbMessage(AdbMessage.A_OKAY, mPeer.mId, mId);
    mTransport.send(message);
  }

  @Override
  public int enqueue(AdbMessage message) {
    message.command = AdbMessage.A_WRTE;
    message.arg0 = mPeer.mId;
    message.arg1 = mId;
    mTransport.send(message);
    return 1;
  }

  @Override
  public void close() {
    AdbMessage message = new AdbMessage(AdbMessage.A_CLSE, mPeer != null ? mPeer.mId : 0, mId, "");
    mTransport.send(message);
    super.close();
  }
}
