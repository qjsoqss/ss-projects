#!/bin/bash

dir_path="/srv/sftpuser/data"
archive_base="$HOME/logs_arch"
current_archive="${archive_base}.zip"
old_archive="${archive_base}_old.zip"
old_archive_1="${archive_base}_old_1.zip"
max_size_mb=500

get_file_size_mb() {
    local file="$1"
    if [ -f "$file" ]; then
        du -m "$file" | cut -f1    
    else
        echo 0
    fi
}

rotate_archives() {
    if [ -f "$old_archive_1" ]; then
        rm -f "$old_archive_1"
    fi

    if [ -f "$old_archive" ]; then
        mv "$old_archive" "$old_archive_1"
    fi

    if [ -f "$current_archive" ]; then
        mv "$current_archive" "$old_archive"
    fi
}

if [ $(get_file_size_mb "$current_archive") -ge $max_size_mb ]; then
    rotate_archives
fi

zip -j "$current_archive" "$dir_path"/*

rm -f "$dir_path"/*

if [ $(get_file_size_mb "$current_archive") -ge $max_size_mb ]; then
    rotate_archives
fi
