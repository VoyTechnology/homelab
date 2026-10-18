local config = import 'config.libsonnet';
local images = import 'images.libsonnet';
local homeassistant = import 'homeassistant.libsonnet';
local otbr = import 'otbr.libsonnet';

local threadDongle = "/dev/serial/by-id/usb-Nabu_Casa_ZBT-2_14C19FC4DBA8-if00";

config + images + homeassistant + otbr {
  // TODO: Pass this through overrides once I figure out how...
  _config+:: {
    threadDongle: threadDongle,
    networkInterface: 'enp6s0',
    nodeName: 's1-bet1',
    devices: {
      'zigbee-dongle': "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_48595f40c274ef1196c7cd8c8fcc3fa0-if00-port0",
      'thread-dongle': threadDongle,
    },
  }
}
