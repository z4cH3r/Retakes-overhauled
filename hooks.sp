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



void InitHooks() {
    /** Event Hooks **/
    HookEvent("round_end", e_OnRoundEnd);
    HookEvent("bomb_defused", e_OnBombDefused);
    HookEvent("player_hurt", e_OnPlayerDamaged);
    HookEvent("round_prestart", e_OnRoundPreStart);
    HookEvent("round_poststart", e_OnRoundPostStart);
    HookEvent("player_team", e_OnPlayerChangeTeam, EventHookMode_Pre);
    HookEvent("player_connect_full", e_OnFullConnect, EventHookMode_Pre);

    /** Listeners **/
    AddCommandListener(l_JoinTeam, "jointeam");

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

Action l_JoinTeam(int client, const char[] command, int argc) {
    if (0 == client) {
        return Plugin_Continue;
    }

    // Get joinTeam args
    char func_arg[MAX_INPUT_SIZE];
    GetCmdArg(1, func_arg, sizeof(func_arg));
    int target_team = StringToInt(func_arg);
    int source_team = GetClientTeam(client);

    // If retake isn't live, allow team transfers
    if (GetRoundState() & RetakeNotLiveTypes()) {
        // ChangeClientTeam(client, target_team);
        return Plugin_Continue;
    }

    // Do not allow newcomers to select a team which isn't spectator
    if (source_team == CS_TEAM_NONE || source_team == CS_TEAM_SPECTATOR) {
        target_team = CS_TEAM_SPECTATOR;
    }

    // Allow only moving to spec from any team
    switch (target_team) {
        case CS_TEAM_T: {
            PrintToChat(client, "Cannot change team to T");
            return Plugin_Handled;
        }
        case CS_TEAM_CT: {
            PrintToChat(client, "Cannot change team to CT");
            return Plugin_Handled;
        }
        case CS_TEAM_SPECTATOR: {
            InsertClientIntoQueue(client);
            return Plugin_Handled;
        }
    }
    
    return Plugin_Handled;
}

public Action e_OnPlayerChangeTeam(Event event, char[] name, bool dont_broadcast) {
    event.BroadcastDisabled = false;
    if ((GetRoundState() & ~RetakeNotLiveTypes()) && (GetEventInt(event, "team") != CS_TEAM_SPECTATOR)) {
        event.BroadcastDisabled = true;
    }
    return Plugin_Changed;
}

/** Enforce server cvars **/
public void ConVarChange_Handler(Handle convar, const char[] old_value, const char[] new_value) {
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

public Action e_OnRoundPreStart(Event event, const char[] name, bool dontBroadcast) {
    SetupPreRound();

    return Plugin_Handled;
}

public Action e_OnRoundPostStart(Event event, const char[] name, bool dontBroadcast) {
    BeforeSetupRound();
    SetupRound();

    return Plugin_Handled;
}

public Action e_OnRoundEnd(Event event, char[] name, bool dontBroadcast) {
    int winnerTeam = GetEventInt(event, "winner");

    if (CS_TEAM_CT == winnerTeam) {
        SetIsCTWin(true);
        SetTWinStreak(0); // Reset terrorist winning streak
    }

    if (CS_TEAM_T == winnerTeam) {
        SetTWinStreak(GetTWinStreak() + 1);
        // If over 50% of rounds needed for scramble then print winstreak
        if (GetTWinStreak() > RoundToCeil(GetPercentage(WINSTREAK_MAX, 50))) {
            PrintToChatAll("Terrors are on %d winstreak!", GetTWinStreak());
        }
    }

    SetWasBombPlanted(-1 != FindEntityByClassname(-1, "planted_c4"));

    SetupRoundEnd();

    return Plugin_Handled;
}

public Action e_OnPlayerDamaged(Event event, char[] name, bool dontBroadcast)
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

public Action e_OnBombDefused(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetPlayerCount(GetTeamMatrix(CS_TEAM_T), true) > 0)
	{
		PrintToChatAll("%s %N has ninja defused!", RETAKE_PREFIX, client);
		g_Client[client].round_damage += 400;
	}
}

public Action e_OnFullConnect(Event event, char[] name, bool dontBroadcast) {
    if (GetRoundState() & ~RetakeNotLiveTypes()) { 
        int client = GetClientOfUserId(GetEventInt(event, "userid"));
        InsertClientIntoQueue(client);
    }
}

#endif // HOOKS_SP