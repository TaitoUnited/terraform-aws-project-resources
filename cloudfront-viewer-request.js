function handler(event) {
  var request = event.request;
  var uri = request.uri;
  var isFileRequest = uri.replace(/.*\//, "").includes(".");

  if (!isFileRequest) {
    // TODO: remove hardcoded /publicview
    if (uri.startsWith("/publicview")) {
      request.uri = "/publicview/index.html";
    } else {
      request.uri = "/index.html";
    }
  }

  return request;
}
