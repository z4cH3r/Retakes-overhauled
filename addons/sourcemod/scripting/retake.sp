#if !defined RETAKE_SP
#define RETAKE_SP

#pragma semicolon 1
#pragma newdecls required

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

#include "retakes-overhauled/types.sp"

/** Cross file globals **/
Client g_Client[MAXPLAYERS + 1];
Queue g_ClientQueue;
Spawn g_Spawns[MAX_SPAWN_COUNT];
SpawnModels g_SpawnModels;

#include "retakes-overhauled/round.sp"
#include "retakes-overhauled/hooks.sp"
#include "retakes-overhauled/votes.sp"
#include "retakes-overhauled/menus.sp"
#include "retakes-overhauled/cookies.sp"
#include "retakes-overhauled/commands.sp"
#include "retakes-overhauled/plugin_info.sp"
#include "retakes-overhauled/spawn_points.sp"



void InitConsoleCMDs() {
    InitAdminCMDs();

    RegConsoleCmd("sm_guns", MenuGunPref);
    RegConsoleCmd("sm_vp", c_VotePistol);
    RegConsoleCmd("sm_vd", c_VoteDeagle);
}

void SetRetakeLiveCvars() {
    ServerCommand("exec retakes_live.cfg");
}

void SetEditCvars() {
    ServerCommand("exec retakes_edit.cfg");
}

void SetInitCvars() {
    ServerCommand("exec retakes.cfg");
}

public void OnPluginEnd() {

}

public void OnPluginStart() { 
    PrintToChatAll("%s Plugin loaded", RETAKE_PREFIX);

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

char[] GetSiteStringFromBombsite(Bombsite site) {
    char ret[MAX_INPUT_SIZE] = "NONE";
    switch (site) {
        case A: {
            ret = "A";
        }
        case B: {
            ret = "B";
        }
    }
    
    return ret;
}

char[] GetSpawnTypeStringFromSpawnType(SpawnType type) {
    char ret[MAX_INPUT_SIZE] = "NONE";
    switch (type) {
        case CT: {
            ret = "Counter-Terrorist";
        }
        case T: {
            ret = "Terrorist";
        }
        case BOMBER: {
            ret = "Bomber";
        }
    }
    
    return ret;
}

void ClearQueue() {
    while (-1 != g_ClientQueue.pop()) {
        
    }
}

#endif // RETAKE_SP