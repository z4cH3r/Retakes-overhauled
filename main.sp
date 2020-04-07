#if !defined MAIN_SP
#define MAIN_SP

#pragma semicolon 1
#pragma newdecls required

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include "types.sp"

/** Cross file globals **/
Client g_ClientWeaponPref[MAXPLAYERS + 1];

#include "hooks.sp"
#include "menus.sp"
#include "cookies.sp"
#include "listeners.sp"
#include "plugin_info.sp"



public void InitConsoleCMDs() {
    RegConsoleCmd("guns", MenuGunPref);
    // RegConsoleCmd("vp", MenuGunPref);
    // RegConsoleCmd("vd", MenuGunPref);
}

public void InitConvars() {
    Handle cvar = FindConVar("mp_t_default_secondary");
    SetConVarString(cvar, "");
    cvar = FindConVar("mp_ct_default_secondary");
    SetConVarString(cvar, "");
    cvar = FindConVar("mp_give_player_c4");
    SetConVarInt(cvar, 0);
    cvar = FindConVar("mp_free_armor");
    SetConVarInt(cvar, 0);
}

public void OnPluginStart() { 
    PrintToChatAll("test");

    InitHooks();

    InitListeners();

    InitCookies();

    InitConsoleCMDs();

    InitConvars();

    RetakeStart();

    for (int i = 1; i < MaxClients; i++) {
        if (!AreClientCookiesCached(i) || IsFakeClient(i)) {
            continue;
        }

        OnClientCookiesCached(i);
    }
}

public void GivePlayerItemWeaponID(int client, WeaponTypes weapon_id) {
    switch (weapon_id) {
        case AK47: {
            GivePlayerItem(client, "weapon_ak47");
        }
        case SG553: {
            GivePlayerItem(client, "weapon_sg556");
        }
        case AWP: {
            GivePlayerItem(client, "weapon_awp");
        }
        case M4A1: {
            GivePlayerItem(client, "weapon_m4a1");
        }
        case M4A1S: {
            GivePlayerItem(client, "weapon_m4a1_silencer");
        }
        case CZ: {
            GivePlayerItem(client, "weapon_cz75a");
        }
        case P250: {
            GivePlayerItem(client, "weapon_p250");
        }
        case GLOCK: {
            GivePlayerItem(client, "weapon_glock");
        }
        case USP: {
            GivePlayerItem(client, "weapon_hkp2000");
        }
        case P2000: {
            GivePlayerItem(client, "weapon_hkp2000");
        }
        case TEC9: {
            GivePlayerItem(client, "weapon_tec9");
        }
        case FIVESEVEN: {
            GivePlayerItem(client, "weapon_fiveseven");
        }
    }
}

#endif // MAIN_SP