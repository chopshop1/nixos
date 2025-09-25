{
  hostname = "devbox-container";
  username = "devuser";
  timezone = "UTC";
  sshAuthorizedKey = null;

  bootLoader = {
    type = null;
    device = null;
    efiSupport = false;
    useOSProber = false;
  };

  virtualization = { enableKVM = false; };
}
