#!/bin/bash
set -e

if ! pidof nginx > /dev/null; then
    exit 1
fi

if ! ss -tuln | grep -q ':443.*LISTEN'; then
    exit 1
fi

exit 0