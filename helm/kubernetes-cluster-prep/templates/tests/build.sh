#!/bin/bash -e

# Run from dir in which this script resides
cd "$(dirname "$0")"

TAG=latest

echo "================================================"
echo "     Building Cluster Prep Helm test image"
echo "================================================"
docker build -t "rpothier/conjur-cluster-prep-test:$TAG" .
echo "Done!"
