import QtQuick 2.14
import QtQuick.Window 2.14
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import PageEnum 1.0
import Qt.labs.platform 1.1
import Qt.labs.folderlistmodel 2.12
import QtQuick.Dialogs 1.1
import "./"
import "Pages"
import "Pages/Protocols"
import "Config"

Window  {
    property var pages: ({})
    property var protocolPages: ({})

    id: root
    visible: true
    width: GC.screenWidth
    height: GC.isDesktop() ? GC.screenHeight + titleBar.height : GC.screenHeight
    Keys.enabled: true
    onClosing: {
        console.debug("QML onClosing signal")
        UiLogic.onCloseWindow()
    }

    //flags: Qt.FramelessWindowHint
    title: "AmneziaVPN"

    function gotoPage(page, reset, slide) {
        if (reset) {
            if (page === PageEnum.ServerSettings) {
                ServerSettingsLogic.onUpdatePage();
            }
            if (page === PageEnum.ShareConnection) {
            }
            if (page === PageEnum.Wizard) {
                WizardLogic.radioButtonMediumChecked = true
            }
            if (page === PageEnum.WizardHigh) {
                WizardLogic.onUpdatePage();
            }
            if (page === PageEnum.ServerConfiguringProgress) {
                ServerConfiguringProgressLogic.progressBarValue = 0;
            }
            if (page === PageEnum.GeneralSettings) {
                GeneralSettingsLogic.onUpdatePage();
            }
            if (page === PageEnum.ServersList) {
                ServerListLogic.onUpdatePage();
            }
            if (page === PageEnum.Start) {
                StartPageLogic.pushButtonBackFromStartVisible = !pageLoader.empty
                StartPageLogic.onUpdatePage();
            }
            if (page === PageEnum.NewServerProtocols) {
                NewServerProtocolsLogic.onUpdatePage()
            }
            if (page === PageEnum.ServerContainers) {
                ServerContainersLogic.onUpdatePage()
            }
            if (page === PageEnum.AppSettings) {
                AppSettingsLogic.onUpdatePage()
            }
            if (page === PageEnum.NetworkSettings) {
                NetworkSettingsLogic.onUpdatePage()
            }
            if (page === PageEnum.Sites) {
                SitesLogic.updateSitesPage()
            }
            if (page === PageEnum.Vpn) {
                VpnLogic.updateVpnPage()
            }
        }

        if (slide) {
            pageLoader.push(pages[page], {}, StackView.PushTransition)
        } else {
            pageLoader.push(pages[page], {}, StackView.Immediate)
        }

        pages[page].activated(reset)
    }

    function gotoProtocolPage(protocol, reset, slide) {
        if (reset && protocolPages[protocol] !== "undefined") {
            protocolPages[protocol].logic.onUpdatePage();
        }

        if (slide) {
            pageLoader.push(protocolPages[protocol], {}, StackView.PushTransition)
        } else {
            pageLoader.push(protocolPages[protocol], {}, StackView.Immediate)
        }

        protocolPages[protocol].activated(reset)
    }

    function close_page() {
        if (pageLoader.depth <= 1) {
            return
        }
        pageLoader.pop()
    }

    function set_start_page(page, slide) {
        pageLoader.clear()
        if (slide) {
            pageLoader.push(pages[page], {}, StackView.PushTransition)
        } else {
            pageLoader.push(pages[page], {}, StackView.Immediate)
        }
        if (page === PageEnum.Start) {
            UiLogic.pushButtonBackFromStartVisible = !pageLoader.empty
            UiLogic.onUpdatePage();
        }
    }

    TitleBar {
        id: titleBar
        anchors.top: root.top
        visible: GC.isDesktop()
        DragHandler {
            grabPermissions: TapHandler.CanTakeOverFromAnything
            onActiveChanged: {
                if (active) {
                    root.startSystemMove();
                }
            }
            target: null
        }
        onCloseButtonClicked: {
            if (UiLogic.currentPageValue === PageEnum.Start ||
                    UiLogic.currentPageValue === PageEnum.NewServer) {
                Qt.quit()
            } else {
                root.hide()
            }
        }
    }

    Rectangle {
        y: GC.isDesktop() ? titleBar.height : 0
        anchors.fill: parent
        color: "white"
    }

    StackView {
        id: pageLoader
        y: GC.isDesktop() ? titleBar.height : 0
        anchors.fill: parent
        focus: true

//        initialItem: page_servers
        onCurrentItemChanged: {
            console.debug("QML onCurrentItemChanged " + pageLoader.currentItem)
            UiLogic.currentPageValue = currentItem.page
        }

//        Keys.onReleased: {
//            if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape) {
//                console.debug("Back button captured")
//                if (UiLogic.currentPageValue !== PageEnum.VPN &&
//                        UiLogic.currentPageValue !== PageEnum.ServerConfiguring &&
//                        !(UiLogic.currentPageValue === PageEnum.Start && pageLoader.depth < 2)) {
//                    close_page();
//                }


//                // TODO: fix
//                //if (ui->stackedWidget_main->currentWidget()->isEnabled()) {
//                //    closePage();
//                //}

//                event.accepted = true
//            }
//        }

        Keys.onPressed: {
            UiLogic.keyPressEvent(event.key)
        }

    }

    FolderListModel {
        id: folderModelPages
        folder: "qrc:/ui/qml/Pages/"
        nameFilters: ["*.qml"]
        showDirs: false

        onStatusChanged: if (status == FolderListModel.Ready) {
                             for (var i=0; i<folderModelPages.count; i++) {
                                 createPagesObjects(folderModelPages.get(i, "filePath"), false);
                             }
                             UiLogic.initalizeUiLogic()
                         }
    }

    FolderListModel {
        id: folderModelProtocols
        folder: "qrc:/ui/qml/Pages/Protocols/"
        nameFilters: ["*.qml"]
        showDirs: false

        onStatusChanged: if (status == FolderListModel.Ready) {
                             for (var i=0; i<folderModelProtocols.count; i++) {
                                 createPagesObjects(folderModelProtocols.get(i, "filePath"), true);
                             }
        }
    }

    function createPagesObjects(file, isProtocol) {
        if (file.indexOf("Base") !== -1) return; // skip Base Pages

        var c = Qt.createComponent("qrc" + file);

        var finishCreation = function (component){
            if (component.status == Component.Ready) {
                var obj = component.createObject(root);
                if (obj == null) {
                    console.debug("Error creating object " + component.url);
                }
                else {
                    obj.visible = false
                    if (isProtocol) {
                        protocolPages[obj.protocol] = obj
                    }
                    else {
                        pages[obj.page] = obj
                    }



                }
            } else if (component.status == Component.Error) {
                console.debug("Error loading component:", component.errorString());
            }
        }

        if (c.status == Component.Ready)
            finishCreation(c);
        else {
            console.debug("Warning: Pages components are not ready");
        }
    }

    Connections {
        target: UiLogic
        function onGoToPage(page, reset, slide) {
            console.debug("Connections onGoToPage " + page);
            root.gotoPage(page, reset, slide)
        }
        function onGoToProtocolPage(protocol, reset, slide) {
            console.debug("Connections onGoToProtocolPage " + protocol);
            root.gotoProtocolPage(protocol, reset, slide)
        }
        function onClosePage() {
            root.close_page()
        }
        function onSetStartPage(page, slide) {
            root.set_start_page(page, slide)
        }
        function onShowPublicKeyWarning() {
            publicKeyWarning.visible = true
        }
        function onShowConnectErrorDialog() {
            connectErrorDialog.visible = true
        }
        function onShow() {
            root.show()
        }
        function onHide() {
            root.hide()
        }
    }

    MessageDialog {
        id: closePrompt
//        x: (root.width - width) / 2
//        y: (root.height - height) / 2
        title: qsTr("Exit")
        text: qsTr("Do you really want to quit?")
        standardButtons: StandardButton.Yes | StandardButton.No
        onYes: {
            Qt.quit()
        }
        visible: false
    }
    SystemTrayIcon {
        visible: true
        icon.source: UiLogic.trayIconUrl
        onActivated: {
            if (Qt.platform.os == "osx" ||
                    Qt.platform.os == "linux") {
                if (reason === SystemTrayIcon.DoubleClick ||
                        reason === SystemTrayIcon.Trigger) {
                    root.show()
                    root.raise()
                    root.requestActivate()
                }
            }
        }

        menu: Menu {
            MenuItem {
                iconSource: "qrc:/images/tray/application.png"
                text: qsTr("Show") + " " + "AmneziaVPN"
                onTriggered: {
                    root.show()
                    root.raise()
                }
            }
            MenuSeparator { }
            MenuItem {
                text: qsTr("Connect")
                enabled: UiLogic.trayActionConnectEnabled
                onTriggered: {
                    UiLogic.onConnect()
                }
            }
            MenuItem {
                text: qsTr("Disconnect")
                enabled: UiLogic.trayActionDisconnectEnabled
                onTriggered: {
                    UiLogic.onDisconnect()
                }
            }
            MenuSeparator { }
            MenuItem {
                iconSource: "qrc:/images/tray/link.png"
                text: qsTr("Visit Website")
                onTriggered: {
                    Qt.openUrlExternally("https://amnezia.org")
                }
            }
            MenuItem {
                iconSource: "qrc:/images/tray/cancel.png"
                text: qsTr("Quit") + " " + "AmneziaVPN"
                onTriggered: {
                    closePrompt.open()
                }
            }
        }
    }
    MessageDialog {
        id: publicKeyWarning
        title: "AmneziaVPN"
        text: qsTr("It's public key. Private key required")
        visible: false
    }
    MessageDialog {
        id: connectErrorDialog
        title: "AmneziaVPN"
        text: UiLogic.dialogConnectErrorText
        visible: false
    }
}
