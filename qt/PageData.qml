import QtQuick 2.0

import "qrc:/JsLoader.js" as JsLoader
import com.azulejoe 1.0 // for c++ types registered in main.cpp

Item {

    id: topItem

    property var utterances;
    property var links;
    property alias imageSource : main.src;

    // This is a bit of a hack: The JS pagesets hardcode
    // "document.main.src" as the destination for the background
    // image. We mimic that here so that it still works.
    Item {
        id: document
        anchors.fill: parent

        // Without this alias, JS gives a TypeError.
        property alias main: main
        Item {
            id: main
            property string src;
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
        var i,j;
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

    function loadFileFromJs(inputFile, inputFunction) {
        var success = JsLoader.loadResource(inputFile);
        if (success) {
            utterances = new2dArray(5);
            links = new2dArray(5);

            // TODO: Don't use the evil eval.
            eval("JsLoader." + inputFunction + "()");


            console.log("main.src:");
            console.log(main.src);
            for (var i=0; i < 5; i++) {
                for (var j=0; j < 5; j++) {
                    model.append({ link: links[j][i],
                                     utterance: utterances[j][i] })
                }
            }
        }
        return success;
    }

    // Return a string comprised of n spaces.
    function spaces(n) {
        var s = "";
        for (var i=0; i < n; i++) {
            s+=" ";
        }
        return s;
    }

    // For a JSON object, print to the console all the
    // entries. Nested objects get indented according to
    // level.
    function logJsonRecursive(obj, level) {
        if (typeof level === 'undefined') {
            level = 0;
        }
        for (var prop in obj) {
            var val = obj[prop];
            console.log(spaces(level*2) + "Key:" + prop);
            console.log(spaces(level*2) + "Value:" + val);
            if (typeof val === 'object') {
                logJsonRecursive(val, level+1);
            }
        }
    }

    function toHex( decString ) {
      return  ("0"+(Number(decString).toString(16))).slice(-2).toUpperCase()
    }

    // Convert from OBF RGB values to QML equivalents:
    // rgb(x, y, z) -> #RRGGBB
    // rgba(x, y, z, a) -> #AARRGGBB
    // QML numbers are in hex, OBF are decimal.
    function parseObfRgb( obfString, defaultColor ) {

        if (typeof obfString === 'undefined') {
            return defaultColor
        }
        if (typeof defaultColor === 'undefined') {
          defaultColor = "#000000"
        }

        // Strip out all whitespace
        obfString = obfString.replace(/ /g,'');

        // Extract numbers, either RGB or RGBA
        var regExp = /rgba?\((\d*),(\d*),(\d*),?([\d.]*)?\)/i
        var match = regExp.exec(obfString);
        if (match == null) {
            console.log("Cannot parse colour "+obfString)
            return defaultColor
        }

        // Check all captured values are in range
        // Start at 1 since 0 is whole matching string.
        for (var i = 1; i < match.length; i++) {
            if (match[i] > 255 || match[i] < 0 ) {
                console.log("Cannot parse colour "+obfString)
                return defaultColor
            }
        }

        // Extract colors, in hex
        var r = toHex(match[1]);
        var g = toHex(match[2]);
        var b = toHex(match[3]);
        var a = null;
        if (match.length > 4 && typeof match[4] != 'undefined') {
            a = toHex(Math.floor(parseFloat(match[4]*255)));
        }

        // Create new string
        var qmlString = "#";
        if (a != null) {
            qmlString += a;
        }

        qmlString += r + g + b
        return qmlString
    }


    FileUtils {
        id:fileUtils
    }

    // Make sure images in manifest are proper file references.
    function fixupImagePaths(image_map, top_dir) {
      for (var image_name in image_map) {
        var image_path = image_map[image_name];
        image_map[image_name] = "file:/" + fileUtils.fullFile(top_dir, image_path);

      }
      return image_map;
    }

    // In the manifest.JSON, images are presented as a simple map, e.g.:
    // "images": {
    //   "af4183ed5": "images/im_af4183ed5.png",
    //   "06f83586a": "images/im_06f83586a.png",
    //   "6da965ab4": "images/im_6da965ab4.png",
    //  }
    // In individual page files with embedded images, we have a list instead:
    // "images": [
    //  {
    //    "id": 1,
    //    "data": "data:image/png;base64,iVBORw0KG...."
    //  }
    // {
    //    "id": 2,
    //    "data": "data:image/png;base64,dbH5s0if...."
    //  }
    // ]
    // This function converts the latter to:
    //  {
    //   "1": "data:image/png;base64,iVBORw0KG....",
    //   "2": "data:image/png;base64,dbH5s0if...."
    //  }
    function convertImageArrayToMap(image_array, top_dir) {
      var n = image_array.length;
      var map = {};
      for (var i = 0; i < n; i++) {
        var im = image_array[i];

        // According to OBF spec, references should be used in this order:
        // 1 - data
        // 2 - path
        // 3 - url
        // 4 - symbol.
        // Currently we support 1-3, but not 4.
        if (typeof im["data"] !== 'undefined') {
           map[im["id"]]  = im["data"];
        }
        else if (typeof im["path"] !== 'undefined') {
          map[im["id"]]  =  "file:/" + fileUtils.fullFile(top_dir, im["path"]);
        }
        else if (typeof im["url"] !== 'undefined') {
            map[im["id"]]  = im["url"];
        }
        else if (typeof im["symbol"] !== 'undefined') {
            map[im["id"]]  = im["symbol"];
        }
        else {
          console.log("No data found for image "+im["id"]);
        }
      }
      return map;
    }

    // Looks for an image reference first as an ID into a map.
    // Checks local map first, then global map.
    // If no matching id found, interprets as a file reference
    // or URL
    function findImage(id, local_map, global_map, top_dir) {
      var image_path

      if (typeof id === "undefined") {
        return image_path
      }

      // Look in local map
      if (typeof local_map !== "undefined") {
        image_path = local_map[id];
      }

      // Look in global map
      if (typeof image_path === "undefined" &&
          typeof global_map !== "undefined") {
        image_path = global_map[id];
      }

      return image_path;
    }

    function extractButtonInfo(button, topDir,
                               image_paths_local,
                               image_paths_global){
        var id = button["id"]
        var label = button["label"]
        // utterance is 'vocalization', if defined, otherwise
        // defaults to 'label', unless it's a link.
        var utterance = button["vocalization"]
        var link = ""
        var loadBoard = button["load_board"]
        if (loadBoard !== undefined) {
            link = loadBoard["path"]
        }
        else if (utterance === undefined){
            utterance = label
        }
        var bg_color = button["background_color"]
        bg_color = parseObfRgb(bg_color, "white")

        var border_color = button["border_color"]
        border_color = parseObfRgb(border_color, "black")

        var image_id = button["image_id"]
        var image_path = findImage(image_id, image_paths_local,
                                    image_paths_global, topDir);

        var action = button["action"];
        return { id: id,
                 link: link,
                 label: label,
                 utterance: utterance,
                 image_path: image_path,
                 bg_color: bg_color,
                 border_color: border_color,
                 action: action};
    }

    function findIn2dArray(array, item) {
        var l1 = array.length;
        var countPrevRows = 0;
        for(var i=0; i<l1; i++){
            var pos = array[i].indexOf(item);
            if(pos !== -1){
                return countPrevRows + pos;
            }
            // Keep track of size of prev rows
            // (may not all be the same)
            countPrevRows += array[i].length;
        }
        return -1;
    }

    // manifestFile = full url to manifest which describes the whole file
    // page = page name, or empty string for root page.
    function loadFileFromObf(topDir, page) {

        // Read manifest file for mappings/default page
        var manifestFile = fileUtils.fullFile(topDir, "manifest.json");
        if (!fileUtils.exists(manifestFile)) {
            console.log("Cannot find file " + manifestFile);
            return null;
        }

        var fileContent = fileUtils.read(manifestFile);
        var manifestObj = JSON.parse(fileContent);
        var image_paths = manifestObj["paths"]["images"];        
        image_paths = fixupImagePaths(image_paths, topDir);

        var board_paths = manifestObj["paths"]["boards"];

        // Default to root page if none requested
        if (page === "") {
            page = manifestObj["root"];
        }

        // Read requested page
        var pageFile = fileUtils.fullFile(topDir, page);

        if (!fileUtils.exists(pageFile)) {
            console.log("Cannot find file " + pageFile);
            return null;
        }

        fileContent = fileUtils.read(pageFile);
        var obj = JSON.parse(fileContent);

        // Pre-fill the model with the correct number of items for the
        // grid. This is necessary since we might not read them in correct
        // order
        var grid = obj["grid"];
        var grid_rows = grid["rows"];
        var grid_cols = grid["columns"];
        var max_items = grid_cols*grid_rows;
        var button_order = grid["order"];

        for (var i = 0; i < max_items; i++) {
            // This model will be used for any empty buttons.
            model.append({ link: "",
                           label: "",
                           utterance: "",
                           image_path: "",
                           bg_color: "white",
                           border_color: "grey",
                           action: ""
                         });
        }

        // Images may be defined in the manifest OR in the individual file.
        // We should look in both places
        if (typeof obj["images"] !== 'undefined') {
          image_paths = convertImageArrayToMap(obj["images"], topDir);
        }

        var image_paths_file;
        if (typeof obj["images"] !== 'undefined') {
            image_paths_file = convertImageArrayToMap(obj["images"], topDir);
        }

        // Read all the fields we care about
        for (var prop in obj) {
            if (prop === "buttons") {
                var allButtons = obj[prop];
                for (var buttonName in allButtons) {
                    var info = extractButtonInfo(allButtons[buttonName],
                                                 topDir,
                                                 image_paths_file,
                                                 image_paths);

                    // Find out index for this button
                    var ind = findIn2dArray(button_order,info.id);
                    if (ind < 0) {
                        console.log("Cannot find index for button "+info);
                    }
                    else {
                        model.set(ind, { link: info.link ? info.link : "",
                                         label: info.label ? info.label : "",
                                         utterance: info.utterance ? info.utterance : "",
                                         image_path: info.image_path ? info.image_path : "",
                                         bg_color: info.bg_color ? info.bg_color : "",
                                         border_color: info.border_color ? info.border_color : "",
                                         action: info.action ? info.action : ""
                                       });
                    }
                    i++;
                }
            }
        }
        return { rows: grid_rows, cols: grid_cols }
    }

    // Contents of the model that gets filled in by loading
    // a file.
    property ListModel listModel: ListModel {
        id: model
    }


}

