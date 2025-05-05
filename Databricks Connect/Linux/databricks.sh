#!/bin/bash

# confirm bash profile exists
if [ ! -f "$HOME/.bashrc" ]; then
    echo -e "\r\nError. BASH profile not found. Exiting...\r\n"
    exit 1
fi

# select PEM certificate
echo "PATH to CRT certificate:"
read crt_file

if [ ! -f "$crt_file" ]; then
    echo -e "\r\nError. File does not exist/unavailable.\r\n"
    exit 1
elif [[ "$crt_file" != *.crt ]]; then
    echo -e "\r\nError. Invalid file-extension.\r\n"
    exit 1
else
    cert="$crt_file"
fi

# modify bash profile to initalize certificate per each BASH session
echo "export REQUESTS_CA_BUNDLE=$cert" >> "$HOME/.bashrc"

# check for errors
if [ $? -ne 0 ]; then
    echo -e "\r\nError. Failed to update $HOME/.bashrc"
    exit 1
else
    echo -e "\r\nDone.\r\n"
fi
