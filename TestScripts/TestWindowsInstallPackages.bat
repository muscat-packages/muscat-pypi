@echo off
setlocal enabledelayedexpansion

echo "Test script to install and test Muscat using uv"

for %%P in (3.10 3.11 3.12 3.13 3.14) do (
    echo Working on, %%P!
    echo Working on, %%P! > log%%P.win.txt
    uv venv p%%Penv -p %%P >> log%%P.win.txt 2>&1
    call p%%Penv\Scripts\activate >> log%%P.win.txt 2>&1
    uv pip install Muscat h5py >> log%%P.win.txt 2>&1
    python -m Muscat.Helpers.Check >> log%%P.win.txt 2>&1
    call deactivate
)
echo "Done"

echo "Test script to install and test Muscat using uv (DONE)"