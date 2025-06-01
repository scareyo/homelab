{ inputs, name, uuid, memory, vcpus, mac, disk }:

inputs.nixvirt.lib.domain.writeXML {
  type = "kvm";
  name = name;
  uuid = uuid;
  memory = {
    count = memory;
    unit = "GiB";
  };
  vcpu = {
    count = vcpus;
  };
  os = {
    firmware = "efi";
    type = "hvm";
    arch = "x86_64";
    machine = "q35";
    boot = {
      dev = "hd";
    };
  };
  features = {
    acpi = {};
    apic = {};
  };
  cpu = {
    mode = "host-passthrough";
  };
  clock = {
    offset = "utc";
    timer = [
      { name = "rtc"; tickpolicy = "catchup"; }
      { name = "pit"; tickpolicy = "delay"; }
      { name = "hpet"; present = false; }
    ];
  };
  pm = {
    suspend-to-mem = { enabled = false; };
    suspend-to-disk = { enabled = false; };
  };
  devices = {
    emulator = "/run/current-system/sw/bin/qemu-system-x86_64";
    disk = [
      {
        type = "file";
        device = "disk";
        driver = {
          name = "qemu";
          type = "qcow2";
        };
        source = {
          file = "${disk}";
        };
        target = {
          bus = "virtio";
          dev = "vda";
        };
      }
    ];
    controller = [
      { type = "usb"; model = "qemu-xhci"; ports = 15; }
      { type = "pci"; model = "pcie-root"; }
      { type = "pci"; model = "pcie-root-port"; }
      { type = "pci"; model = "pcie-root-port"; }
      { type = "pci"; model = "pcie-root-port"; }
      { type = "pci"; model = "pcie-root-port"; }
      { type = "pci"; model = "pcie-root-port"; }
      { type = "pci"; model = "pcie-root-port"; }
      { type = "pci"; model = "pcie-root-port"; }
      { type = "pci"; model = "pcie-root-port"; }
      { type = "pci"; model = "pcie-root-port"; }
      { type = "pci"; model = "pcie-root-port"; }
      { type = "pci"; model = "pcie-root-port"; }
      { type = "pci"; model = "pcie-root-port"; }
      { type = "pci"; model = "pcie-root-port"; }
      { type = "pci"; model = "pcie-root-port"; }
    ];
    interface = {
      type = "bridge";
      source = { bridge = "br0"; };
      mac = { address = mac; };
      model = { type = "virtio"; };
    };
    console = {
      type = "pty";
    };
    channel = [
      {
        type = "unix";
        source = {
          mode = "bind";
        };
        target = {
          type = "virtio";
          name = "org.qemu.guest_agent.0";
        };
      }
      {
        type = "spicevmc";
        target = {
          type = "virtio";
          name = "com.redhat.spice.0";
        };
      }
    ];
    input = [
      {
        type = "tablet";
        bus = "usb";
      }
    ];
    graphics = {
      type = "spice";
      autoport = true;
      image = { compression = false; };
    };
    sound = {
      model = "ich9";
    };
    video = {
      model = { type = "qxl"; };
    };
    redirdev = [
      { bus = "usb"; type = "spicevmc"; }
      { bus = "usb"; type = "spicevmc"; }
    ];
    memballoon = {
      model = "virtio";
    };
    rng = {
      model = "virtio";
      backend = { model = "random"; source = "/dev/urandom"; };
    };
  };
}
