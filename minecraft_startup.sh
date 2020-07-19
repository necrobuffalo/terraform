#!/bin/bash

MNT_DIR=/mnt/disks/minecraft

if [[ -d $MNT_DIR ]];then 
    exit
else 
    sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/disk/by-id/google-minecraft-worlds
    sudo mkdir -p $MNT_DIR
    sudo mount -o discard,defaults /dev/disk/by-id/google-minecraft-worlds $MNT_DIR
fi
