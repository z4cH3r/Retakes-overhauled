#if !defined ROUND_SP
#define ROUND_SP

#include "types.sp"

RoundTypes g_ROUND_STATUS = WARMUP;

Handle g_hWarmupTimer = INVALID_HANDLE;
float g_iWarmupTimerStart;



public void RetakeStart() {
    // if (GetClientCount(true) >= 2) {

    // }

    // g_iWarmupTimerStart = GetEngineTime();
    // g_hWarmupTimer = CreateTimer(0.1, Timer_Countdown, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

    // EnableWarmup();
    g_ROUND_STATUS = FULLBUY_ROUND;
}

public void EnableWarmup() {
    if (1 == 1 || GetClientCount(true) >= 2) {
    }
    else {
        if (INVALID_HANDLE != g_hWarmupTimer) {
            CloseHandle(g_hWarmupTimer);
        }
    }
}

// Callback for timer
public Action Timer_Countdown(Handle timer)
{
	// When our global variable is 0, stop the timer
	if (GetEngineTime() - g_iWarmupTimerStart >= 30)
		return Plugin_Stop;
	
	// We print out our global variable which is our count down timer
	PrintHintTextToAll("[Retakes] starting in %.02f ", 30 - (GetEngineTime() - g_iWarmupTimerStart));	
	
	// Continue running the repeated timer
	return Plugin_Continue;
}

public void OnClientDisconnect(int client) {

}

public int GetRandomAwpPlayer(int team) {
    int index = 0;
    int clients[MAXPLAYERS];
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGame(i) || IsFakeClient(i)) {
            continue;
        }
        
        if (team == GetClientTeam(i) && true == g_ClientWeaponPref[i].pref.want_awp) {
            clients[index++] = i;
        }
    }

    if (index > 0) {
        // -- because index is increased after each insert and GetRandomInt is inclusive
        index -= 1;
    }

    return clients[GetRandomInt(0, index)]; 
}

public WeaponTypes GetRandomAwpSecondary(int client, int team) {
    int rand = GetRandomInt(0, 3); // 25% chance
    WeaponTypes secondary = P250;

    if (0 == rand && WEAPON_NONE != secondary) {
        secondary = g_ClientWeaponPref[client].pref.awp_secondary & ~P250;
        WeaponTypes team_mask = (CS_TEAM_T == team) ? PISTOL_T_MASK : PISTOL_CT_MASK;
        secondary = secondary & team_mask;
        secondary = (secondary & CZ) ? CZ : secondary;
    }

    return secondary;
}

public void SetupRound() {
    switch (g_ROUND_STATUS) {
        case FULLBUY_ROUND: {
            SetupFullbuyRound();
        }
        case WAITING: {
            EnableWarmup();
        }
        case PISTOL_ROUND: {
            SetupPistolRound();
        }
    }
}

public void SetupPistolRound() {
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGame(i) || IsFakeClient(i)) {
            continue;
        }

        SetEntProp(i, Prop_Send, "m_bHasHelmet", 0);
        SetEntProp(i, Prop_Data, "m_ArmorValue", 100, 1); 

        WeaponTypes secondary = WEAPON_NONE;

        if (CS_TEAM_T == GetClientTeam(i)) {
            secondary = GLOCK;
        }
        else {
            secondary = USP;  // Doesn't matter if USP or P2K, when giving weapon_hkp2000 you receive whatever you have in inventory.
        }

        GivePlayerItemWeaponID(i, secondary);
    }
}

public void SetupFullbuyRound() {
    int awp_player_t = GetRandomAwpPlayer(CS_TEAM_T);   // Both of these CAN be 0 incase of an entire team which 
    int awp_player_ct = GetRandomAwpPlayer(CS_TEAM_CT); // awp is selected to false

    PrintToChatAll("Hello?");
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGame(i) || IsFakeClient(i)) {
            continue;
        }

        SetEntProp(i, Prop_Send, "m_bHasHelmet", 1);
        SetEntProp(i, Prop_Data, "m_ArmorValue", 100, 1); 

        WeaponTypes primary = WEAPON_NONE;
        WeaponTypes secondary = WEAPON_NONE;

        /** If AWP player **/
        if (i == awp_player_t || i == awp_player_ct) { 
            primary = AWP;
            secondary = GetRandomAwpSecondary(i, GetClientTeam(i));
        }
        else {
            if (CS_TEAM_T == GetClientTeam(i)) {
                primary = g_ClientWeaponPref[i].pref.primary_t;
                secondary = GLOCK;
            }
            else {
                primary = g_ClientWeaponPref[i].pref.primary_ct;
                secondary = USP;  // Doesn't matter if USP or P2K, when giving weapon_hkp2000 you receive whatever you have in inventory.
            }
        }

        GivePlayerItemWeaponID(i, primary);
        GivePlayerItemWeaponID(i, secondary);
    }
}

public void OnMapStart() {
    RetakeStart();
}

#endif // ROUND_SP