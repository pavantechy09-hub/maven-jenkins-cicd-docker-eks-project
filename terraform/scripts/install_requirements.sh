#!/bin/bash
# Helper script (optional) to install prerequisites locally or on instance
set -e
yum update -y
yum install -y java-1.8.0-openjdk-devel maven git curl
