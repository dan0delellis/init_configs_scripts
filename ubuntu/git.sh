#!/bin/bash
read -p "email for git:" EMAIL
read -p "name for git:" NAME
git config --global user.email "$EMAIL"
git config --global user.name "$NAME"
