{
  nixidy.target.repository = "https://github.com/scareyo/homelab";
  nixidy.target.branch = "main";

  nixidy.defaults.helm.extraOpts = [
    "--api-versions gateway.networking.k8s.io/v1/HTTPRoute"
  ];
}
