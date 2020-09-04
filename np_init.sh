#!/bin/ash

PARTITION_NAME="/dev/mmcblk1p3"
FILESYSTEM_TYPE="ext3"
MOUNT_PATH="/mnt/user_part"
LOG_FILE="/tmp/np-init.log"
DIRS_STRUCT_PATH="/etc/"
DIRS_STRUCT_IMG="ddsi.tar"
DIR1="/etc"
DIR2="/usr"
DIR3="/mnt"

put_to_log() {
  echo "$1" >> $LOG_FILE
}

put_to_log_dt() {
  timestamp=$( date )
  echo "$timestamp   $1" >> $LOG_FILE
}

check_fs_type() {
  blkid_res=$(blkid "$PARTITION_NAME")
  if echo "$blkid_res" | grep -q "$FILESYSTEM_TYPE"; then
    put_to_log "fs type: ok";
  else
    put_to_log "fs type: error";
    format_ext3
    if [ $? -eq 0 ]; then
      put_to_log "formatting: successfully";
    else
      put_to_log "formatting: error, partition usage isn't possible!";
      exit 1
    fi
  fi
}

format_ext3() {
  mkfs.ext3 -j "$PARTITION_NAME"
}

restore_dirs_struct() {
  cp $DIRS_STRUCT_PATH$DIRS_STRUCT_IMG $MOUNT_PATH
  cd $MOUNT_PATH
  tar -xf $DIRS_STRUCT_IMG
  rm $DIRS_STRUCT_IMG
  umount "$MOUNT_PATH"
}

check_dir_struct() {
  mkdir -p "$MOUNT_PATH"
  mount "$PARTITION_NAME" "$MOUNT_PATH"
  if [ $? -eq 0 ]; then
    if [ -d "$MOUNT_PATH$DIR1" ] && [ -d "$MOUNT_PATH$DIR2" ] && [ -d "$MOUNT_PATH$DIR3" ]; then
      put_to_log "directories structure: ok";
    else
      put_to_log "directories structure: error, one or more directories are missing!";
      put_to_log "restoring directories structure..."
      restore_dirs_struct
      if [ $? -eq 0 ]; then
        put_to_log "restore: ok"
      else
        put_to_log "restore: error, partition usage isn't possible!"
        exit 1
      fi
    fi
  else
    put_to_log "mount: error, directories structure checking isn't possible!";
    exit 1
  fi
}

rm $LOG_FILE
check_fs_type
check_dir_struct
exit 0
