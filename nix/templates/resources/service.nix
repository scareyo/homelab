{ labels, name }:

{
  metadata = {
    inherit labels;
  };
  spec = {
    selector = {
      "app.kubernetes.io/name" = name;
    };
    ports = [
      {
        protocol = "TCP";
        port = 80;
        targetPort = "http";
      }
    ];
  };
}
