# HRComserv - Community Services Roleplay Script

HRComserv is a simple, lightweight community services script designed for roleplay servers. It doesn’t require any additional frameworks and provides a variety of features to enhance roleplay interactions. Whether you're managing a community services program or adding a unique gameplay mechanic to your server.

## Features

- **Multiple Locations**: Provide a variety of locations where players can perform community service tasks, adding variety to gameplay.
- **Task Variety**: Includes three different types of tasks: 
  - **Hammering**: Animated task with specific duration for hammering onto some structures
  - **Sweeping**: Animated task with specific duration for cleaning different floors with a broom
  - **Digging**: Animated task with specific duration for digging on soft surfaces with a small shovel
- **Staff Commands**: Simplify the management of community service assignments with two powerful commands:
  - `/comserv [id] [tasksCount]`: Assign community services tasks to a player by ID, specifying how many tasks they need to complete.
  - `/stopComserv [id]`: Stop or end the community services tasks of a player.
- **Clothing & Inventory Management**: Automatically change the player’s clothes, remove certain items, and set their inventory to "busy" mode, ensuring a realistic and immersive experience.
- **Everything Configuratable**: All our features (staff commands, tasks types, locations, etc.) are configuratable from our config file
- **Optimized for Performance**: Lightweight and optimized for use on your server, ensuring smooth operation even in high-traffic environments.

## Video Preview

For a quick preview of how HRComserv works, check out this video:

[Watch Video on YouTube](https://youtube.com/watch?v=4hq8T-GZvPo)

## Installation

1. **Download** the script and it's dependencies.
   
2. **Place the Script** in the `resources` folder of your server.
3. **Configure** the script from it's `config.lua` file.
4. **Add to Server Configuration**:
   - In your `server.cfg` or equivalent, add the following line to start the script:

        `start HRComserv`
5. **Restart Your Server** and you're ready to go!

## Documentation

For detailed instructions on how to set up and use HRComserv, refer to the official documentation:

[HRComserv Documentation](https://hrscripts.gitbook.io/resources/HRComserv)

## Support & Community

Need help or have questions? Join the official HRScripts Development support Discord server to connect with the community and get assistance:

[Join Support Discord](https://discord.gg/Du4gEtFn4V)
