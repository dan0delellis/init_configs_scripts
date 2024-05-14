#!/bin/bash
fail_die () {
    logger $1
    exit 1
}

SERVICE="vlc-radio.service"
MIN=300
PLAYLIST=/etc/default/vlc-radio/playlist.m3u8
CURRENT_LEN=$(wc -l $PLAYLIST | awk {'print $1'}) || fail_die "playlist file does not exist"


dpkg --compare-versions $CURRENT_LEN gt $MIN || fail_die "playlist file is too short"

TEMP=$(mktemp)
shuf $PLAYLIST > $TEMP
NEW_LEN=$(wc -l $TEMP | awk {'print $1'})

dpkg --compare-versions $NEW_LEN ge $CURRENT_LEN || fail_die "shuffled playlist $TEMP is somehow shorter than playlist file"

cp $TEMP $PLAYLIST || fail_die "couldn't copy new playlist in place"

systemctl restart $SERVICE
