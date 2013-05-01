package org.chromium.alloy.adb;

class AdbSocket {
  private static int sNextId = 1;
  protected int mId = -1;
  private boolean mClosing = false;
  private boolean mExitOnClose = false;
  protected AdbSocket mPeer = null;

  protected AdbSocket() {
    mId = sNextId++;
  }

  protected AdbSocket(int id) {
    mId = id;
  }

  public int id() {
    return mId;
  }

  public AdbSocket peer() {
    return mPeer;
  }

  public void connectPeer(AdbSocket peer) {
    assert(mPeer == null);
    assert(peer != null);
    assert(peer.mPeer == null);
    mPeer = peer;
    peer.mPeer = this;
  }

  public void ready() {
  }

  public int enqueue(AdbMessage message) {
    mPeer.close();
    return -1;
  }

  public void close() {
    if (mPeer != null) {
      mPeer.mPeer = null;
      mPeer.close();
    }
  }

  public void disconnect() {
  }

  protected void sendToPeer(final String data) {
    AdbMessage message = new AdbMessage();
    message.setData(data);
    mPeer.enqueue(message);
  }
}
