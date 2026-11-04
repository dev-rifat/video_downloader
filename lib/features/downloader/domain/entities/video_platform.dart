enum VideoPlatform {
  youtube('YouTube'),
  facebook('Facebook'),
  instagram('Instagram'),
  tiktok('TikTok'),
  twitter('X / Twitter'),
  other('Web');

  const VideoPlatform(this.label);
  final String label;
}
