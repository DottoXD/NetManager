
# NetManager
A Material UI mobile network monitoring app built with ease-of-use and speed in mind.
Built from scratch with Flutter, NetManager plans to respect Material guidelines for user interfaces and possibly blend in with system applications.

## Supported platforms
NetManager currently supports Android 10+ (SDK ver. 29).
Support for older Android versions (Android 7+, SDK ver. 24) is planned before version 1.0.0.
iOS support is currently unplanned due to missing public APIs to reliably retrieve cell data.

## Data accuracy
NetManager does its best to provide accurate and up-to-date data by filtering out invalid cell info returned by Android's Telephony service.
Simple workarounds are applied on certain devices to gather extra cell data or to remove invalid info.

## Issues and pull requests
Feel free to open an issue for any question, suggestion or any actual issue (such as the app returning wrong cell data) that you might be facing with NetManager.
Pull requests are highly appreciated as long as they're tested.

## License
```
Copyright (C) 2025  DottoXD

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.
```
