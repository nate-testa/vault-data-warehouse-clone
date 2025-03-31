#!/bin/bash

cd /home/vphubspotadmin/hs-edw-writeback || exit

# Check if the virtual environment exists
if [ -d ".venv" ]; then

    source .venv/bin/activate

else
    echo "Virtual environment not found!"
    exit 1
fi


python3 main.py


deactivate
