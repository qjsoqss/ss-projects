#!/bin/bash

dir_path="/srv/sftpuser/data"
archive_path="$HOME/logs_arch.zip"
zip -j "$archive_path" "$dir_path"/*
rm -f "$dir_path"/*
