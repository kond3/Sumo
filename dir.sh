#!/bin/bash

# Author: kond3
# Date: 31/05/2024
# Last modified: 31/05/2024 16:20:56

# Description
# Script to dynamically get program's directory. For everything to work, this must be in same directory of configuration.sh

# Usage
# ./dir.sh

echo $(which dir.sh | sed 's:/dir.sh::')
exit 0
