#!/bin/sh

# Generate the Kubernetes manifests

set -e

nixidy switch .#seraphim
gitleaks dir ./manifests --config .gitleaks.toml
trufflehog filesystem ./manifests --exclude-detectors=GitLab
git add manifests/*
