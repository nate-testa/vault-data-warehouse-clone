#!/bin/bash

cd /home/vphubspotadmin/hs-integration || exit

# Check if the virtual environment exists
if [ -d ".venv" ]; then

    source .venv/bin/activate

else
    echo "Virtual environment not found!"
    exit 1
fi


python3 src/main.py


deactivate
