resource "harvester_storageclass" "infrastructure-longhorn" {
  name = "infrastructure-longhorn"
  parameters = {
    "migratable" = "true"
    "numberOfReplicas" = "1"
    "staleReplicaTimeout" = "30"
  }
}
