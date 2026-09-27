# Acore Racial Tooltips

WoW 3.3.5a displays the base cooldown from Spell.dbc even when the server sends a different actual cooldown.
This addon updates Shadowmeld's cooldown heading to 2 minutes for a combat cast, then restores 10 seconds
when its cooldown ends. It preserves the description and the remaining-cooldown line.

Copy this directory into the client's `Interface/AddOns` directory and fully restart WoW so the new addon
is discovered. Enable **Acore Racial Tooltips** in the character selection AddOns menu. No DBC or MPQ changes
are required. The addon changes presentation only; the server still enforces the actual cooldown.

Combat is captured when the cast is sent, before Sanctuary can clear it, and saved only on a successful cast.
Once the aura ends, the displayed heading follows the cooldown received from the server. Formatting uses
WoW's localized cooldown strings. Only the Shadowmeld spell tooltip is changed.
