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
char g_sCurrentMap[MAX_MAP_SIZE];
Spawn g_Spawns[MAX_SPAWN_COUNT];
SpawnModels g_SpawnModels;

#include "round.sp"
#include "hooks.sp"
#include "votes.sp"
#include "menus.sp"
#include "cookies.sp"
#include "commands.sp"
#include "plugin_info.sp"
#include "spawn_points.sp"



void InitConsoleCMDs() {
    InitAdminCMDs();

    RegConsoleCmd("sm_guns", MenuGunPref);
    RegConsoleCmd("sm_vp", c_VotePistol);
    RegConsoleCmd("sm_vd", c_VoteDeagle);
}

void InitConvars() {
    SetConVarInt(FindConVar("bot_quota"), 0);
    SetConVarInt(FindConVar("mp_free_armor"), 0);
    SetConVarInt(FindConVar("mp_startmoney"), 0);
    SetConVarInt(FindConVar("mp_teamcashawards"), 0);
    SetConVarInt(FindConVar("mp_force_pick_time"), 0);
    SetConVarInt(FindConVar("mp_playercashawards"), 0);
    SetConVarInt(FindConVar("mp_defuser_allocation"), 2);
    SetConVarInt(FindConVar("mp_freezetime"), FREEZETIME);
    SetConVarFloat(FindConVar("mp_roundtime"), 0.15);
    SetConVarFloat(FindConVar("mp_roundtime_defuse"), 0.15);
    SetConVarFloat(FindConVar("mp_roundtime_hostage"), 0.15);
    SetConVarFloat(FindConVar("mp_round_restart_delay"), 2.0);
    SetConVarString(FindConVar("ammo_grenade_limit_flashbang"), "2");

}

public void OnPluginEnd() {

}

public void OnPluginStart() { 
    InitHooks();

    InitCookies();

    InitConsoleCMDs();

    for (int i = 1; i < MaxClients; i++) {
        if (!AreClientCookiesCached(i) || IsFakeClient(i)) {
            continue;
        }

        OnClientCookiesCached(i);
    }
}

WeaponTypes MapWeaponSlotToType(WeaponsSlot weapon) {
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

int GetPowOfTwo(int num) {
    int counter = 0;
    if (num <= 0) {
        return counter;
    }

    while (1 != num) {
        num /= 2;
        counter++;
    }
    
    return counter;
}

float GetPercentage(int value, int percentage) {
    return float(value) * (float(percentage) / 100.0);
}

void PopulateArrayList(ArrayList ar, any[] list, int size) { // You must check size is correct, if not, fuck you
    for (int i = 0; i < size; i++) {
        PushArrayCell(ar, list[i]);
    }
}

#endif // MAIN_SP