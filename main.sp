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
#include "plugin_info.sp"



void InitConsoleCMDs() {
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
    SetConVarFloat(FindConVar("mp_roundtime_defuse"), 0.15);
    SetConVarFloat(FindConVar("mp_roundtime_hostage"), 0.15);

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
    while (1 != num) {
        num /= 2;
        counter++;
    }
    
    return counter;
}

float GetPercentage(int value, int percentage) { // TODO: REMOVE STOCK
    return float(value) * (float(percentage) / 100.0);
}

void PopulateArrayList(ArrayList ar, any[] list, int size) { // You must check size is correct, if not, fuck you
    for (int i = 0; i < size; i++) {
        PushArrayCell(ar, list[i]);
    }
}

void HandleError() {
    PrintToChatAll("%s An error has occured, most likely server out of memory, aborting retake", RETAKE_PREFIX);
    SetRoundState(WAITING);
    CS_TerminateRound(1.0, CSRoundEnd_Draw, false);
    ServerCommand("mp_restartgame 1");
}

#endif // MAIN_SP