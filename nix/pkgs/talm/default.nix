{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "talm";
  version = "0.16.0";

  src = fetchFromGitHub {
    owner = "cozystack";
    repo = "talm";
    rev = "v${version}";
    sha256 = "sha256-lT0NYYYt6HoPBTVA4otzwdOJBnjJd5AtLKKuJi3K9+A=";
  };

  vendorHash = "sha256-dzcA2lBmxT7CXI8/Ad8jnHIfNcmgK3u3PlljqVFIXMg=";

  proxyVendor = true;

  subPackages = [
    "."
  ];

  meta = {
    description = "Manage Talos Linux the GitOps Way";
    homepage = "https://github.com/cozystack/talm";
    license = lib.licenses.mpl20;
  };
}
