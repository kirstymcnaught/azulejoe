import QtQuick 2.0

Rectangle {
    width: 600
    height: 400

   ScanningGridView {
        anchors.fill: parent
        model: testModel;

        id: gridView

        focus: true

        Keys.onSpacePressed: {
            gridView.next();
        }

        delegate: Item {
            anchors.fill: parent
            id: mainItem

            Rectangle {
                id: rect

                z:200

                height: parent.height*0.9
                width: parent.width*0.9
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                color: "red"
                opacity: 1

                Text {
                    anchors.fill: rect
                    text: modelData.name
                    font.pointSize: 32
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

        }
    }

    ListModel {
        id: testModel
        Component.onCompleted: {
            for (var i =0; i < 5; i++) {
                for (var j =0; j < 5; j++) {
                    testModel.append({ name: (i + ", " + j)})
                }
            }
        }
    }

}

