// Downloaded by the image on start. Renovate bumps the versioned ones.
local plugins = [
  'https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot',
  'https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot',
  // renovate: datasource=github-releases-files depName=ViaVersion/ViaVersion
  'https://github.com/ViaVersion/ViaVersion/releases/download/5.4.2/ViaVersion-5.4.2.jar',
  // renovate: datasource=github-releases-files depName=BlueMap-Minecraft/BlueMap
  'https://github.com/BlueMap-Minecraft/BlueMap/releases/download/v5.20/bluemap-5.20-paper.jar',
  'https://github.com/ZetaPlugins/TimberZ/releases/download/1.2.0/TimberZ-1.2.0-1.21.9.jar',
];

{
  minecraft_env+:: { PLUGINS: std.join(',', plugins) },
}
