#!/bin/bash
smb_conf="/etc/samba/smb.conf"
cred_file="/etc/samba/custom_credentials"
custom_path=
default_path=`pwd`
default_user="samba-user"

if [ ! -z "$1" ]; then
    custom_path=$1
fi

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

default_yes() {
    echo $1 | egrep -qi '^$|^y(es)?$'
}
default_no() {
    echo $1 | egrep -qi '^$|^n(o)'
}
fatal_error() {
    echo "Error: $1"
    exit $2
}
create_user=
create_group=
samba_username=
new_user_uid=-1
add_user_to_group=
use_current_owner=
use_other_user=

dir_writable_by_share_user="no"
current_owner_valid="no"

create_samba_user() {
    uid_opt=
    if [ $new_user_uid != -1 ]; then
        uid_opt=" -u $new_user_uid "
    fi
    echo "useradd $1 $uid_opt -M -s /usr/sbin/nologin -d /etc/samba" || fatal_error "can't create user: $!" 1
}

prompt_for_user() {
    read -p "Name for new user ($default_user): " samba_username
    if [ -z $samba_username ]; then
        samba_username=$default_user
    fi
    create_samba_user "$samba_username" $1
}

#get share path
if [ -z "$custom_path" ]; then
    read -p "Path of New Share (default: CWD):" custom_path
fi
if [ ! -z $custom_path ]; then
    if [ -d $custom_path ]; then
        share_path=$(realpath $custom_path)
    else
        fatal_error "$custom_path is not a valid dir" 1
    fi
else
    echo "Blank input, using default path CWD"
    share_path=$default_path;
fi

if [ $share_path == "/" ]; then
    fatal_error "Have you lost your mind?" 99
fi

#get user for share
dir_Usr=
dir_UID=
dir_Grp=
dir_GID=

gather_ownership() {
    dir_Usr=$(stat -c %U $share_path)
    dir_UID=$(stat -c %u $share_path)
    dir_Grp=$(stat -c %G $share_path)
    dir_GID=$(stat -c %g $share_path)
}

user_valid(){
    id -u $1 2>&1 > /dev/null && [ $1 != "root" ]
}

gather_ownership
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
        read -p "This dir already has a non-root, valid owner. Create new user for share anyway? (y/N): " create_user
        default_no $create_user && create_user="no"
    ;;
esac

if default_yes $create_user; then
    prompt_for_user $new_user_id
else
    user_valid $dir_Usr && suggested_user="($dir_Usr)"
    read -p "Existing user for shares: $suggested_user " samba_username
    if [ -z "$samba_username" -a ! -z "$suggested_user" ]; then
        samba_username=$dir_Usr
    fi
    user_valid $samba_username || fatal_error "Invalid user specified." 2
fi

gather_ownership
case $samba_username in
    "")
        fatal_error "without a user, you can't set up a read/writable share" 3
    ;;
    $dir_Usr)
        echo "ok time to set the share password"
        echo "ok we can write the config now"
    ;;
    *)
        echo "the username picked is $samba_username but the owner is $dir_Usr. this means group level sharing"
    ;;
esac
