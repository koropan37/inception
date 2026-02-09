#!/bin/bash
set -e

curl -kfs https://localhost/ > /dev/null || exit 1

exit 0