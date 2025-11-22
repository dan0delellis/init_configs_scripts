#!/bin/bash
bash apt.sh
bash git.sh
bash setup_golang.sh
sudo apt update; sudo apt remove -y unattended-upgrades needrestart
