# Sumo Logic API
I developed this program during my first internship as a SOC Analyst, when, each time a new client (or tenant) was added to the Sumo Logic SIEM, all configuration were made "by hand" through the web interface. Using the API documentation at [Sumo API docs](https://help.sumologic.com/docs/api/) I developed a BASH program to automate some of the configurations. I'm looking forward to improving its functionality, if you want to contribute, take a look at the [tasklist](https://github.com/kond3/Sumo/issues/1)!
***
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
***
# Supported resources
### Log Analytics Platform
- Role
- User
- Dashboard
- Log Search
- Collector
- Source
- Field
- Field Extraction Rule
- Scheduled view
### Cloud SIEM Enterprise
- Rule
- Rule Tuning Expression
- Log Mapping
- Threat Intel Source
- Entity Criticality Config
- Custom Insight
- Context action
- Custom Entity Type
- Custom Match List Column
- Match List
- Match List Item
***
# Note

I chose BASH to do this project for two principal reasons:
1. 😎 Its semplicity in hanlding json files with jq
2. 🐧 The nice tux interface of cowsay 

This program was developed on Ubuntu 22.04, and all the testing was done with this OS, however every Debian-based distro should work just fine.
To understand program flow and view a detailed example of program execution, check out the [wiki](https://github.com/kond3/Sumo/wiki)!
***
# Delete

During the testing phase, I created a simple script to delete resources from a tentan. I want to include it to the repo as `delete_resource.sh` for everyone that can find it useful. It's usage is quite simple:
```
delete_resource.sh <resource_name_1> [resource_name_2] ... [resource_name_n]
```
To make it work you just need to insert id-key pair inside the script. Resource names must match the ones used in `./api/import.txt`.
***
# Important
The program is not complete yet, I will upload all files in a few days.
