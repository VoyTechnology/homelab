local config = import 'config.libsonnet';
local images = import 'images.libsonnet';
local otbr = import 'otbr.libsonnet';

config + images + otbr {
  // TODO: Pass this through overrides once I figure out how...
  _config+:: {
    threadDongle: "/dev/serial/by-id/usb-Nabu_Casa_ZBT-2_14C19FC4DBA8-if00",
    networkInterface: 'enp6s0',
    nodeName: 's1-bet1',
  }
}
