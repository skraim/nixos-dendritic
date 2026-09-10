pragma Singleton

import Quickshell
import Quickshell.Io
import QtQml

Singleton {
    id: root

    readonly property var supportedLanguages: Settings.supportedLanguages
    readonly property string fallbackLanguage: "en"
    readonly property string language: Settings.normalizeLanguage(Settings.language)
    readonly property string translationsDir: Quickshell.shellDir + "/translations"
    readonly property string translationPath: translationsDir + "/" + language + ".json"
    readonly property string fallbackPath: translationsDir + "/" + fallbackLanguage + ".json"
    property var translations: ({})
    property var fallbackTranslations: ({})
    property int revision: 0

    onLanguageChanged: translationsFile.reload()

    FileView {
        id: translationsFile
        path: root.translationPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root._applyText(text())
        onLoadFailed: root._applyText("{}")
    }

    FileView {
        id: fallbackFile
        path: root.fallbackPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root._applyFallbackText(text())
        onLoadFailed: root._applyFallbackText("{}")
    }

    Component.onCompleted: {
        fallbackFile.reload()
        translationsFile.reload()
    }

    function t(key, fallback, values) {
        root.revision

        const found = _lookup(translations, key)
        const fallbackFound = _lookup(fallbackTranslations, key)
        const text = typeof found === "string"
            ? found
            : (typeof fallbackFound === "string"
                ? fallbackFound
                : (fallback !== undefined ? fallback : key))

        return values ? _format(text, values) : text
    }

    function has(key) {
        root.revision
        return typeof _lookup(translations, key) === "string"
            || typeof _lookup(fallbackTranslations, key) === "string"
    }

    function _applyText(text) {
        translations = _parseTranslations(text, translationPath)
        revision += 1
    }

    function _applyFallbackText(text) {
        fallbackTranslations = _parseTranslations(text, fallbackPath)
        revision += 1
    }

    function _parseTranslations(text, path) {
        try {
            const trimmed = String(text || "").trim()
            const parsed = trimmed.length > 0 ? JSON.parse(trimmed) : {}
            return parsed && typeof parsed === "object" && !Array.isArray(parsed) ? parsed : {}
        } catch (e) {
            console.warn("Localization.qml: failed to parse " + path + ":", e)
            return {}
        }
    }

    function _lookup(source, key) {
        if (!source || !key)
            return undefined

        const direct = source[key]
        if (direct !== undefined)
            return direct

        const parts = String(key).split(".")
        let current = source
        for (let i = 0; i < parts.length; i++) {
            if (!current || typeof current !== "object" || current[parts[i]] === undefined)
                return undefined
            current = current[parts[i]]
        }
        return current
    }

    function _format(text, values) {
        let formatted = text
        for (const name in values)
            formatted = formatted.split("{" + name + "}").join(String(values[name]))
        return formatted
    }
}
