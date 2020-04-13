#if !defined ROUND_SP
#define ROUND_SP

#include "types.sp"
#include "client.sp"
#include "spawn_points.sp"


int g_iBomber = -1;
int g_iWinStreak = 0;
int g_iRoundCounter = 0;
bool g_bIsCTWin = false;
bool g_bBombWasPlanted = false;
bool g_bWarmupCountdown = false;
char g_sCurrentMap[MAX_MAP_STRING_SIZE];
bool g_bFullBuyTriggered = false;
RoundTypes g_rtRoundState = WARMUP;
float g_fWarmupTimerEnd;
Handle g_hStartTimer = INVALID_HANDLE;



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
    return GetTeamScore(CS_TEAM_T) + GetTeamScore(CS_TEAM_CT) + 1;
}

int GetInternalRoundCounter() {
    return g_iRoundCounter;
}

void SetWasBombPlanted(bool value) {
    g_bBombWasPlanted = value;
}

RoundTypes GetRoundState() {
    return g_rtRoundState;
}

void SetRoundState(RoundTypes state) {
    // PrintToChatAll("%s Round state set to 0x%08x", RETAKE_PREFIX, state);
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
        case EDIT: {
            return float(EDIT_TIME);
        }
    }
    return 0.0;
}

bool TryRetakeStart() {
    int clients_amount = GetClientCount(); // Using GetClientCount without fix for connecting players case
    if ((clients_amount >= MIN_PLAYERS) && (g_rtRoundState & RETAKE_NOT_LIVE)) {
        g_bWarmupCountdown = false;
        g_fWarmupTimerEnd = GetEngineTime() + GetTimerCountdown();
        SetRoundState(TIMER_STARTED);
        g_hStartTimer = CreateTimer(0.1, TimerCountdown, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        return true;
    }

    RetakeStop();
    return false;
}

 void RetakeStop() {
    if (WAITING != g_rtRoundState) {        
        SetRoundState(WAITING);
        if (GetClientCount() < MIN_PLAYERS) {
            PrintToChatAll("%s Not enough players, aborting retake", RETAKE_PREFIX);
        }
        CS_TerminateRound(1.0, CSRoundEnd_Draw, false);
        ServerCommand("mp_restartgame 1");
    }
}

void EnableWarmupCountdown(int time) {
    SetConVarInt(FindConVar("mp_warmuptime"), time);
    if (0 == GameRules_GetProp("m_bWarmupPeriod")) {
        ServerCommand("mp_warmup_start");
    }  
}

Action TimerCountdown(Handle timer)
{
    if (GetEngineTime() >= g_fWarmupTimerEnd) {
        g_bWarmupCountdown = false;
        SetRoundState(TIMER_STOPPED);

        return Plugin_Stop;
    }

    if (((GetEngineTime() + 5.0) >= g_fWarmupTimerEnd) && (!g_bWarmupCountdown)) {
        g_bWarmupCountdown = true;

        // Set the 5 second countdown freeze
        EnableWarmupCountdown(5);
    }
    
    PrintHintTextToAll("%s starting in %.02f ", RETAKE_PREFIX, g_fWarmupTimerEnd - GetEngineTime());	
    
    return Plugin_Continue;
}

void ClearPlayerDamage() {
    for (int i = 1; i < MAXPLAYERS + 1; i++) {
        g_Client[i].round_damage = 0;
    }
}

void SetupWaitingRound() {
    if (GetClientCountFix() < MIN_PLAYERS) {
        SetInitCvars();        
        PrintToChatAll("%s Waiting for more players (>= %d)", RETAKE_PREFIX, MIN_PLAYERS);	
    }
    else {
        TryRetakeStart();
    }
}

void SetupRoundEnd() {
    if (!g_bBombWasPlanted && (g_rtRoundState & ~RETAKE_NOT_LIVE)) {
        if (-1 != g_iBomber) {
            PrintToChatAll("%s %N hasn't planted the bomb and will be swapped to CT", RETAKE_PREFIX, g_iBomber);
        }
    }
}

Bombsite GetRandomSite() {
    return view_as<Bombsite>(GetURandomInt() % 2);
}

void SwapBomber() {
    int client = GetRandomPlayer(GetTeamMatrix(CS_TEAM_CT));
    if (-1 != client && -1 != g_iBomber) {
        SwitchClientTeam(client, CS_TEAM_T);
        SwitchClientTeam(g_iBomber, CS_TEAM_CT);
    }
}

void SetupPreRound() {
    if (g_rtRoundState & (RETAKE_NOT_LIVE | TIMER_STARTED | TIMER_STOPPED)) {
        return;
    }

    if (!g_bBombWasPlanted) {
        SwapBomber();
    }

    VerifyCookies();
    SetupTeams();
    g_bIsCTWin = false;
    ClearPlayerDamage();
    g_bBombWasPlanted = false;
    ResetSpawnUsage();
    g_iRoundCounter = GetRoundCounter();
}

// Returns how many players SHOULD be on each team
int GetTeamBalanceAmount(int team) {
    int ret = 0;

    int clients = GetClientCountFix(true) + g_ClientQueue.size;

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

// Checks whether delta of T's and CT's >= 1 towards the CT's or too many players overall
void VerifyTeamBalance() {
    int client;
    while (GetPlayerCount(GetTeamMatrix(CS_TEAM_T)) > GetPlayerCount(GetTeamMatrix(CS_TEAM_CT))) {
        client = GetRandomPlayer(GetTeamMatrix(CS_TEAM_T));
        if (-1 != client) {
            SwitchClientTeam(client, CS_TEAM_CT);
            PrintToChatAll("%s Moved %N to CT due to autoteambalance", RETAKE_PREFIX, client);
        }
    }

    while (GetClientCountFix(true) > MAX_INGAME_PLAYERS) {
        client = GetRandomPlayer(GetTeamMatrix(CS_TEAM_T));
        if (-1 != client) {
            SwitchClientTeam(client, CS_TEAM_SPECTATOR);
            PrintToChatAll("%s Moved %N to spectate due to too many players", RETAKE_PREFIX, client);
        }
        else {
            break;
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
    if (INVALID_HANDLE == t_matrix) { 
        SetFailState("%s Could not allocate memory for t_matrix @ SwitchTeams", RETAKE_PREFIX);
    }

    ArrayList ct_matrix = new ArrayList();
    if (INVALID_HANDLE == ct_matrix) { 
        SetFailState("%s Could not allocate memory for ct_matrix @ SwitchTeams", RETAKE_PREFIX);
    }

    PopulateArrayList(t_matrix, GetTeamMatrix(CS_TEAM_T), GetPlayerCount(GetTeamMatrix(CS_TEAM_T)));
    PopulateArrayList(ct_matrix, GetTeamMatrix(CS_TEAM_CT), GetPlayerCount(GetTeamMatrix(CS_TEAM_CT)));

    // PrintToChatAll("Transferring %d players to ct", GetArraySize(t_matrix));

    for (int i = 0; i < GetArraySize(t_matrix); i++) {
        SwitchClientTeam(GetArrayCell(t_matrix, i), CS_TEAM_CT);
    }

    // bubble sorting the clients via round_damage
    for (int i = 1; i <= GetArraySize(ct_matrix) - 1; i++) {
        for (int j = 0; j <  GetArraySize(ct_matrix) - i; j++) {
            if (g_Client[GetArrayCell(ct_matrix, j)].round_damage < g_Client[GetArrayCell(ct_matrix, j + 1)].round_damage) {
                SwapArrayItems(ct_matrix, j, j + 1);
            }
        }
    }

    PrintToChatAll("%s Last round damage:", RETAKE_PREFIX);
    for (int i = 0; i < GetArraySize(ct_matrix); i++) {
        PrintToChatAll("%s %N with %d damage", RETAKE_PREFIX, GetArrayCell(ct_matrix, i), g_Client[GetArrayCell(ct_matrix, i)].round_damage);
    }

    for (int i = 0; (i < GetTeamBalanceAmount(CS_TEAM_T)) && (i < GetArraySize(ct_matrix)); i++) {
        SwitchClientTeam(GetArrayCell(ct_matrix, i), CS_TEAM_T);
        // PrintToChatAll("Transferring %N players to t", GetArrayCell(ct_matrix, i));
    }

    delete t_matrix;
    delete ct_matrix;
}

void ScrambleTeams(bool sort_by_frags = true) {
    ArrayList players_matrix = new ArrayList();
    if (INVALID_HANDLE == players_matrix) { 
        SetFailState("%s Could not allocate memory for players_matrix @ ScrambleTeams", RETAKE_PREFIX);
    }

    PopulateArrayList(players_matrix, GetTeamMatrix(CS_TEAM_T), GetPlayerCount(GetTeamMatrix(CS_TEAM_T)));
    PopulateArrayList(players_matrix, GetTeamMatrix(CS_TEAM_CT), GetPlayerCount(GetTeamMatrix(CS_TEAM_CT)));

    if (sort_by_frags) {
        // Bubble sorting the clients via frags
        for (int i = 1; i <= GetArraySize(players_matrix) - 1; i++) {
            for (int j = 0; j <  GetArraySize(players_matrix) - i; j++) {
                if (GetClientFrags(GetArrayCell(players_matrix, j)) < GetClientFrags(GetArrayCell(players_matrix, j + 1))) {
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
            SwitchClientTeam(GetArrayCell(players_matrix, i), CS_TEAM_CT);
        }
        else {
            SwitchClientTeam(GetArrayCell(players_matrix, i), CS_TEAM_T);
        }
    }

    delete players_matrix;
}

void SetupTeams() {
    InsertQueuedPlayers();

    if (g_bIsCTWin && g_bBombWasPlanted) {
        SwitchTeams();
    }

    VerifyTeamBalance(); // Might be bug cause I'm stupid

    if (g_rtRoundState == TIMER_STOPPED)
    {
        ScrambleTeams(false);
    }

    if (g_iWinStreak >= WINSTREAK_MAX) {
        PrintToChatAll("%s Terrorist achieved maximum winstreak of %d, scrambling...", RETAKE_PREFIX, WINSTREAK_MAX);
        g_iWinStreak = 0;
        ScrambleTeams();
    }

}

void InsertQueuedPlayers() {
    int ingame_players = GetClientCountFix(true);

    while (g_ClientQueue.size > 0 && ingame_players < MAX_INGAME_PLAYERS) {
        SwitchClientTeam(g_ClientQueue.pop(), GetNextTeamBalance());
        ingame_players = GetClientCountFix(true);
    }
}

void BeforeSetupRound() {
    // If not live, do nothing
    if (g_rtRoundState & (RETAKE_NOT_LIVE | TIMER_STARTED)) {
        return;
    }

    if ((GetClientCountFix() < MIN_PLAYERS) && (g_rtRoundState != WARMUP)) {
        SetRoundState(WAITING);
        return;
    }

    if (g_rtRoundState == TIMER_STOPPED) {
        return;
    }

    int round_counter = GetRoundCounter();
    if (1 == round_counter) { // In case of rr or map switch
        SetTWinStreak(0);
        g_bFullBuyTriggered = false;
        SetRoundState(PISTOL_ROUND);
    }

    if (round_counter > MIN_PISTOL_ROUNDS && !g_bFullBuyTriggered) {
        g_bFullBuyTriggered = true;
        SetRoundState(FULLBUY_ROUND);
    }

    PrintToChatAll("%s Started round %d (0x%08x)", RETAKE_PREFIX, round_counter, g_rtRoundState);
}

void EnableEdit() {
    if ((INVALID_HANDLE != g_hStartTimer) && (GetEngineTime() < g_fWarmupTimerEnd)) {
        KillTimer(g_hStartTimer);
    }
    PrintToChatAll("%s Edit mode enabled", RETAKE_PREFIX);

    SetEditCvars();

    SetRoundState(EDIT);
    ServerCommand("mp_restartgame 1");
}

void SetupSpawns(Bombsite site) {
    ArrayList players_matrix = new ArrayList();
    if (INVALID_HANDLE == players_matrix) { 
        SetFailState("%s Could not allocate memory for players_matrix @ SetupSpawns", RETAKE_PREFIX);
    }
    
    PopulateArrayList(players_matrix, GetTeamMatrix(CS_TEAM_T), GetPlayerCount(GetTeamMatrix(CS_TEAM_T)));
    PopulateArrayList(players_matrix, GetTeamMatrix(CS_TEAM_CT), GetPlayerCount(GetTeamMatrix(CS_TEAM_CT)));

    for (int i = 0; i < GetArraySize(players_matrix); i++) {
        int spawn_index = GetRandomSpawn(view_as<SpawnType>(GetClientTeam(GetArrayCell(players_matrix, i))), site);
        if (-1 == spawn_index) {
            RetakeStop();
            SetFailState("%s Did not find spawn point for %N, Team %d, Site %d @ SetupSpawns",      \
             RETAKE_PREFIX, GetArrayCell(players_matrix, i),                                        \
             GetClientTeam(GetArrayCell(players_matrix, i)), site);
            break;
        }

        TeleportClient(GetArrayCell(players_matrix, i), g_Spawns[spawn_index]);
    }
    
    delete players_matrix;
}

Action SwitchToBomb(Handle timer, int client) {
    FakeClientCommand(client, "use weapon_c4");
    return Plugin_Stop;
}

void RetakeLiveRoundSetup() {
    Bombsite cur_site = GetRandomSite();
    
    StripAllClientsWeapons(KNIFE_MASK);

    SetupSpawns(cur_site);

    g_iBomber = GetRandomPlayer(GetTeamMatrix(CS_TEAM_T));
    if (-1 != g_iBomber) {
        int spawn_index = GetRandomSpawn(BOMBER, cur_site);

        if (-1 == spawn_index) {
            RetakeStop();
            SetFailState("%s Did not find spawn point for %N, Team %d, Site %d @ RetakeLiveRoundSetup", \
             RETAKE_PREFIX, g_iBomber, GetClientTeam(g_iBomber), cur_site);
        }
        TeleportClient(g_iBomber, g_Spawns[spawn_index]);
        GiveClientItemWeaponID(g_iBomber, C4);
        CreateTimer(0.1, SwitchToBomb, g_iBomber);
    }

    switch (cur_site) {
        case A:
            PrintToChatAll("%s Retaking on site A (%d CT vs %d T)", RETAKE_PREFIX, \
             GetPlayerCount(GetTeamMatrix(CS_TEAM_CT)), GetPlayerCount(GetTeamMatrix(CS_TEAM_T)));	
        case B:
            PrintToChatAll("%s Retaking on site B (%d CT vs %d T)", RETAKE_PREFIX, \
             GetPlayerCount(GetTeamMatrix(CS_TEAM_CT)), GetPlayerCount(GetTeamMatrix(CS_TEAM_T)));	
    }
}

void SetupRound() {
    // If we're live, strip and assign random terrorist the bomb
    if (g_rtRoundState & ~(RETAKE_NOT_LIVE | TIMER_STARTED | TIMER_STOPPED)) {
        RetakeLiveRoundSetup();
    }

    switch (g_rtRoundState) {
        case WAITING: {
            SetupWaitingRound();
        }
        case WARMUP: {
            TryRetakeStart();
        }
        case EDIT: {
            SetupEditRound();
        }
        case TIMER_STOPPED: {
            SetRoundState(PISTOL_ROUND);
            SetRetakeLiveCvars();
            InsertSpectateIntoServer();
            ServerCommand("mp_restartgame 1");
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

void SetupEditRound() {
    for (int i = 0; i < MaxClients; i++) {
        g_Client[i].spawnpoint_tele = false;
        g_Client[i].edit_menu_opened = false;
    }
    DrawSpawns();
}

void SetupDeagleRound() {
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

void SetupPistolRound() {
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

void SetupFullbuyRound() {
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

void UpdateCurrentMapLower() {
    GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));
    int len = strlen(g_sCurrentMap);
    for (int i = 0; i < len ; i++) {
        g_sCurrentMap[i] = CharToLower(g_sCurrentMap[i]);
    }
}

char[] GetCurrentMapLower() {
    return g_sCurrentMap;
}

void PrecacheModels() {
    g_SpawnModels.ct_model = PrecacheModel(CT_MODEL);
    g_SpawnModels.t_model = PrecacheModel(T_MODEL);
    g_SpawnModels.bomber_model = PrecacheModel(BOMBER_MODEL);
    g_SpawnModels.error_model = PrecacheModel(ERROR_MODEL);
}

public void OnMapStart() {
    SetRoundState(WARMUP);

    ResetAllClientsAllVotes();

    SetInitCvars();

    ConnectToDB();

    PrecacheModels();
    
    UpdateCurrentMapLower();

    LoadSpawns();
}

#endif // ROUND_SP