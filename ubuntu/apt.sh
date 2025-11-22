#!/bin/bash
sudo apt update; sudo apt remove -y unattended-upgrades needrestart
sudo apt upgrade -y
sudo apt install -y vim git screen
