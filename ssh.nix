{ ... }: {

  services.openssh = {
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    enable = true;
    startWhenNeeded = true;
  };

}
