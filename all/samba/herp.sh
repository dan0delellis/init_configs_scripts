#!/bin/bash
set -e
smb_conf="/etc/samba/smb.conf"
cred_file="/etc/samba/custom_credentials"

default_path=`pwd`
default_user="sambashares"

sharename=
share_path= #"    path =";
valid_users= #"    valid users = ";
#[<sharename>]
#    path = <sharepath>
#    valid users = <shareuser>
#    available = yes
#    browsable = yes
#    writable = yes
#    read only = no
#    public = no

is_that_a_yes() {
    echo $1 | egrep -qi '^$|^y(es)?$'
}

create_user=
create_group=
samba_username=
new_user_uid=-1
add_user_to_group=

dir_writable_by_share_user="no"
current_owner_valid="no"
create_samba_user() {
    uid_opt=
    if [ $new_user_uid != -1 ]; then
        uid_opt=" -u $new_user_uid "
    fi
    echo "useradd $1 $uid_opt -M -s /usr/sbin/nologin -d /etc/samba" || (echo "Error creating user: $!"; exit 1)
}

prompt_for_user() {
    read -p "Name for new user (sambashares): " samba_username
    if [ -z $samba_username ]; then
        samba_username=$default_user
    fi
    create_samba_user "$samba_username" $1
}

#get share path
read -p "Path of New Share (default: CWD):" custom_path
if [ ! -z $custom_path ]; then
    if [ -d $custom_path ]; then
        share_path=$(realpath $custom_path)
    else
        echo "! $custom_path is not a valid dir";
        exit 1;
    fi
else
    echo "> Blank input, using default path CWD"
    share_path=$default_path;
fi

if [ $share_path == "/" ]; then
    echo "Have you lost your mind?"; exit 1
fi

#get user for share
dir_Usr=$(stat -c %U $share_path)
dir_Grp=$(stat -c %G $share_path)
dir_UID=$(stat -c %u $share_path)
dir_GID=$(stat -c %g $share_path)

echo "This directory is owned by UID $dir_UID:$dir_GID ($dir_Usr:$dir_Grp)";
case $dir_Usr in
    UNKNOWN)
        read -p "Create new user with UID $dir_UID? (Y/n): " create_user
        new_user_uid=$dir_UID
    ;;
    root)
        read -p "Will not use user 'root' as share user. Create new user for shares? (Y/n): " create_user
    ;;
    *)
        read -p "This dir already has a non-root valid owner. Create new user for share anyway? (y/N): " create_user
        current_owner_valid="yes"
    ;;
esac

if is_that_a_yes $create_user; then
    prompt_for_user $new_user_id
fi

echo "if $share_path is now owned by a valid user, time to set the valid user option to that userid"
echo "otherwise, i need to do some logic with group ownership"
