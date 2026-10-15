enum ServerPreset {
  usb('USB', 'http://localhost:8080'),
  tailscale('Tailscale', 'https://aleksa-laptop.taila87519.ts.net');

  const ServerPreset(this.label, this.url);
  final String label;
  final String url;
}
