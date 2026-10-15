enum ServerPreset {
  usb('USB', 'http://localhost:8080'),
  tailscale('Tailscale', 'https://<laptop>.<tailnet>.ts.net');

  const ServerPreset(this.label, this.url);
  final String label;
  final String url;
}
