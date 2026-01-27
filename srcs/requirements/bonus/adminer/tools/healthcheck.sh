#!/bin/bash
set -e

curl -sf http://localhost:8080 > /dev/null || exit 1