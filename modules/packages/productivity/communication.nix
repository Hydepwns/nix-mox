{ pkgs, ... }:

{
  # Messaging and communication applications
  signal-desktop = pkgs.signal-desktop;
  telegram-desktop = pkgs.telegram-desktop;
  discord = pkgs.discord;
  slack = pkgs.slack;
  element-desktop = pkgs.element-desktop;
  whatsapp-for-linux = pkgs.whatsapp-for-linux;

  # Video calling and conferencing
  zoom-us = pkgs.zoom-us;
  teams = pkgs.teams;
  skypeforlinux = pkgs.skypeforlinux;

  # Email clients
  thunderbird = pkgs.thunderbird;
  evolution = pkgs.evolution;

  # IRC and chat
  hexchat = pkgs.hexchat;
  weechat = pkgs.weechat;

  # Voice and video
  mumble = pkgs.mumble;
  teamspeak_client = pkgs.teamspeak_client;
}
