#if !defined COOKIES_SP
#define COOKIES_SP

#include "main.sp"
#include "types.sp"


Handle g_hClientAwp = INVALID_HANDLE;
Handle g_hClientAwpSecondary = INVALID_HANDLE;
Handle g_hClientPrimaryT = INVALID_HANDLE;
Handle g_hClientPrimaryCT = INVALID_HANDLE;



void InitCookies() {
    g_hClientAwp = RegClientCookie("cAwp31121", "Client awp preference", CookieAccess_Protected);
    g_hClientAwpSecondary = RegClientCookie("cPistol21113", "Client secondary preference when with awp", CookieAccess_Protected);
    g_hClientPrimaryT = RegClientCookie("cPrimaryT21113", "Client Primary T weapon preference", CookieAccess_Protected);
    g_hClientPrimaryCT = RegClientCookie("cPrimaryCT21113", "Client Primary CT preference", CookieAccess_Protected);
}

Handle GetCookie(cookies cookie) {
    switch (cookie) {
        case cAwp: {
            return g_hClientAwp;
        }
        case cAwpSecondary: {
            return g_hClientAwpSecondary;
        }
        case cPrimaryT: {
            return g_hClientPrimaryT;
        }
        case cPrimaryCT: {
            return g_hClientPrimaryCT;
        }
    }
    return INVALID_HANDLE;
}

void SetCookie(int client, cookies cookie, const char[] value) {
    if (!IsClientValid(client)) { return; }
    PrintToChatAll("Setting cookie %d to %s", cookie, value);
    switch (cookie) {
        case cAwp: {
            SetClientCookie(client, g_hClientAwp, value);
        }
        case cAwpSecondary: {
            SetClientCookie(client, g_hClientAwpSecondary, value);
        }
        case cPrimaryT: {
            SetClientCookie(client, g_hClientPrimaryT, value);
        }
        case cPrimaryCT: {
            SetClientCookie(client, g_hClientPrimaryCT, value);
        }
    }
}

bool AreCookiesExisting(int client) {
    if (!IsClientValid(client)) { return false; }
    char pref[MAX_INPUT_SIZE];

    for (int i = view_as<int>(cAwp); i <= view_as<int>(cPrimaryCT); i++) { // IF YOU ADD MORE COOKIES, VERIFY THIS!
        GetClientCookie(client, GetCookie(view_as<cookies>(i)), pref, sizeof(pref));
        if (0 == strlen(pref)) { 
            return false;
        }
    }
    
    return true;
}

void OnClientCookiesCached(int client) {
    if (IsFakeClient(client) || !IsClientValid(client)) {
        return;
    }

    char pref[MAX_INPUT_SIZE];
    bool is_new = !AreCookiesExisting(client);

    // Initialize cookies in players cache (and store default value cookies if player is new)
    GetClientCookie(client, GetCookie(cAwp), pref, sizeof(pref));
    g_Client[client].pref.want_awp = (is_new) ? false : view_as<bool>(StringToInt(pref));

    GetClientCookie(client, GetCookie(cAwpSecondary), pref, sizeof(pref));
    g_Client[client].pref.awp_secondary = (is_new) ? P250 : view_as<WeaponTypes>(StringToInt(pref));

    GetClientCookie(client, GetCookie(cPrimaryT), pref, sizeof(pref));
    g_Client[client].pref.primary_t = (is_new) ? AK47 : view_as<WeaponTypes>(StringToInt(pref));

    GetClientCookie(client, GetCookie(cPrimaryCT), pref, sizeof(pref));
    g_Client[client].pref.primary_ct = (is_new) ? M4A1 : view_as<WeaponTypes>(StringToInt(pref));

    if (is_new) {
        g_Client[client].pref.StoreClientCookies(client);
        MenuGunPref(client, 0);
    }
}

#endif // COOKIES_SP