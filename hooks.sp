#if !defined HOOKS_SP
#define HOOKS_SP

#include "main.sp"
#include "round.sp"
#include "types.sp"

/** Convars **/
Handle g_hFreeArmor = INVALID_HANDLE;
Handle g_hStartMoney = INVALID_HANDLE;
Handle g_hForcePickTime = INVALID_HANDLE;
Handle g_hTeamCashAwards = INVALID_HANDLE;
Handle g_hPlayerCashAwards = INVALID_HANDLE;
Handle g_hDefuserAllocation = INVALID_HANDLE;

public void InitHooks() {
    /** Event Hooks **/
    HookEvent("round_end", e_OnRoundEnd);
    HookEvent("player_hurt", e_OnPlayerDamged);
    HookEvent("bomb_defused", e_OnBombDefused);
    HookEvent("round_prestart", e_OnRoundPreStart);
    HookEvent("round_poststart", e_OnRoundPostStart);
    HookEvent("player_connect_full", e_OnFullConnect, EventHookMode_Pre);


    /** Convar Hooks **/
    g_hFreeArmor = FindConVar("mp_free_armor");
    g_hStartMoney = FindConVar("mp_startmoney");
    g_hForcePickTime = FindConVar("mp_force_pick_time");
    g_hTeamCashAwards = FindConVar("mp_teamcashawards");
    g_hPlayerCashAwards = FindConVar("mp_playercashawards");
    g_hDefuserAllocation = FindConVar("mp_defuser_allocation");
    // ammo_grenade_limit_flashbang 2
    HookConVarChange(g_hFreeArmor, ConVarChange_Handler);
    HookConVarChange(g_hStartMoney, ConVarChange_Handler);
    HookConVarChange(g_hForcePickTime, ConVarChange_Handler);
    HookConVarChange(g_hTeamCashAwards, ConVarChange_Handler);
    HookConVarChange(g_hPlayerCashAwards, ConVarChange_Handler);
    HookConVarChange(g_hDefuserAllocation, ConVarChange_Handler);
}

/** Enforce server cvars **/
public void ConVarChange_Handler(Handle convar, const char[] oldValue, const char[] newValue) {
    if (0 != GetConVarInt(g_hFreeArmor)) {
        SetConVarInt(g_hFreeArmor, 0);
    }
    
    if (0 != GetConVarInt(g_hTeamCashAwards)) {
        SetConVarInt(g_hTeamCashAwards, 0);
    }

    if (0 != GetConVarInt(g_hPlayerCashAwards)) {
        SetConVarInt(g_hPlayerCashAwards, 0);
    }

    if (0 != GetConVarInt(g_hStartMoney)) {
        SetConVarInt(g_hStartMoney, 0);
    }

    if (0 != GetConVarInt(g_hForcePickTime)) {
        SetConVarInt(g_hForcePickTime, 0);
    }

    if (0 != GetConVarInt(g_hDefuserAllocation)) {
        SetConVarInt(g_hDefuserAllocation, 2);
    }
}

public Action e_OnRoundPreStart(Handle event, const char[] name, bool dontBroadcast) {
    SetupPreRound();

    return Plugin_Handled;
}

public Action e_OnRoundPostStart(Handle event, const char[] name, bool dontBroadcast) {
    SetupRound();

    return Plugin_Handled;
}

public Action e_OnRoundEnd(Handle event, char[] name, bool dontBroadcast) {
    int winnerTeam = GetEventInt(event, "winner");
    if (CS_TEAM_CT == winnerTeam) {
        PrintToChatAll("Set win = true");
        g_bIsCTWin = true;
        g_iWinStreak = 0;
    }
    if (CS_TEAM_T == winnerTeam) {
        g_iWinStreak++;
        PrintToChatAll("Terrors are on %d winstreak!", g_iWinStreak);
    }

    int bomb_ent = FindEntityByClassname(-1, "planted_c4");
    PrintToChatAll("Was bomb planted %d", bomb_ent);

    return Plugin_Handled;
}

public Action e_OnPlayerDamged(Handle event, char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "attacker"));
    if (0 == client) {
        return;
    }
    int damage = GetEventInt(event, "dmg_health");
    if (GetClientTeam(client) == CS_TEAM_CT) {
        g_Client[client].round_damage += damage;
    }
}

public Action e_OnBombDefused(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetTeamClientCountFix(CS_TEAM_T) > 0)
	{
		PrintToChatAll("[Retakes] Ninja defuse!");
		g_Client[client].round_damage += 400;
	}
}

public Action e_OnFullConnect(Handle event, char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    InsertClientIntoQueue(client);

    if (WAITING == GetRoundState() && ((GetClientCountFix() + 1) >= MINIMUM_PLAYERS)) {
        TryRetakeStart(true);
        return;
    }
}

#endif // HOOKS_SP