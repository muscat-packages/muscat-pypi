#!/bin/bash

echo "Test script to install and test Muscat using uv"

for pver in 3.10 3.11 3.12 3.13 3.14; do
    echo "Working on, $pver!"
    echo "Working on, $pver!" > log${pver}.txt
    (
    uv venv p${pver}env -p $pver  > log${pver}.txt 2>&1
    source p${pver}env/bin/activate >> log${pver}.txt 2>&1
    uv pip install Muscat[all] >> log${pver}.txt 2>&1
    python -m Muscat.Helpers.Check >> log${pver}.txt 2>&1
    deactivate
    )
done

echo "Test script to install and test Muscat using uv (DONE)"
