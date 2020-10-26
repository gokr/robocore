class RoboUser {
  int? discordId, telegramId;

  RoboUser.discord(this.discordId);
  RoboUser.telegram(this.telegramId);
  RoboUser.both(this.discordId, this.telegramId);

  @override
  bool operator ==(other) {
    if (other is RoboUser)
      return other.discordId == this.discordId ||
          other.telegramId == this.telegramId;
    return false;
  }

  String toString() => "RoboUser($discordId, $telegramId)";
}
