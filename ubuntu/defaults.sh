#!/bin/bash
sudo apt update; sudo apt remove -y unattended-upgrades needrestart
sudo apt upgrade -y
sudo apt install -y vim git screen
read -p "email for git:" EMAIL
read -p "name for git:" NAME
git config --global user.email "$EMAIL"
git config --global user.name "$NAME"
