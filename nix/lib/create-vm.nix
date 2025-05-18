{ inputs, name, uuid, vcpus, memory, mac, diskSize }:

let
  imageDir = "/var/lib/libvirt/images";
  image = inputs.nixos-generators.nixosGenerate {
    system = "x86_64-linux";
    modules = [
      {
        virtualisation.diskSize = diskSize * 1024;
      }
      ../hosts/${name}
    ];
    format = "qcow-efi";
  };
in
{
  system.activationScripts."${name}".text = ''
    echo "Creating ${name} image"
    mkdir -p ${imageDir}
    if [ ! -f ${imageDir}/${name}.qcow2 ]; then
      cp ${image}/nixos.qcow2 ${imageDir}/${name}.qcow2
    fi
  '';

  virtualisation.libvirt = {
    connections."qemu:///system".domains = [
      {
        active = true;
        definition = inputs.nixvirt.lib.domain.writeXML {
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
                  file = "${imageDir}/${name}.qcow2";
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
        };
      }
    ];
  };
}
