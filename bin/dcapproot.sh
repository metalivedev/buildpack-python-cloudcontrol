#!/bin/bash
set -e

: ${APPROOT:="."}

# Set the code and current directories expected by dotcloud apps
ln -s . code
ln -s . git-$DEP_VERSION
ln -s code/$APPROOT current
