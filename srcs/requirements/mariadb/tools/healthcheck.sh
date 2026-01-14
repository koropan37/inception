#!/bin/bash
set -e

PORT=3306
ss -tuln sport = :$PORT | grep -q 'LISTEN' || exit 1