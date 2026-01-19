#!/bin/sh

# Generate the Kubernetes manifests

set -e

nixidy switch .#seraphim
gitleaks dir ./manifests
trufflehog filesystem ./manifests
git add manifests/*
