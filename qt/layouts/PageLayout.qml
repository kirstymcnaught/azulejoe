import QtQuick 2.0

import "qrc:/JsLoader.js" as JsLoader

import ".."

Item {
    //anchors.fill: parent

    // The page name, e.g. "food".
    // Must correspond to the function called to populate the
    // data, e.g. food().
    property string page: ""

    Item {
        id: document
        anchors.fill: parent

        z: 100

        // Without this alias, JS gives a TypeError.
        property alias main: main
        Image {
            id: main

            // This alias is to match the web conventions.
            property alias src: main.source

            anchors.fill: parent
        }
    }

    // These need to have file-level scope so our external script can
    // write to them.
    property variant utterances: {}
    property variant links: {}

    // The gridview of mouseareas
    ScanningGridView {
        id: gridView
        z: 101

        anchors.fill: parent

        numCols: 5
        numRows: 5

        focus: true
        Keys.onSpacePressed: {
            console.log("space");
            gridView.next();
        }

        onClicked: {
            var utterance = utterances[col][row];
            var link = links[col][row];
            clickCell(utterance, link);
        }

        delegate: Item {
            //z: 1000
            anchors.fill: parent

            MouseArea {
                    id: mouseArea
                    z: 500
                width: parent.width*0.95
                height: parent.width*0.95
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    clickCell(modelData.utterance, modelData.link);
                 }
            }
            Rectangle {
                width: parent.width*0.9
                height: parent.width*0.9
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                color: "grey"
                opacity: 0.2
                visible: mouseArea.pressedButtons
            }            
        }

        model: pageSet

        // Without this, child pages don't get focus.
        Component.onCompleted: forceActiveFocus()
    }


    // Create a pageset model from JS file.
    ListModel {
        id: pageSet

        Component.onCompleted: {
            JsLoader.loadResource("qrc:/" + page + ".js")

            utterances = new2dArray(5);
            links = new2dArray(5);

            // TODO: Don't use the evil eval.
            eval("JsLoader." + page + "()");

            for (var i=0; i < 5; i++) {
                for (var j=0; j < 5; j++) {
                    pageSet.append({ link: links[j][i],
                                       utterance: utterances[j][i] })
                }
            }
        }
    }

    function clickCell(utterance, link) {
        if (utterance.length > 0) {
            // If we've got a single letter, we're spelling a word
            // and don't want to add a space
            if (utterance.length === 1) {
                app.appendWord(qsTr(utterance))
            }
            else {
                app.appendWord(" " + qsTr(utterance))
            }
        }

        if (link.trim().length > 0) {
            var cmd = link.trim();
            switch (cmd) {
            case "clear":
                app.resetText();
                break;
            case "deleteword":
                app.deleteWord();
                break;
            case "Backspace":
                app.backspace();
                break;
            case "speak":
                TTSClient.speak(app.text);
                break;
            case "1":
                stackView.pop();
                break;
            case "google":
                googlesearch();
                break;
            case "youtube":
                youtubesearch();
                break;
            case "twitter":
                tweet();break;
            default:
                stackView.push({ item: "qrc:/layouts/PageLayout.qml",
                                   replace: true ,
                                   properties: { page: cmd , focus: true} });
            }
        }
    }

    function new2dArray(size)
    {
        var temp = new Array(size);
        for (var i = 0; i < size; i++) {
            temp[i] = new Array(size);
        }
        return temp;
    }

    function reset() {
        var i,j
        for(j=0;j<5;j++)
        {
            for(i=0;i<5;i++)
            {
                utterances[i][j]="";
                links[i][j]="";
            }
        }
        links[3][0]="speak";
    }

    function googlesearch() {
        var words = app.getWords();
        var url = "http://www.google.co.uk/images?q="
                + words.join("+");
        Qt.openUrlExternally(url);

    }
    function youtubesearch() {
        var words = app.getWords();
        var url = "http://www.youtube.com/results?search_query="
                + words.join("+") +"&search_type=&aq=0";
        Qt.openUrlExternally(url);
    }
    function tweet() {
        var words = app.getWords();
        var twtTitle=words.join(" ");
        var maxLength = 140;
        if(twtTitle.length > maxLength)
        {
            twtTitle = twtTitle.substr(0, (maxLength -3))+'...';
        }
        var url ='http://twitter.com/home?status='+twtTitle.replace(" ", "%20");
        Qt.openUrlExternally(url);
    }

}


