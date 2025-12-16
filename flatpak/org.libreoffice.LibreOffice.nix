{
  services.flatpak.packages = [ "flathub:app/org.libreoffice.LibreOffice//stable" ];
  services.flatpak.overrides."org.libreoffice.LibreOffice" = {
    Context.filesystems = [ "!host" ];
  };
}
