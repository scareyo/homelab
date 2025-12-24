{ config, name }:

{
  spec = {
    selector = {
      "app.kubernetes.io/name" = name;
    };
    ports = [
      {
        protocol = "TCP";
        port = 80;
        targetPort = config.workload.port;
      }
    ];
  };
}
