frame.grabToImage(result => {
  root.saved = result.saveToFile(path) ? "saved" : "save failed";
}, Qt.size(frame.width * 3, frame.height * 3));