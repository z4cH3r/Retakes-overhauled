#if !defined COOKIES_SP
#define COOKIES_SP

#include "main.sp"
#include "types.sp"


Handle g_hClientAwp = INVALID_HANDLE;
Handle g_hClientPistol = INVALID_HANDLE;
Handle g_hClientPrimaryT = INVALID_HANDLE;
Handle g_hClientPrimaryCT = INVALID_HANDLE;


public void InitCookies() {
    g_hClientAwp = RegClientCookie("cAwp", "Client awp preference", CookieAccess_Protected);
    g_hClientPistol = RegClientCookie("cPistol", "Client pistol with awp preference", CookieAccess_Protected);
    g_hClientPrimaryT = RegClientCookie("cPrimaryT", "Client Primary T weapon preference", CookieAccess_Protected);
    g_hClientPrimaryCT = RegClientCookie("cPrimaryCT", "Client Primary CT preference", CookieAccess_Protected);
}

public Handle GetCookie(cookies cookie) {
    switch (cookie) {
        case cAwp: {
            return g_hClientAwp;
        }
        case cPistol: {
            return g_hClientPistol;
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

public void SetCookie(int client, cookies cookie, String:value[]) {
    PrintToChatAll("Setting cookie %d to %s", cookie, value);
    switch (cookie) {
        case cAwp: {
            SetClientCookie(client, g_hClientAwp, value);
        }
        case cPistol: {
            SetClientCookie(client, g_hClientPistol, value);
        }
        case cPrimaryT: {
            SetClientCookie(client, g_hClientPrimaryT, value);
        }
        case cPrimaryCT: {
            SetClientCookie(client, g_hClientPrimaryCT, value);
        }
    }
}

#endif // COOKIES_SP