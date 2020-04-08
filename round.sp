#if !defined ROUND_SP
#define ROUND_SP

#include "types.sp"
#include "client.sp"


RoundTypes g_rtRoundState = WARMUP;
bool g_bIsCTWin = false;
bool g_bFullBuyTriggered = false;
int g_iWinStreak = 0;
int g_iRoundCounter = 0;
int g_iBomber;

Handle g_hWarmupTimer = INVALID_HANDLE;
float g_iWarmupTimerStart;



public int GetRoundCounter() {
    return g_iRoundCounter;
}

public RoundTypes GetRoundState() {
    return g_rtRoundState;
}

public void SetRoundState(RoundTypes state) {
    g_rtRoundState = state;
}

public float GetWaitTime() {
    switch (g_rtRoundState) {
        case WARMUP: {
            return float(WARMUP_TIME);
        }
        case WAITING: {
            return float(WAITING_TIME);
        }
    }
    return 0.0;
}

void TryRetakeStart(bool is_on_connect = false) {
    int clients_amount = GetClientCountFix();
    if (is_on_connect) {
        clients_amount += 1;
    }

    if ((clients_amount >= MINIMUM_PLAYERS) || g_rtRoundState == WARMUP) {
        g_iWarmupTimerStart = GetEngineTime();
        g_hWarmupTimer = CreateTimer(0.1, TimerCountdown, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    }
    else {
        CS_TerminateRound(1.0, CSRoundEnd_Draw, false);
        ServerCommand("mp_restartgame 1");
    }
}

public void RetakeStop() {
        g_rtRoundState = WAITING;
        PrintHintTextToAll("[Retakes] Not enough players, aborting retake");

        CS_TerminateRound(1.0, CSRoundEnd_Draw, false);
        ServerCommand("mp_restartgame 1");
}

public Action TimerCountdown(Handle timer)
{
	if (GetTimeDelta(g_iWarmupTimerStart) >= GetWaitTime()) {
        if (INVALID_HANDLE != g_hWarmupTimer) {
            KillTimer(g_hWarmupTimer);
        }
        g_hWarmupTimer = INVALID_HANDLE;

        g_rtRoundState = TIMER_END;
        g_iRoundCounter = 0;

        SetConVarInt(FindConVar("mp_warmuptime"), 5);

        return Plugin_Stop;
    }
	
	PrintHintTextToAll("[Retakes] starting in %.02f ", GetWaitTime() - GetTimeDelta(g_iWarmupTimerStart));	
	
	return Plugin_Continue;
}

public void OnClientDisconnect_Post(int client) {
    if (GetClientCountFix() < MINIMUM_PLAYERS) {
        RetakeStop();
    }
}

public void OnClientConnected(int client) {
    /** Maybe do stuff? **/
}

public void ClearPlayerDamage() {
    for (int i = 1; i < MAXPLAYERS + 1; i++) {
        g_Client[i].round_damage = 0;
    }
}

public void SetupWaitingRound() {
    if (GetClientCountFix() < MINIMUM_PLAYERS) {
        PrintToChatAll("[Retakes] Waiting for more players (>= %d)", MINIMUM_PLAYERS);	
    }
}

public void SetupPreRound() {
    if (g_rtRoundState == WARMUP) {
        return;
    }

    if (g_rtRoundState == TIMER_END) {
        g_iRoundCounter = 0; // Init rounds (Can bug sometime with a weird restart spam)
        g_rtRoundState = PISTOL_ROUND;
    }

    if (GetClientCountFix() < MINIMUM_PLAYERS) { 
        PrintToChatAll("Return waiting");
        g_rtRoundState = WAITING;
        InsertQueuedPlayers();
        if (GetClientCountFix() >= MINIMUM_PLAYERS) {
            TryRetakeStart();
        }
        return;
    }

    g_iRoundCounter = GetTeamScore(CS_TEAM_T) + GetTeamScore(CS_TEAM_CT) + 1; // round 1 is 0
    PrintToChatAll("Now entering round %d, round type %d", g_iRoundCounter, g_rtRoundState);

    if (0 == g_iRoundCounter && !(g_rtRoundState == PISTOL_ROUND)) {
        PrintToChatAll("[Retakes] Live");
        PrintHintTextToAll("[Retakes] Live");        
    }

    if (!(g_rtRoundState & (WARMUP | WAITING | EDIT))) { 
        SetupTeams();
    }

    if (g_iRoundCounter < MINIMUM_PISTOL_ROUNDS) {
        g_bFullBuyTriggered = false;
    }

    PrintToChatAll("Round type %d, fullbuy triggered? %d", g_rtRoundState, g_bFullBuyTriggered);

    if (g_iRoundCounter > MINIMUM_PISTOL_ROUNDS && !g_bFullBuyTriggered) {
        g_bFullBuyTriggered = true;
        g_rtRoundState = FULLBUY_ROUND;
    }

    g_bIsCTWin = false;
    ClearPlayerDamage();
}

public int GetTeamBalanceAmount(int team) {
    int ret = -1;

    int clients = GetClientCountFix();

    switch (team) {
        case CS_TEAM_T: {
            ret = clients / 2;
        }
        case CS_TEAM_CT: {
            ret = clients / 2;
            if (clients % 2) {
                ret += 1;
            }
        }
    }

    return ret;
}

public void VerifyTeamBalance() {
    int current_t_players = GetTeamClientCountFix(CS_TEAM_T, false);
    int current_ct_players = GetTeamClientCountFix(CS_TEAM_CT, false);

    int team_delta = current_ct_players - current_t_players;

    if (team_delta > 1) { // More CT's than T's
        for (int i = 0; i < (team_delta / 2); i++) {
            CS_SwitchTeam(GetRandomPlayer(CS_TEAM_CT), CS_TEAM_T);
        }
    }
    if (team_delta < 0) { // More T's than CT's
        for (int i = 0; i < -((team_delta / 2) + team_delta % 2); i++) {
            CS_SwitchTeam(GetRandomPlayer(CS_TEAM_T), CS_TEAM_CT);
        }
    }

    PrintToChatAll("T players balance %d", current_t_players);
    PrintToChatAll("CT players balance %d", current_ct_players);
}

public int GetNextTeamBalance() {
    int next_team = CS_TEAM_CT;
    int current_t_players = GetTeamClientCountFix(CS_TEAM_T, false);
    int current_ct_players = GetTeamClientCountFix(CS_TEAM_CT, false);

    if (current_t_players >= current_ct_players) {
        next_team = CS_TEAM_CT;
    }
    else {
        next_team = CS_TEAM_T;
    }

    return next_team;
}

public int SwitchTeams() {
    int index = 0;
    int to_ct_clients[4];
    int to_t_clients[4];
    for (int i = 1; i < MaxClients; i++) {
        if (index > 3) {
            PrintToChatAll("Somehow more than 4 T players, contact @AE");
            break;
        }
        if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T) {
            to_ct_clients[index++] = i;
            PrintToChatAll("to_ct_clients[%d] = %N to ct", index - 1, i);
        }
    }
    PrintToChatAll("Transferring %d to ct", index);

    index = 0;
    int damage;
    int most_damage;
    int most_damage_client = -1;
    bool already_existing = false;
    bool insert_arbitrary = false;

    for (int i = 0; i < GetTeamBalanceAmount(CS_TEAM_T); i++) {
        for (int j = 1; j < MaxClients; j++) {
            if (!IsClientInGame(j) || GetClientTeam(j) != CS_TEAM_CT) {
                continue;
            }

            damage = g_Client[j].round_damage;
            if (damage > most_damage || insert_arbitrary) {
                for (int k = 0; k < GetTeamBalanceAmount(CS_TEAM_T); k++) {
                    if (to_t_clients[k] == j) {
                        already_existing = true;
                        break;
                    }
                }
                if (already_existing) {
                    already_existing = false;
                    continue;
                }

                most_damage = damage;
                most_damage_client = j;

                if (insert_arbitrary) {
                    break;
                }
            }
        }

        if (most_damage_client == -1 && insert_arbitrary == false) {
            insert_arbitrary = true;
            i -= 1;
            continue;
        }

        PrintToChatAll("to_t_clients[%d] = %N to ct", i, most_damage_client);
        to_t_clients[i] = most_damage_client;
        most_damage_client = -1;
    }
    PrintToChatAll("Transferring %d to t", GetTeamBalanceAmount(CS_TEAM_T));

    for (int i = 0; i < 4; i++) {
        if (to_ct_clients[i] > 0) {
            CS_SwitchTeam(to_ct_clients[i], CS_TEAM_CT);
        }
        if (to_t_clients[i] > 0) {
            CS_SwitchTeam(to_t_clients[i], CS_TEAM_T);
        }
    }
}

public void ScrambleTeams() {
    int temp;
    int index = 0;
    int clients_frag_sorted[MAXPLAYERS];

    for (int i = 1; i < MAXPLAYERS; i++) {
        if (!IsClientInGamePlaying(i)) {
            continue;
        }
        clients_frag_sorted[index++] = i;
    }

    for (int i = 1; i <= GetClientCountFix() - 1; ++i) {
        if (!IsClientInGamePlaying(clients_frag_sorted[i])) {
            continue;
        }
        for (int j = 0; j < GetClientCountFix() - i; ++j) {
            if (!IsClientInGamePlaying(clients_frag_sorted[j])) {
                continue;
            }
            if (GetClientFrags(clients_frag_sorted[j]) < GetClientFrags(clients_frag_sorted[j + 1])) {
                temp = clients_frag_sorted[j];
                clients_frag_sorted[j] = clients_frag_sorted[j + 1];
                clients_frag_sorted[j + 1] = temp;
            }
        }
    }

    index = 0;
    int target_team = CS_TEAM_CT;
    for (int i = 1; i < MAXPLAYERS; i++) {
        if (!IsClientInGamePlaying(clients_frag_sorted[i]))  {
            continue;
        }

        if (i % 2 == 0) {
            target_team = CS_TEAM_CT;
        }
        else {
            target_team = CS_TEAM_T;
        }
        CS_SwitchTeam(clients_frag_sorted[i], target_team);
        PrintToChatAll("Fragger[%d] = %N with %d frags!", i + 1, clients_frag_sorted[i], GetClientFrags(clients_frag_sorted[i]));
    }
}

public void SetupTeams() {
    if (g_bIsCTWin) {
        SwitchTeams();
    }
    if (g_iWinStreak >= WINSTREAK_MAX) {
        g_iWinStreak = 0;
        ScrambleTeams();
    }

    VerifyTeamBalance();

    InsertQueuedPlayers();
}

public void InsertQueuedPlayers() {
    int ingame_players = GetClientCountFix();

    if (ingame_players <= 9 && g_ClientQueue.len > 0) {
        while (g_ClientQueue.len > 0 && ingame_players <= 9) {
            ChangeClientTeam(g_ClientQueue.pop(), GetNextTeamBalance());
            ingame_players = GetClientCountFix();
        }
    }
}

public void SetupRound() {
    /** Two special cases which we do not strip player **/
    WeaponTypes mask = KNIFE_MASK;

    if (g_rtRoundState & (WAITING | WARMUP)) {
        mask |= PISTOL_MASK;
    }

    StripAllClientsWeapons(mask);

    if (!(g_rtRoundState & (WAITING | WARMUP))) {
        g_iBomber = GetRandomPlayer(CS_TEAM_T);
        GiveBombToPlayer(g_iBomber);
    }
    

    switch (g_rtRoundState) {
        case WAITING: {
            SetupWaitingRound();
        }
        case WARMUP: {
            TryRetakeStart();
        }
        case FULLBUY_ROUND: {
            SetupFullbuyRound();
        }
        case PISTOL_ROUND: {
            SetupPistolRound();
        }
        case DEAGLE_ROUND: {
            SetupDeagleRound();
        }
    }
}

public void SetupDeagleRound() {
    /** Per player setup **/
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGamePlaying(i) || IsFakeClient(i)) {
            continue;
        }

        SetEntProp(i, Prop_Send, "m_bHasHelmet", 1); // Head armor = true
        SetEntProp(i, Prop_Data, "m_ArmorValue", 100, 1); 

        GiveClientItemWeaponID(i, DEAGLE);
    }
}

public void SetupPistolRound() {
    /** Per player setup **/
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGamePlaying(i) || IsFakeClient(i)) {
            continue;
        }

        SetEntProp(i, Prop_Send, "m_bHasHelmet", 0); // Head armor = false
        SetEntProp(i, Prop_Data, "m_ArmorValue", 100, 1); 

        WeaponTypes secondary = WEAPON_NONE;

        if (CS_TEAM_T == GetClientTeam(i)) {
            secondary = GLOCK;
        }
        else {
            secondary = USP;  // Doesn't matter if USP or P2K, when giving weapon_hkp2000 you receive whatever you have in inventory.
        }

        GiveClientItemWeaponID(i, secondary);
    }
}

public void SetupFullbuyRound() {
    int awp_player_t = GetRandomAwpPlayer(CS_TEAM_T);   // Both of these CAN be 0 incase of an entire team which 
    int awp_player_ct = GetRandomAwpPlayer(CS_TEAM_CT); // awp is selected to false

    /** Per player setup **/
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGamePlaying(i) || IsFakeClient(i)) {
            continue;
        }

        SetEntProp(i, Prop_Send, "m_bHasHelmet", 1);
        SetEntProp(i, Prop_Data, "m_ArmorValue", 100, 1); 

        WeaponTypes weapon = WEAPON_NONE;

        weapon |= GetRandomGrenades(i);

        /** If AWP player **/
        if (i == awp_player_t || i == awp_player_ct) { 
            weapon |= AWP;
            weapon |= GetRandomAwpSecondary(i);
        }
        else {
            if (CS_TEAM_T == GetClientTeam(i)) {
                weapon |= g_Client[i].pref.primary_t;
                weapon |= GLOCK;
            }
            else {
                weapon |= g_Client[i].pref.primary_ct;
                weapon |= USP;  // Doesn't matter if USP or P2K, when giving weapon_hkp2000 you receive whatever you have in inventory.
            }
        }

        GiveClientItemWeaponID(i, weapon);
    }
}

public void InitRetake() {
    TryRetakeStart();
    ServerCommand("mp_warmuptime 120");
    ServerCommand("mp_warmup_start");
    g_rtRoundState = WARMUP;
}

public void OnMapStart() {

    PrintToChatAll("OnMapStart()");
    InitRetake();

    InitConvars();
}

#endif // ROUND_SP