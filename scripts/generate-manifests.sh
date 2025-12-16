#!/bin/sh

# Generate the Kubernetes manifests

set -e

nixidy switch .#seraphim
git add manifests/*
