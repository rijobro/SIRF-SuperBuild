#!/usr/bin/env bash
# Gadgetron
apt-get update
apt-get install -y --no-install-recommends \
  h5utils              \
  liblapack-dev        \
  libace-dev
# Not required (yet) by SIRF
# libxml2-dev
# libxslt-dev
# python-h5py
# python-libxml2
# python-psutil
# libplplot-dev
