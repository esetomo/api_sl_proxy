string DOMAIN = "target domain (without scheme)";
string CLIENT_ID = "CLIENT_ID";
string CLIENT_SECRET = "CLIENT_SECRET";
string PROXY = "proxy url (with scheme)";
string url;
string token;

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
            llLoadURL(llGetOwner(), 
                      "", 
                      PROXY + "/oauth/" + CLIENT_ID + "/read write follow/" + DOMAIN + "?sl=" + url);
        } else {
            if(method == "POST"){
                list data = ["grant_type", "authorization_code",
                             "redirect_uri", PROXY + "/oauth/callback",
                             "client_id", CLIENT_ID,
                             "client_secret", CLIENT_SECRET,
                             "code", body];
                llHTTPRequest("https://" + DOMAIN + "/oauth/token", [HTTP_METHOD, "POST", HTTP_MIMETYPE, "application/json"], llList2Json(JSON_OBJECT, data));       
                llReleaseURL(url);
            }
            llHTTPResponse(id, 200, "OK");
        }
    }
    
    http_response(key id, integer status, list meta, string body)
    {
        token = llJsonGetValue(body, ["access_token"]);
        state token_active;
    }
}

state token_active
{
    state_entry()
    {
        llHTTPRequest("https://" + DOMAIN + "/api/v1/accounts/verify_credentials?access_token=" + token, [], "");
    }
    
    http_response(key id, integer status, list meta, string body)
    {
        llOwnerSay(body);
    }
}
