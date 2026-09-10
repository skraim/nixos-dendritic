pragma Singleton

import "root:/functions/fuzzysort.js" as Fuzzy
import Quickshell
import Quickshell.Io
import qs.services

/**
 * - Eases fuzzy searching for applications by name
 * - Guesses icon name for window class name
 */
Singleton {
    id: root
    property real scoreThreshold: 0.2
    property var assetFiles: ({})  // lowercase basename → file:// URL

    Process {
        id: assetListProc
        running: true
        command: ["find", Quickshell.shellDir + "/assets", "-maxdepth", "1", "-name", "*.svg", "-printf", "%f\\n"]
        property var _buf: ({})
        stdout: SplitParser {
            onRead: data => {
                const base = data.trim();
                if (base) {
                    const key = base.replace(/\.svg$/i, "").toLowerCase();
                    assetListProc._buf[key] = "file://" + Quickshell.shellDir + "/assets/" + base;
                }
            }
        }
        onExited: {
            root.assetFiles = _buf;
        }
    }

    readonly property list<DesktopEntry> list: Array.from(DesktopEntries.applications.values).sort((a, b) => a.name.localeCompare(b.name))

    readonly property var preppedNames: list.map(a => ({
                name: Fuzzy.prepare(`${a.name} `),
                entry: a
            }))

    readonly property var preppedIcons: list.map(a => ({
                name: Fuzzy.prepare(`${a.icon} `),
                entry: a
            }))

    function fuzzyQuery(search: string): var { // Idk why list<DesktopEntry> doesn't work
        return Fuzzy.go(search, preppedNames, {
            all: true,
            key: "name"
        }).map(r => {
            return r.obj.entry;
        });
    }

    function iconExists(iconName) {
        if (!iconName || iconName.length == 0)
            return false;
        return (Quickshell.iconPath(iconName, true).length > 0) && !iconName.includes("image-missing");
    }

    function getReverseDomainNameAppName(str) {
        return str.split('.').slice(-1)[0].toLowerCase();
    }

    function getKebabNormalizedAppName(str) {
        return str.toLowerCase().replace(/\s+/g, "-");
    }

    function guessIcon(str) {
        if (!str || str.length == 0)
            return "image-missing";

        // app_icons overrides take highest priority
        const override = Settings.appIcons[str] || Settings.appIcons[str.toLowerCase()];
        if (override) {
            if (override.startsWith("file://"))
                return override;
            if (override.startsWith("/"))
                return "file://" + override;
            if (iconExists(override))
                return override;
            const resolved = "file://" + Quickshell.shellDir + "/" + override;
            return resolved;
        }

        // Icon exists -> return as is
        if (iconExists(str))
            return str;

        // Simple guesses
        const reverseDomainNameAppName = getReverseDomainNameAppName(str);
        if (iconExists(reverseDomainNameAppName))
            return reverseDomainNameAppName;

        const kebabNormalizedGuess = getKebabNormalizedAppName(str);
        if (iconExists(kebabNormalizedGuess))
            return kebabNormalizedGuess;

        // Search in desktop entries
        const iconSearchResults = Fuzzy.go(str, preppedIcons, {
            all: true,
            key: "name"
        }).map(r => {
            return r.obj.entry;
        });
        if (iconSearchResults.length > 0) {
            const guess = iconSearchResults[0].icon;
            if (iconExists(guess))
                return guess;
        }

        const nameSearchResults = root.fuzzyQuery(str);
        if (nameSearchResults.length > 0) {
            const guess = nameSearchResults[0].icon;
            if (iconExists(guess))
                return guess;
        }

        // Assets folder fallback
        const assetPath = root.assetFiles[str.toLowerCase()];
        if (assetPath) {
            return assetPath;
        }

        return str;
    }
}
