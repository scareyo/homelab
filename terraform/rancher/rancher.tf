provider "rancher2" {
  alias = "admin"

  api_url = rancher2_bootstrap.admin.url
  token_key = rancher2_bootstrap.admin.token
  insecure = true
}

resource "rancher2_bootstrap" "admin" {
  initial_password = "${local.secrets.rancher.password}"
  password = "${local.secrets.rancher.password}"
  telemetry = false
}

resource "rancher2_catalog_v2" "harvester-ui" {
  provider = rancher2.admin

  cluster_id = "local"
  name = "harvester-ui"
  git_repo = "https://github.com/harvester/harvester-ui-extension"
  git_branch = "gh-pages"
}

resource "rancher2_app_v2" "harvester-ui" {
  provider = rancher2.admin

  cluster_id = "local"
  name = "harvester"
  namespace = "cattle-ui-plugin-system"
  repo_name = "harvester-ui"
  chart_name = "harvester"
  chart_version = "1.0.0"
}

resource "rancher2_cluster" "seraphim" {
  provider = rancher2.admin

  name = "seraphim"
  labels = {
    "provider.cattle.io" = "harvester"
  }
}

resource "kubernetes_manifest" "cluster-registration-url" {
  manifest = {
    "apiVersion" = "harvesterhci.io/v1beta1"
    "kind"       = "Setting"
    "metadata" = {
      "name"      = "cluster-registration-url"
    }
    "value"      = "${resource.rancher2_cluster.seraphim.cluster_registration_token[0].manifest_url}"
  }
}
