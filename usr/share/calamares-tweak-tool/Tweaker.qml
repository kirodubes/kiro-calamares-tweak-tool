import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: win
    visible: true
    title: "Calamares Tweak Tool"
    width: 720
    height: 560
    color: t.bgBottom

    // ── Kiro dark palette (shared with kiro-keybindings) ────────────────
    readonly property var t: ({
        bgTop: "#111C33", bgBottom: "#020617", cardBg: "#0C1B33", cardBorder: "#1E293B",
        title: "#ffffff", subtext: "#94A3B8", desc: "#E2E8F0",
        accentA: "#0195F7", accentB: "#2FC328", warn: "#F59E0B", danger: "#F87171"
    })
    readonly property bool isLuks2: backend.luksGeneration === "luks2"

    Component.onCompleted: {
        x = Math.round(Screen.width / 2 - width / 2)
        y = Math.round(Screen.height / 2 - height / 2)
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: win.t.bgTop }
            GradientStop { position: 1.0; color: win.t.bgBottom }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 18

            // ── Header ──────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 14
                Image { source: logoPath; sourceSize.height: 40; fillMode: Image.PreserveAspectFit }
                ColumnLayout {
                    spacing: 1
                    Text { text: "Calamares Tweak Tool"; color: win.t.title; font.pixelSize: 22; font.bold: true }
                    Text {
                        text: "encryption + bootloader · edits " + backend.configDir
                        color: win.t.subtext; font.pixelSize: 12
                    }
                }
                Item { Layout.fillWidth: true }
                Text { text: "dev / expert"; color: win.t.warn; font.pixelSize: 11; font.bold: true }
            }

            Rectangle {
                Layout.fillWidth: true; height: 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: win.t.accentA }
                    GradientStop { position: 1.0; color: win.t.accentB }
                }
            }

            // ── Missing-config banner ───────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                visible: !backend.configExists
                color: "#2A1113"; border.color: win.t.danger; border.width: 1; radius: 10
                implicitHeight: 44
                Text {
                    anchors.centerIn: parent
                    text: "No Calamares config found at " + backend.configDir + "  —  try --dev for the bundled sample"
                    color: win.t.danger; font.pixelSize: 13
                }
            }

            // ── Bootloader ──────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                color: win.t.cardBg; border.color: win.t.cardBorder; border.width: 1; radius: 14
                implicitHeight: blCol.implicitHeight + 32
                enabled: backend.configExists
                ColumnLayout {
                    id: blCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                    spacing: 10
                    Text { text: "BOOTLOADER"; color: win.t.accentA; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1.4 }
                    RowLayout {
                        spacing: 10
                        Repeater {
                            model: backend.bootloaders
                            delegate: RadioButton {
                                text: modelData
                                checked: backend.bootloader === modelData
                                onClicked: backend.setBootloader(modelData)
                                contentItem: Text {
                                    text: parent.text; color: win.t.desc; font.pixelSize: 15
                                    leftPadding: parent.indicator.width + 8; verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }
                }
            }

            // ── Encryption ──────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                color: win.t.cardBg; border.color: win.t.cardBorder; border.width: 1; radius: 14
                implicitHeight: 64
                enabled: backend.configExists
                RowLayout {
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 16 }
                    ColumnLayout {
                        spacing: 1
                        Text { text: "ENCRYPTION"; color: win.t.accentA; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1.4 }
                        Text { text: "show the “Encrypt system” option in the installer"; color: win.t.subtext; font.pixelSize: 12 }
                    }
                    Item { Layout.fillWidth: true }
                    Switch {
                        checked: backend.encryption
                        onToggled: backend.setEncryption(checked)
                    }
                }
            }

            // ── Derived LUKS readout (the guard, made visible) ──────────
            Rectangle {
                Layout.fillWidth: true
                radius: 14; border.width: 1
                color: win.isLuks2 ? "#0C2A14" : "#2A2410"
                border.color: win.isLuks2 ? win.t.accentB : win.t.warn
                implicitHeight: 70
                opacity: backend.encryption ? 1.0 : 0.5
                RowLayout {
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 16 }
                    spacing: 14
                    Text {
                        text: backend.luksGeneration.toUpperCase()
                        color: win.isLuks2 ? win.t.accentB : win.t.warn
                        font.pixelSize: 24; font.bold: true
                    }
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        color: win.t.desc; font.pixelSize: 13
                        text: win.isLuks2
                              ? "systemd-boot decrypts via the initramfs → LUKS2/Argon2id is safe and stronger."
                              : "GRUB can't unlock LUKS2/Argon2id → forced to LUKS1 so the system still boots."
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // ── Status ──────────────────────────────────────────────────
            Text {
                Layout.fillWidth: true
                text: backend.status
                color: win.t.subtext; font.pixelSize: 12
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                visible: backend.configExists && !backend.writable
                text: "Read-only: relaunch as root (e.g. sudo -E calamares-tweak-tool) to save changes."
                color: win.t.warn; font.pixelSize: 12
            }

            // ── Actions ─────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Button {
                    text: "Apply"
                    enabled: backend.configExists && backend.writable
                    onClicked: backend.apply()
                    Layout.preferredWidth: 120; Layout.preferredHeight: 42
                    contentItem: Text { text: parent.text; color: "#ffffff"; font.pixelSize: 15; font.bold: true
                                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { radius: 10; color: parent.enabled ? (parent.down ? "#0277C4" : win.t.accentA) : "#1E293B" }
                }
                Item { Layout.fillWidth: true }
                Button {
                    text: "Launch installer"
                    onClicked: backend.launchInstaller()
                    Layout.preferredWidth: 170; Layout.preferredHeight: 42
                    contentItem: Text { text: parent.text; color: win.t.desc; font.pixelSize: 15
                                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { radius: 10; color: "transparent"; border.color: win.t.cardBorder; border.width: 1 }
                }
            }
        }
    }

    Shortcut { sequence: "Escape"; onActivated: Qt.quit() }
}
