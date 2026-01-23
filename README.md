
# NetManager
A Material UI mobile network monitoring app built with ease-of-use and speed in mind.
Built from scratch with Flutter, NetManager plans to respect Material guidelines for user interfaces and possibly blend in with system applications.

## Supported platforms
NetManager currently has somewhat stable support for Android 10+ (SDK ver. 29) and experimental support for Android 8 and 9 (SDK ver. 26, 27 and 28). 
The app can be installed on Android 7 (SDK ver. 24 and 25), but it should be considered as unsupported as of now.
Experimental support for a companion Wear OS companion app is also available.
Support for older Android versions (Android 7+, SDK ver. 24) is planned before version 1.0.0.
iOS support is currently unplanned due to missing public APIs to reliably retrieve cell data.

## Data accuracy
NetManager does its best to provide accurate and up-to-date data by filtering out invalid cell info returned by Android's Telephony service.
Simple workarounds are applied on certain devices to gather extra cell data or to remove invalid info.

## Analytics
NetManager might collect anonymous analytic data (opt-in) such as crash dumps and error logs.
All data is non-linkable to user and is collected with the open source [Sentry Dart SDK](https://github.com/getsentry/sentry-dart) and stored on Bugsink, an EU managed open source Sentry alternative.

## Issues and pull requests
Feel free to open an issue for any question, suggestion or any actual issue (such as the app returning wrong cell data) that you might be facing with NetManager.
Pull requests are highly appreciated as long as they're tested.

## Builds
Development builds are available at [GitHub Actions](https://github.com/DottoXD/NetManager/actions).
Stable and pre-release builds are available in the [Releases](https://github.com/DottoXD/NetManager/actions) tab on GitHub.

## License
```
Copyright (C) 2025 - 2026 DottoXD

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.
```
