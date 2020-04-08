#if !defined VOTES_SP
#define VOTES_SP

public bool CanVote(int client) {
    return (GetEngineTime() - g_Client[client].last_command_time) >= VOTE_COOLDOWN_TIME;
}

public int GetVotesAmountNeeded() {
    return GetClientsAmountPercentage(VOTE_PERCENTAGE);
}

public int GetVotesAmount(RoundTypes type) {
    int sum_votes = 0;
    for (int i = 1; i < MaxClients; i++) {
        if (!IsClientInGamePlaying(i)) {
                continue;
            }
        sum_votes += view_as<int>(g_Client[i].votes[GetVoteIndex(type)]);
    }

    return sum_votes;
}

public int GetVoteIndex(RoundTypes type) {
    return GetPowOfTwo(view_as<int>(type));
}

public bool IsVoteEnabled(RoundTypes type) {
    return ((GetRoundCounter() > MINIMUM_PISTOL_ROUNDS) && GetRoundState() == type);
}

char[] GetVoteType(RoundTypes type) {
    char msg[MAX_INPUT_SIZE] = "undefined";

    switch (type) {
        case PISTOL_ROUND: {
            msg = "pistols";
        }
        case DEAGLE_ROUND: {
            msg = "deagles";
        }
    }

    return msg;
}

char[] GetVotePrefix(int client, RoundTypes type) {
    char msg[MAX_INPUT_SIZE] = "undefined";

    if (IsVoteEnabled(type)) {
        if (g_Client[client].votes[GetVoteIndex(type)]) {
            msg = "wants to disable";
        }
        else {
            msg = "devoted disabling";
        }
    }
    else {
        if (g_Client[client].votes[GetVoteIndex(type)]) {
            msg = "wants to enable";
        }
        else {
            msg = "devoted enabling";
        }
    }

    return msg;
}

public Action c_VotePistol(int client, int argc) {
    VoteHandler(client, PISTOL_ROUND);
}

public Action c_VoteDeagle(int client, int argc) {
    VoteHandler(client, DEAGLE_ROUND);
}

public void ResetAllClientsVote(RoundTypes type) {
    for (int i = 1; i < MaxClients; i++) {
        if (!IsClientInGamePlaying(i)) {
                continue;
            }
        g_Client[i].votes[GetVoteIndex(type)] = false;
    }
}

public Action VoteHandler(int client, RoundTypes type) {
    if (!IsClientInGamePlaying(client)) { return Plugin_Handled; }
    if (!CanVote(client)) {
        PrintToChat(client, "[Retakes] Can vote only every %d seconds", VOTE_COOLDOWN_TIME);
        return Plugin_Handled;
    }
    else { g_Client[client].last_command_time = GetEngineTime(); }
    if (GetRoundCounter() <= MINIMUM_PISTOL_ROUNDS) { 
        PrintToChat(client, "[Retakes] Can vote for %s only after %d rounds", GetVoteType(type), MINIMUM_PISTOL_ROUNDS);
        return Plugin_Handled;
    }

    g_Client[client].votes[GetVoteIndex(type)] ^= true;
    int votes_amount = GetVotesAmount(type);
    int votes_needed = GetVotesAmountNeeded();

    PrintToChatAll("[Retakes] %N %s %s only (%d of %d required)", client, GetVotePrefix(client, type), GetVoteType(type), votes_amount, votes_needed);

    if (votes_amount >= GetVotesAmountNeeded()) {
        if (IsVoteEnabled(type)) {
            PrintToChatAll("[Retakes] %s only disabled", GetVoteType(type));
            SetRoundState(FULLBUY_ROUND);
        }
        else {
            PrintToChatAll("[Retakes] %s only enabled", GetVoteType(type));
            SetRoundState(type);
        }
        
        ResetAllClientsVote(type);
        return Plugin_Handled;
    }

    return Plugin_Handled;
}

#endif // VOTES_SP