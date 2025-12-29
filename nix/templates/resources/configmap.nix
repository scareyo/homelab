{ labels, persistence }:

{
  metadata = {
    inherit labels;
  };
  data = persistence.config.data;
}
