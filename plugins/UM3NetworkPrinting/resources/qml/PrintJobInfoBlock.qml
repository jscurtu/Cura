import QtQuick 2.2
import QtQuick.Dialogs 1.1
import QtQuick.Controls 2.0
import QtQuick.Controls.Styles 1.4
import QtGraphicalEffects 1.0

import UM 1.3 as UM


Item
{
    id: base
    property var printJob: null
    property var shadowRadius: 5 * screenScaleFactor
    function getPrettyTime(time)
    {
        return OutputDevice.formatDuration(time)
    }

    width: parent.width

    UM.I18nCatalog
    {
        id: catalog
        name: "cura"
    }

    Rectangle
    {
        id: background
        anchors
        {
            top: parent.top
            topMargin: 3 * screenScaleFactor
            left: parent.left
            leftMargin: base.shadowRadius
            rightMargin: base.shadowRadius
            right: parent.right
            bottom: parent.bottom
            bottomMargin: base.shadowRadius
        }

        layer.enabled: true
        layer.effect: DropShadow
        {
            radius: base.shadowRadius
            verticalOffset: 2 * screenScaleFactor
            color: "#3F000000"  // 25% shadow
        }

        Item
        {
            // Content on the left of the infobox
            anchors
            {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                right: parent.horizontalCenter
                margins: UM.Theme.getSize("wide_margin").width
                rightMargin: UM.Theme.getSize("default_margin").width
            }

            Label
            {
                id: printJobName
                text: printJob.name
                font: UM.Theme.getFont("default_bold")
                width: parent.width
                elide: Text.ElideRight
            }

            Label
            {
                id: ownerName
                anchors.top: printJobName.bottom
                text: printJob.owner
                font: UM.Theme.getFont("default")
                opacity: 0.6
                width: parent.width
                elide: Text.ElideRight
            }

            Image
            {
                id: printJobPreview
                source: printJob.previewImageUrl
                anchors.top: ownerName.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: totalTimeLabel.bottom
                width: height
                opacity: printJob.state == "error" ? 0.5 : 1.0
            }

            UM.RecolorImage
            {
                id: statusImage
                anchors.centerIn: printJobPreview
                source: printJob.state == "error" ? "../svg/aborted-icon.svg" : ""
                visible: source != ""
                width: 0.5 * printJobPreview.width
                height: 0.5 * printJobPreview.height
                sourceSize.width: width
                sourceSize.height: height
                color: "black"
            }

            Label
            {
                id: totalTimeLabel
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                font: UM.Theme.getFont("default")
                text: printJob != null ? getPrettyTime(printJob.timeTotal) : ""
                elide: Text.ElideRight
            }
        }

        Item
        {
            // Content on the right side of the infobox.
            anchors
            {
                top: parent.top
                bottom: parent.bottom
                left: parent.horizontalCenter
                right: parent.right
                margins: 2 * UM.Theme.getSize("default_margin").width
                leftMargin: UM.Theme.getSize("default_margin").width
                rightMargin: UM.Theme.getSize("default_margin").width / 2
            }

            Label
            {
                id: targetPrinterLabel
                elide: Text.ElideRight
                font: UM.Theme.getFont("default_bold")
                text:
                {
                    if(printJob.assignedPrinter == null)
                    {
                        if(printJob.state == "error")
                        {
                            return catalog.i18nc("@label", "Waiting for: Unavailable printer")
                        }
                        return catalog.i18nc("@label", "Waiting for: First available")
                    }
                    else
                    {
                        return catalog.i18nc("@label", "Waiting for: ") + printJob.assignedPrinter.name
                    }

                }

                anchors
                {
                    left: parent.left
                    right: contextButton.left
                    rightMargin: UM.Theme.getSize("default_margin").width
                }
            }


            function switchPopupState()
            {
                popup.visible ? popup.close() : popup.open()
            }

            Button
            {
                id: contextButton
                text: "\u22EE" //Unicode; Three stacked points.
                width: 35
                height: width
                anchors
                {
                    right: parent.right
                    top: parent.top
                }
                hoverEnabled: true

                background: Rectangle
                {
                    opacity: contextButton.down || contextButton.hovered ? 1 : 0
                    width: contextButton.width
                    height: contextButton.height
                    radius: 0.5 * width
                    color: UM.Theme.getColor("viewport_background")
                }
                contentItem: Label
                {
                    text: contextButton.text
                    color: UM.Theme.getColor("monitor_text_inactive")
                    font.pixelSize: 25
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }

                onClicked: parent.switchPopupState()
            }

            Popup
            {
                // TODO Change once updating to Qt5.10 - The 'opened' property is in 5.10 but the behavior is now implemented with the visible property
                id: popup
                clip: true
                closePolicy: Popup.CloseOnPressOutside
                x: (parent.width - width) + 26 * screenScaleFactor
                y: contextButton.height - 5 * screenScaleFactor // Because shadow
                width: 182 * screenScaleFactor
                height: contentItem.height + 2 * padding
                visible: false
                padding: 5 * screenScaleFactor // Because shadow

                transformOrigin: Popup.Top
                contentItem: Item
                {
                    width: popup.width
                    height: childrenRect.height + 36 * screenScaleFactor
                    anchors.topMargin: 10 * screenScaleFactor
                    anchors.bottomMargin: 10 * screenScaleFactor
                    Button
                    {
                        id: sendToTopButton
                        text: catalog.i18nc("@label", "Move to top")
                        onClicked:
                        {
                            sendToTopConfirmationDialog.visible = true;
                            popup.close();
                        }
                        width: parent.width
                        enabled: OutputDevice.queuedPrintJobs[0].key != printJob.key
                        visible: enabled
                        anchors.top: parent.top
                        anchors.topMargin: 18 * screenScaleFactor
                        height: visible ? 39 * screenScaleFactor : 0 * screenScaleFactor
                        hoverEnabled: true
                        background: Rectangle
                        {
                            opacity: sendToTopButton.down || sendToTopButton.hovered ? 1 : 0
                            color: UM.Theme.getColor("viewport_background")
                        }
                        contentItem: Label
                        {
                            text: sendToTopButton.text
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    MessageDialog
                    {
                        id: sendToTopConfirmationDialog
                        title: catalog.i18nc("@window:title", "Move print job to top")
                        icon: StandardIcon.Warning
                        text: catalog.i18nc("@label %1 is the name of a print job.", "Are you sure you want to move %1 to the top of the queue?").arg(printJob.name)
                        standardButtons: StandardButton.Yes | StandardButton.No
                        Component.onCompleted: visible = false
                        onYes: OutputDevice.sendJobToTop(printJob.key)
                    }

                    Button
                    {
                        id: deleteButton
                        text: catalog.i18nc("@label", "Delete")
                        onClicked:
                        {
                            deleteConfirmationDialog.visible = true;
                            popup.close();
                        }
                        width: parent.width
                        height: 39 * screenScaleFactor
                        anchors.top: sendToTopButton.bottom
                        hoverEnabled: true
                        background: Rectangle
                        {
                            opacity: deleteButton.down || deleteButton.hovered ? 1 : 0
                            color: UM.Theme.getColor("viewport_background")
                        }
                        contentItem: Label
                        {
                            text: deleteButton.text
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    MessageDialog
                    {
                        id: deleteConfirmationDialog
                        title: catalog.i18nc("@window:title", "Delete print job")
                        icon: StandardIcon.Warning
                        text: catalog.i18nc("@label %1 is the name of a print job.", "Are you sure you want to delete %1?").arg(printJob.name)
                        standardButtons: StandardButton.Yes | StandardButton.No
                        Component.onCompleted: visible = false
                        onYes: OutputDevice.deleteJobFromQueue(printJob.key)
                    }
                }

                background: Item
                {
                    width: popup.width
                    height: popup.height

                    DropShadow
                    {
                        anchors.fill: pointedRectangle
                        radius: 5
                        color: "#3F000000"  // 25% shadow
                        source: pointedRectangle
                        transparentBorder: true
                        verticalOffset: 2
                    }

                    Item
                    {
                        id: pointedRectangle
                        width: parent.width - 10 * screenScaleFactor // Because of the shadow
                        height: parent.height - 10 * screenScaleFactor // Because of the shadow
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle
                        {
                            id: point
                            height: 14 * screenScaleFactor
                            width: 14 * screenScaleFactor
                            color: UM.Theme.getColor("setting_control")
                            transform: Rotation { angle: 45}
                            anchors.right: bloop.right
                            anchors.rightMargin: 24
                            y: 1
                        }

                        Rectangle
                        {
                            id: bloop
                            color: UM.Theme.getColor("setting_control")
                            width: parent.width
                            anchors.top: parent.top
                            anchors.topMargin: 8 * screenScaleFactor // Because of the shadow + point
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 8 * screenScaleFactor // Because of the shadow
                        }
                    }
                }

                exit: Transition
                {
                    // This applies a default NumberAnimation to any changes a state change makes to x or y properties
                    NumberAnimation { property: "visible"; duration: 75; }
                }
                enter: Transition
                {
                    // This applies a default NumberAnimation to any changes a state change makes to x or y properties
                    NumberAnimation { property: "visible"; duration: 75; }
                }

                onClosed: visible = false
                onOpened: visible = true
            }

            Row
            {
                id: printerFamilyPills
                spacing: 0.5 * UM.Theme.getSize("default_margin").width
                anchors
                {
                    left: parent.left
                    right: parent.right
                    bottom: extrudersInfo.top
                    bottomMargin: UM.Theme.getSize("default_margin").height
                }
                height: childrenRect.height
                Repeater
                {
                    model: printJob.compatibleMachineFamilies

                    delegate: PrinterFamilyPill
                    {
                        text: modelData
                        color: UM.Theme.getColor("viewport_background")
                        padding: 3 * screenScaleFactor
                    }
                }
            }
            // PrintCore && Material config
            Row
            {
                id: extrudersInfo
                anchors.bottom: parent.bottom

                anchors
                {
                    left: parent.left
                    right: parent.right
                }
                height: childrenRect.height

                spacing: UM.Theme.getSize("default_margin").width

                PrintCoreConfiguration
                {
                    id: leftExtruderInfo
                    width: Math.round(parent.width / 2) * screenScaleFactor
                    printCoreConfiguration: printJob.configuration.extruderConfigurations[0]
                }

                PrintCoreConfiguration
                {
                    id: rightExtruderInfo
                    width: Math.round(parent.width / 2) * screenScaleFactor
                    printCoreConfiguration: printJob.configuration.extruderConfigurations[1]
                }
            }

        }

        Rectangle
        {
            color: UM.Theme.getColor("viewport_background")
            width: 2 * screenScaleFactor
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: UM.Theme.getSize("default_margin").height
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}