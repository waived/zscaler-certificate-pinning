#!/bin/bash

# select CRT certiciate
read -rp "Path to CRT certificate: " cert

# confirm file exists
if [[ ! -f "$cert" ]]; then
    echo -e "\r\nError. File does not exist/unavailable.\r\n"
    exit 1
fi

# confirm it ends with .crt
if [[ ! "$cert" =~ \.crt$ ]]; then
    echo -e "\r\nError. Invalid file type. Exiting...\r\n"
    exit 1
fi

WGETRC="$HOME/.wgetrc"

# if wgetrc config-file exists and contains a ca_certificate entry, remove it
if [[ -f "$WGETRC" ]]; then
    # backup original file
    cp "$WGETRC" "$WGETRC.bak"

    # remove any existing ca_certificate lines
    grep -v '^ca_certificate=' "$WGETRC" > "${WGETRC}.tmp" && mv "${WGETRC}.tmp" "$WGETRC"
    if [[ $? -ne 0 ]]; then
        echo -e "\r\nError. Could not modify $WGETRC.\r\n"
        exit 1
    fi
fi

# add new ca_certificate entry
echo "ca_certificate=$cert" >> "$WGETRC"
if [[ $? -ne 0 ]]; then
    echo -e "\r\nError. Failed to write to $WGETRC\r\n"
    exit 1
fi

echo "Done."
