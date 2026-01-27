#!/bin/bash
mysqladmin ping -h localhost -u root -p"$(cat /run/secrets/db_root_password)" --silent