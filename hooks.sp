#if !defined HOOKS_SP
#define HOOKS_SP

#include "main.sp"
#include "round.sp"
#include "types.sp"



void InitHooks() {
    /** Event Hooks **/
    HookEvent("round_end", e_OnRoundEnd);
    HookEvent("bomb_defused", e_OnBombDefused);
    HookEvent("player_hurt", e_OnPlayerDamaged);
    HookEvent("round_prestart", e_OnRoundPreStart);
    HookEvent("round_poststart", e_OnRoundPostStart);
    HookEvent("player_connect_full", e_OnFullConnect);
    HookEvent("player_team", e_OnPlayerChangeTeam, EventHookMode_Pre);

    /** Listeners **/
    AddCommandListener(l_JoinTeam, "jointeam");
}

Action l_JoinTeam(int client, const char[] command, int argc) {
    if (!IsClientValid(client)) {
        return Plugin_Continue;
    }

    // Get joinTeam args
    char func_arg[MAX_INPUT_SIZE];
    GetCmdArg(1, func_arg, sizeof(func_arg));
    int target_team = StringToInt(func_arg);
    int source_team = GetClientTeam(client);

    // If retake isn't live, allow team transfers
    if (GetRoundState() & (RETAKE_NOT_LIVE | TIMER_STARTED)) {
        if (GetRoundState() != TIMER_STARTED) {
            TryRetakeStart();
        }
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
    if ((GetRoundState() & ~(RETAKE_NOT_LIVE | TIMER_STARTED)) && (GetEventInt(event, "team") != CS_TEAM_SPECTATOR)) {
        event.BroadcastDisabled = true;
    }
    return Plugin_Changed;
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
    if (GetRoundState() & (RETAKE_NOT_LIVE | TIMER_STARTED | TIMER_STOPPED)) {
        return Plugin_Continue;
    }
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
    if (!IsClientValid(client)) { return; }

    int damage = GetEventInt(event, "dmg_health");
    if (GetClientTeam(client) == CS_TEAM_CT) {
        g_Client[client].round_damage += damage;
    }
}

public Action e_OnBombDefused(Event event, char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsClientValid(client)) { return; }

    if(GetPlayerCount(GetTeamMatrix(CS_TEAM_T), true) > 0)
    {
        PrintToChatAll("%s %N has ninja defused!", RETAKE_PREFIX, client);
        g_Client[client].round_damage += 400;
    }
}

public Action e_OnFullConnect(Event event, char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsClientValid(client)) { return; }
    if (GetRoundState() & ~RETAKE_NOT_LIVE) { 
        InsertClientIntoQueue(client);
    }

    if (IsFakeClient(client)) {
        return;
    }

    g_Client[client].last_command_time = GetEngineTime();
    ResetClientVotes(client);

    if (g_rtRoundState == WAITING) {
        TryRetakeStart();
    }
}

public void OnClientDisconnect_Post(int client) {
    if (!IsClientValid(client)) { return; }
    if ((GetClientCountFix() < MIN_PLAYERS) && (~RETAKE_NOT_LIVE & g_rtRoundState)) {
        RetakeStop();
    }
    
    // Remove client from queue if existing
    g_ClientQueue.pop(g_ClientQueue.get_index(client));
}

#endif // HOOKS_SP