# Sumo
I created this program during my first internship as a SOC Analyst, when, each time a new client (or tenant) was added to the SIEM, all configuration were made "by hand" through the web interface. Using the Sumologic API documentation I developed a BASH program to automate some of the configurations. I'm looking forward to improving its functionality, if you want to contribute, take a look at the [tasklist](https://github.com/kond3/Sumo/issues/1)!

# Installation and usage
Program execution is quite straightforward, however some initial configurations are required. First, create an access ID - access key pair from Sumo (`Administration` -> `Security` -> `Access Key`).

Once you have id and key, the actual configuration can start:
```
sudo apt update && sudo apt upgrade
sudo apt install curl jq cowsay

git clone https://github.com/kond3/Sumo.git
cd Sumo

export PATH=$PATH:$(pwd)
chmod 744 configure.sh
chmod 744 script/*.sh
```
Then, to start the program just type:
```
configuration.sh
```
# Note

I chose BASH to do this project for two principal reasons:
1. 😎 Its semplicity in hanlding json files with jq
2. 🐧 The nice tux interface of cowsay 

This program was developed on Ubuntu 22.04, and all the testing was done with this OS, however every Debian-based distro should work just fine.
To understand program flow and view a detailed example of program execution, check out the [wiki](https://github.com/kond3/Sumo/wiki)!

# Important
The program is not complete yet, I will upload all files in a few days.
