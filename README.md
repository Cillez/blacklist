# Blacklist

A defensive PvP awareness tool for World of Warcraft Classic Anniversary (2.5.5). Track players who have engaged you in PvP combat and receive alerts when they're nearby to help you make informed decisions about your safety.

**Important**: This addon is designed for defensive awareness and legitimate PvP tracking purposes only. It should not be used to harass, discriminate, or negatively target other players. Use responsibly and in accordance with your server's rules and Blizzard's Terms of Service.

## Features

### Automatic Death Tracking
- Automatically detects when you're killed by a player
- Prompts you to add them to your blacklist with a custom reason
- Captures zone information automatically

### Proximity Alerts
- **Target Alerts**: Notifies you when you target a blacklisted player
- **Mouseover Alerts**: Warns you when you mouseover a blacklisted player
- **Nameplate Alerts**: Alerts when a blacklisted player's nameplate appears nearby
- Configurable cooldown to prevent spam (5-120 seconds)
- Optional chat messages and sound warnings

### Tooltip Integration
- Shows blacklist status directly in player tooltips
- Displays the reason for blacklisting
- Color-coded for easy identification

### Management Interface
- Full GUI window (`/bl` to open)
- Searchable list of all blacklisted players
- Edit reasons for existing entries
- Add players manually with custom reasons
- Remove players from the list
- View player count and statistics

### Settings Panel
- Toggle all notification types independently
- Configure alert cooldown duration
- Enable/disable death popup prompts
- Control tooltip display
- Accessible via Interface > AddOns > Blacklist or `/bl config`

## Commands

- `/bl` or `/blacklist` - Open the blacklist management window
- `/bl add <name> [reason]` - Add a player to your blacklist
- `/bl remove <name>` - Remove a player from your blacklist
- `/bl check` - Check if your current target is blacklisted
- `/bl config` - Open the settings panel
- `/bl help` - Show all available commands

## Usage

### Adding Players

**After Death:**
1. When killed by a player, a popup will appear (if enabled)
2. Enter a reason (optional) and click "Add"
3. The player is automatically added to your blacklist

**Manually:**
1. Open the blacklist window with `/bl`
2. Type a player name in the "Name" field
3. Optionally add a reason
4. Click "Add" or press Enter

**Via Command:**
```
/bl add PlayerName Camped me at BRM
```

### Managing Your List

- **Search**: Use the search box to filter players by name
- **Edit**: Click any row to edit the reason for that player
- **Remove**: Click the X button on any row to remove a player
- **Clear All**: Use the "Clear All" button to remove everyone (with confirmation)

### Notifications

When a blacklisted player is detected:
- A chat message appears (if enabled): `BLACKLISTED player spotted: PlayerName (reason) [source]`
- A warning sound plays (if enabled)
- The tooltip shows blacklist status (if enabled)

All alerts respect the cooldown setting to prevent spam.

## Configuration

Access settings via:
- Interface > AddOns > Blacklist
- `/bl config` command

**General:**
- Enable/disable the entire addon

**Death Popup:**
- Toggle automatic prompts after PvP deaths

**Notifications:**
- Alert on Target
- Alert on Mouseover
- Alert on Nameplate
- Chat notifications
- Sound alerts
- Alert cooldown (5-120 seconds)

**Tooltip:**
- Show blacklist status in player tooltips


## Author

Cillez

## Version

1.0

---

## Important Disclaimer

This addon is a **defensive awareness tool** designed to help you track players who have engaged you in PvP combat. It provides information to help you make informed decisions about your gameplay.

**This addon must not be used to:**
- Discriminate against players
- Violate Blizzard's Terms of Service or your server's rules
- Engage in any form of griefing or toxic behavior

The addon only provides information - how you use that information is your responsibility. Use this tool ethically and respectfully.
