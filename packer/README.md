# Talos Linux Hetzer Cloud Image

Prepare an image with Packer

## Requirements

1. Set environement variables:

    - `HCLOUD_TOKEN`
    - `INFISICAL_UNIVERSAL_AUTH_CLIENT_ID`
    - `INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET`

## Build

```
packer init .
```

```
packer build .
```
