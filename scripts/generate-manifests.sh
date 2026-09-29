#!/usr/bin/env sh

# Generate Kubernetes manifests using Nixidy and scan for secrets

set -e

nixidy switch .#seraphim
gitleaks dir ./manifests --config .gitleaks.toml
trufflehog filesystem ./manifests --exclude-detectors=GitLab
git add manifests/*
