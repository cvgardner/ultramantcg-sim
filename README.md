# Ultraman TCG Simulator

This is a fan-made simulator for the Ultraman TCG built in GODOT. 

# Disclaimer

This project is not affiliated with, endorsed by, or in any way connected to the Ultraman Trading Card Game (TCG), Tsuburaya Productions Co., Ltd, or any other companies involved in the production, distribution, or marketing of the Ultraman TCG. All trademarks, logos, and images related to the Ultraman TCG are the property of their respective owners. This project is an independent endeavor created for informational and entertainment purposes only.

# TODOs

https://trello.com/b/rsCkQVH3/ultramantcg-sim

# Implementation Details

## Card Database

The current card database is stored in the ultramansim/cards and the card data is stored in json files separted by set in the scripts/card_data directory. This decision was made for simplicity and allows for art customization by savy users. The ideal setup would be to store the card_data json/data in a hosted database and have the clients pull it when loading. This way the data which the automation is based on would not be able to be tampered with.

## PVP Server

Since this is a fan project using a dedicated server model was deemed cost prohibitive. We opted for a peer2peer connection system with a remote server to handle NAT hole punching. Initially this will only allow for room matches by sharing codes but a match making system will be implemented in the future as well as potentially ranked. 