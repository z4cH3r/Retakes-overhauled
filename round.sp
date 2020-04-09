#if !defined ROUND_SP
#define ROUND_SP

#include "types.sp"
#include "client.sp"


int g_iBomber;
int g_iWinStreak = 0;
int g_iRoundCounter = 0;
bool g_bIsCTWin = false;
bool g_bBombWasPlanted = false;
bool g_bWarmupCountdown = false;
bool g_bFullBuyTriggered = false;
RoundTypes g_rtRoundState = WARMUP;
float g_iWarmupTimerStart;




RoundTypes RetakeNotLiveTypes() {
    return WARMUP | WAITING | EDIT;
}

/** Set / Get for included files only **/
void SetIsCTWin(bool value) {
    g_bIsCTWin = value;
}

void SetTWinStreak(int value) {
    g_iWinStreak = value;
}

int GetTWinStreak() {
    return g_iWinStreak;
}

int GetRoundCounter() {
    return g_iRoundCounter;
}

void SetWasBombPlanted(bool value) {
    g_bBombWasPlanted = value;
}

RoundTypes GetRoundState() {
    return g_rtRoundState;
}

void SetRoundState(RoundTypes state) {
    PrintToChatAll("%s Round state set to 0x%08x", RETAKE_PREFIX, state);
    g_rtRoundState = state;
}

float GetTimerCountdown() {
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

bool TryRetakeStart() {
    int clients_amount = GetClientCountFix();
    if ((clients_amount >= MINIMUM_PLAYERS) && (g_rtRoundState & RetakeNotLiveTypes())) {
        g_iWarmupTimerStart = GetEngineTime();
        CreateTimer(0.1, TimerCountdown, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        return true;
    }
    
    return false;
}

 void RetakeStop() {
    if (WAITING != g_rtRoundState) {

        SetRoundState(WAITING);
        PrintToChatAll("%s Not enough players, aborting retake", RETAKE_PREFIX);

        CS_TerminateRound(1.0, CSRoundEnd_Draw, false);
        ServerCommand("mp_restartgame 1");
    }
}

Action TimerCountdown(Handle timer)
{
    if (GetTimeDelta(g_iWarmupTimerStart) >= GetTimerCountdown()) {
        g_bWarmupCountdown = false;
        SetRoundState(TIMER_END);

        return Plugin_Stop;
    }

    if ((GetTimeDelta(g_iWarmupTimerStart) >= (GetTimerCountdown() - 5)) && (!g_bWarmupCountdown)) {
        g_bWarmupCountdown = true;

        // Set the 5 second countdown freeze
        SetConVarInt(FindConVar("mp_warmuptime"), 5);
        if(0 == GameRules_GetProp("m_bWarmupPeriod")) {
            ServerCommand("mp_warmup_start");
        }  
    }
    
    PrintHintTextToAll("%s starting in %.02f ", RETAKE_PREFIX, GetTimerCountdown() - GetTimeDelta(g_iWarmupTimerStart));	
    
    return Plugin_Continue;
}

public void OnClientDisconnect_Post(int client) {
    if (GetClientCountFix() < MINIMUM_PLAYERS) {
        RetakeStop();
    }
}

public void OnClientConnected(int client) {
    if (IsFakeClient(client)) {
        return;
    }

    g_Client[client].last_command_time = GetEngineTime();
    ResetClientVotes(client);
}

void ClearPlayerDamage() {
    for (int i = 1; i < MAXPLAYERS + 1; i++) {
        g_Client[i].round_damage = 0;
    }
}

void SetupWaitingRound() {
    if (GetClientCountFix() < MINIMUM_PLAYERS) {
        PrintToChatAll("%s Waiting for more players (>= %d)", RETAKE_PREFIX, MINIMUM_PLAYERS);	
    }
    else {
        TryRetakeStart();
    }
}

void SetupRoundEnd() {
    if (!g_bBombWasPlanted && (g_rtRoundState & ~RetakeNotLiveTypes())) {
        PrintToChatAll("%s %N hasn't planted the bomb and will be swapped to CT", RETAKE_PREFIX, g_iBomber);
        int client = GetRandomPlayer(GetTeamMatrix(CS_TEAM_CT));
        if (-1 != client) {
            CS_SwitchTeam(client, CS_TEAM_T);
        }
        CS_SwitchTeam(g_iBomber, CS_TEAM_CT);
    }
}

void SetupPreRound() {
    if (g_rtRoundState & RetakeNotLiveTypes()) {
        return;
    }

    SetupTeams();
    g_bIsCTWin = false;
    ClearPlayerDamage();
    g_bBombWasPlanted = false;
}

// Returns how many players SHOULD be on each team
int GetTeamBalanceAmount(int team) {
    int ret = 0;

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

// Checks whether delta of T's and CT's >= 1 towards the CT's
void VerifyTeamBalance() {
    int client;
    int counter;
    while ((CS_TEAM_T == GetNextTeamBalance()) && (counter++ < MaxClients)) {
        PrintToChatAll("%s team %d teambalance", RETAKE_PREFIX, GetNextTeamBalance());
        client = GetRandomPlayer(GetTeamMatrix(CS_TEAM_T));
        if (-1 != client) {
            CS_SwitchTeam(client, CS_TEAM_CT);
            PrintToChatAll("%s Moved %N to CT due to autoteambalance", RETAKE_PREFIX, client);
        }
    }
}

// Returns which team would a player be assigned NEXT
int GetNextTeamBalance() {
    int next_team;
    int current_t_players = GetPlayerCount(GetTeamMatrix(CS_TEAM_T));
    int current_ct_players = GetPlayerCount(GetTeamMatrix(CS_TEAM_CT));

    if (current_ct_players > current_t_players) {
        next_team = CS_TEAM_T;
    }
    else {
        next_team = CS_TEAM_CT;
    }

    return next_team;
}

int SwitchTeams() {
    ArrayList t_matrix = new ArrayList();
    if (INVALID_HANDLE == t_matrix) { HandleError(); }

    ArrayList ct_matrix = new ArrayList();
    if (INVALID_HANDLE == ct_matrix) { HandleError(); }

    PopulateArrayList(t_matrix, GetTeamMatrix(CS_TEAM_T), GetPlayerCount(GetTeamMatrix(CS_TEAM_T)));
    PopulateArrayList(ct_matrix, GetTeamMatrix(CS_TEAM_CT), GetPlayerCount(GetTeamMatrix(CS_TEAM_CT)));

    PrintToChatAll("Transferring %d players to ct", GetArraySize(t_matrix));

    for (int i = 0; i < GetArraySize(t_matrix); i++) {
        CS_SwitchTeam(GetArrayCell(t_matrix, i), CS_TEAM_CT);
    }

    // bubble sorting the clients via round_damage
    for (int i = 1; i <= GetArraySize(ct_matrix) - 1; i++) {
        for (int j = 0; j <  GetArraySize(ct_matrix) - i; j++) {
            if (g_Client[GetArrayCell(ct_matrix, j)].round_damage > g_Client[GetArrayCell(ct_matrix, j + 1)].round_damage) {
                SwapArrayItems(ct_matrix, j, j + 1);
            }
        }
    }

    PrintToChatAll("%s Last round damage:", RETAKE_PREFIX);
    for (int i = 0; i < GetArraySize(ct_matrix); i++) {
        PrintToChatAll("%s %N with %d damage", RETAKE_PREFIX, GetArrayCell(ct_matrix, i), g_Client[GetArrayCell(ct_matrix, i)].round_damage);
    }

    for (int i = 0; (i < GetTeamBalanceAmount(CS_TEAM_T)) && (i < GetArraySize(ct_matrix)); i++) {
        CS_SwitchTeam(GetArrayCell(ct_matrix, i), CS_TEAM_T);
    }

    delete t_matrix;
    delete ct_matrix;
}

void ScrambleTeams(bool sort_by_frags = true) {
    ArrayList players_matrix = new ArrayList();
    if (INVALID_HANDLE == players_matrix) { HandleError(); }

    PopulateArrayList(players_matrix, GetTeamMatrix(CS_TEAM_T), GetPlayerCount(GetTeamMatrix(CS_TEAM_T)));
    PopulateArrayList(players_matrix, GetTeamMatrix(CS_TEAM_CT), GetPlayerCount(GetTeamMatrix(CS_TEAM_CT)));

    if (sort_by_frags) {
        // Bubble sorting the clients via frags
        for (int i = 1; i <= GetArraySize(players_matrix) - 1; i++) {
            for (int j = 0; j <  GetArraySize(players_matrix) - i; j++) {
                if (GetClientFrags(GetArrayCell(players_matrix, j)) > GetClientFrags(GetArrayCell(players_matrix, j + 1))) {
                    SwapArrayItems(players_matrix, j, j + 1);
                }
            }
        }

        // Print frag stats
        PrintToChatAll("%s Scramble stats:", RETAKE_PREFIX);
        for (int i = 0; i < GetArraySize(players_matrix); i++) {
            PrintToChatAll("%s %d. %N with %d frags", RETAKE_PREFIX, i + 1, GetArrayCell(players_matrix, i), GetClientFrags(GetArrayCell(players_matrix, i)));
        }
    }
    else {
        SortADTArray(players_matrix, Sort_Random, Sort_Integer);
    }

    for (int i = 0; i < GetArraySize(players_matrix); i++) {
        if (i % 2 == 0) {
            CS_SwitchTeam(GetArrayCell(players_matrix, i), CS_TEAM_T);
        }
        else {
            CS_SwitchTeam(GetArrayCell(players_matrix, i), CS_TEAM_CT);
        }
    }

    delete players_matrix;
}

void SetupTeams() {
    InsertQueuedPlayers();

    if (g_bIsCTWin && g_bBombWasPlanted) {
        SwitchTeams();
    }

    if (g_rtRoundState == TIMER_END)
    {
        ScrambleTeams(false);
    }

    VerifyTeamBalance();

    if (g_iWinStreak > WINSTREAK_MAX) {
        PrintToChatAll("%s Terrorist achieved maximum winstreak of %d, scrambling...", RETAKE_PREFIX, WINSTREAK_MAX);
        g_iWinStreak = 0;
        ScrambleTeams();
    }

}

public void InsertQueuedPlayers() {
    int ingame_players = GetClientCountFix(true);

    if (ingame_players <= 9 && g_ClientQueue.len > 0) {
        while (g_ClientQueue.len > 0 && ingame_players <= 9) {
            CS_SwitchTeam(g_ClientQueue.pop(), GetNextTeamBalance());
            ingame_players = GetClientCountFix(true);
        }
    }
}

void BeforeSetupRound() {
    // If not live, do nothing
    if (g_rtRoundState & RetakeNotLiveTypes()) {
        return;
    }

    if (GetClientCountFix() < MINIMUM_PLAYERS) {
        SetRoundState(WAITING);
        return;
    }

    if (g_rtRoundState == TIMER_END) {
        SetRoundState(PISTOL_ROUND);
        InsertSpectateIntoServer();
        ServerCommand("mp_restartgame 1");
    }

    int round_counter = GetTeamScore(CS_TEAM_T) + GetTeamScore(CS_TEAM_CT) + 1;

    if (round_counter <= MINIMUM_PISTOL_ROUNDS) {
        g_bFullBuyTriggered = false;
        SetRoundState(PISTOL_ROUND); // In case of rr or something   
    }

    if (round_counter > MINIMUM_PISTOL_ROUNDS && !g_bFullBuyTriggered) {
        g_bFullBuyTriggered = true;
        SetRoundState(FULLBUY_ROUND);
    }

    PrintToChatAll("%s Started round %d (0x%08x)", RETAKE_PREFIX, round_counter, g_rtRoundState);
}

void SetupRound() {

    // If we're live, strip and assign random terrorist the bomb
    if (g_rtRoundState & ~RetakeNotLiveTypes()) {
        StripAllClientsWeapons(KNIFE_MASK);
        g_iBomber = GetRandomPlayer(GetTeamMatrix(CS_TEAM_T));
        if (-1 != g_iBomber) {
            PrintToChatAll("%s Bomb given to %N", RETAKE_PREFIX, g_iBomber);
            GiveClientItemWeaponID(g_iBomber, C4);
        }
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
        if (!IsClientInGamePlaying(i)) {
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
        if (!IsClientInGamePlaying(i)) {
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
    int awp_player_t = GetRandomAwpPlayer(GetTeamMatrix(CS_TEAM_T));   // Both of these CAN be 0 incase of an entire team which 
    int awp_player_ct = GetRandomAwpPlayer(GetTeamMatrix(CS_TEAM_CT)); // awp is selected to false

    /** Per player setup **/
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGamePlaying(i)) {
            continue;
        }

        SetEntProp(i, Prop_Send, "m_bHasHelmet", 1);
        SetEntProp(i, Prop_Data, "m_ArmorValue", 100, 1); 

        WeaponTypes weapon = WEAPON_NONE;

        weapon = GetRandomGrenades(i);

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
    ServerCommand("mp_warmuptime 120");
    ServerCommand("mp_autoteambalance 1");
    ServerCommand("mp_warmup_start");
    SetRoundState(WARMUP);
    if (!TryRetakeStart()) {
        RetakeStop();
    }
}

public void OnMapStart() {
    InitConvars();
    
    InitRetake();
}

#endif // ROUND_SP