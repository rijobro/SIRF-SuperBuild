#!/usr/bin/env bash
apt-get update
apt-get install -y --no-install-recommends \
  python-dev           \
  python-tk
apt-get clean
