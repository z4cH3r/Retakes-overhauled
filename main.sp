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
Client g_Client[MAXPLAYERS + 1];
Queue g_ClientQueue;

#include "round.sp"
#include "hooks.sp"
#include "votes.sp"
#include "menus.sp"
#include "cookies.sp"
#include "listeners.sp"
#include "plugin_info.sp"



public void InitConsoleCMDs() {
    RegConsoleCmd("sm_guns", MenuGunPref);
    RegConsoleCmd("sm_vp", c_VotePistol);
    RegConsoleCmd("sm_vd", c_VoteDeagle);
}

public void InitConvars() {
    SetConVarInt(FindConVar("mp_free_armor"), 0);
    SetConVarInt(FindConVar("mp_startmoney"), 0);
    SetConVarInt(FindConVar("mp_teamcashawards"), 0);
    SetConVarInt(FindConVar("mp_force_pick_time"), 0);
    SetConVarInt(FindConVar("mp_playercashawards"), 0);
    SetConVarInt(FindConVar("mp_defuser_allocation"), 2);
}

public void OnPluginStart() { 
    PrintToChatAll("test");

    InitHooks();

    InitListeners();

    InitCookies();

    InitConsoleCMDs();

    InitRetake();

    for (int i = 1; i < MaxClients; i++) {
        if (!AreClientCookiesCached(i) || IsFakeClient(i)) {
            continue;
        }

        OnClientCookiesCached(i);
    }
}

public float GetTimeDelta(float start_time) {
    return GetEngineTime() - start_time;
}

public WeaponTypes MapWeaponSlotToType(WeaponsSlot weapon) {
    if (weapon == Slot_Secondary) {
        return PISTOL_MASK;
    }
    if (weapon == Slot_Primary) {
        return RIFLE_MASK;
    }
    if (weapon == Slot_Projectile) {
        return UTILITY_MASK;
    }
    if (weapon == Slot_Melee) { 
        return KNIFE_MASK;
    }
    if (weapon == Slot_Explosive) {
        return C4_MASK;
    }
    return WEAPON_NONE;
}

public int GetPowOfTwo(int num) {
    int counter = 0;
    while (num != 1) {
        num /= 2;
        counter++;
    }
    
    return counter;
}

#endif // MAIN_SP