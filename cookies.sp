#if !defined COOKIES_SP
#define COOKIES_SP

#include "main.sp"
#include "types.sp"


Handle g_hClientAwp = INVALID_HANDLE;
Handle g_hClientAwpSecondary = INVALID_HANDLE;
Handle g_hClientPrimaryT = INVALID_HANDLE;
Handle g_hClientPrimaryCT = INVALID_HANDLE;



public void InitCookies() {
    g_hClientAwp = RegClientCookie("cAwp3121", "Client awp preference", CookieAccess_Protected);
    g_hClientAwpSecondary = RegClientCookie("cPistol2113", "Client secondary preference when with awp", CookieAccess_Protected);
    g_hClientPrimaryT = RegClientCookie("cPrimaryT2113", "Client Primary T weapon preference", CookieAccess_Protected);
    g_hClientPrimaryCT = RegClientCookie("cPrimaryCT2113", "Client Primary CT preference", CookieAccess_Protected);
}

public Handle GetCookie(cookies cookie) {
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

public void SetCookie(int client, cookies cookie, const char[] value) {
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

public void OnClientCookiesCached(int client) {
    if (IsFakeClient(client)) {
        return;
    }

    bool is_new = false;

    char pref[MAX_INPUT_SIZE];

    GetClientCookie(client, GetCookie(cAwp), pref, sizeof(pref));
    if (0 == strlen(pref)) { is_new |= true; }
    g_ClientWeaponPref[client].pref.want_awp = (is_new) ? false : view_as<bool>(StringToInt(pref));
    PrintToChatAll("Awp %s", pref);

    GetClientCookie(client, GetCookie(cAwpSecondary), pref, sizeof(pref));
    if (0 == strlen(pref)) { is_new |= true; }
    g_ClientWeaponPref[client].pref.awp_secondary = (is_new) ? P250 : view_as<WeaponTypes>(StringToInt(pref));
    PrintToChatAll("Pistol %s", pref);

    GetClientCookie(client, GetCookie(cPrimaryT), pref, sizeof(pref));
    if (0 == strlen(pref)) { is_new |= true; }
    g_ClientWeaponPref[client].pref.primary_t = (is_new) ? AK47 : view_as<WeaponTypes>(StringToInt(pref));
    PrintToChatAll("Primary T %s", pref);

    GetClientCookie(client, GetCookie(cPrimaryCT), pref, sizeof(pref));
    if (0 == strlen(pref)) { is_new |= true; }
    g_ClientWeaponPref[client].pref.primary_ct = (is_new) ? M4A1 : view_as<WeaponTypes>(StringToInt(pref));
    PrintToChatAll("primary CT %s", pref);

    if (is_new) {
        g_ClientWeaponPref[client].pref.StoreClientCookies(client);
        MenuGunPref(client, 0);
    }
}

#endif // COOKIES_SP