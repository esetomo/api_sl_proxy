string DOMAIN = "target domain (without scheme)";
string PROXY = "proxy url (with scheme)";
string TOKEN = "API TOKEN";
string url;

default
{
    state_entry()
    {
        llRequestSecureURL();
    }

    http_request(key id, string method, string body)
    {
        if(method == URL_REQUEST_GRANTED){
            url = body;
            llHTTPRequest(PROXY + "/streaming/" + DOMAIN + "/" + TOKEN + "?sl=" + url + "&stream=public", [], "");
        } else {
            llWhisper(0, body);
            llHTTPResponse(id, 200, "OK");
        }
    }

    http_response(key id, integer status, list meta, string body)
    {
        llOwnerSay((string)status);
        llOwnerSay(body);
    }
}

