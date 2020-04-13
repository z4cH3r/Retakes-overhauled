#if !defined VOTES_SP
#define VOTES_SP

bool CanVote(int client) {
    return (GetEngineTime() - g_Client[client].last_command_time) >= VOTE_COOLDOWN_TIME;
}

int GetVotesAmountNeeded() {
    return GetClientsAmountPercentage(VOTE_PERCENTAGE);
}

int GetVotesAmount(RoundTypes type) {
    int sum_votes = 0;
    for (int i = 1; i < MaxClients; i++) {
        if (!IsClientInGamePlaying(i)) {
                continue;
            }
        sum_votes += view_as<int>(g_Client[i].votes[GetVoteIndex(type)]);
    }

    return sum_votes;
}

int GetVoteIndex(RoundTypes type) {
    return GetPowOfTwo(view_as<int>(type));
}

bool IsVoteEnabled(RoundTypes type) {
    return ((GetRoundCounter() > MIN_PISTOL_ROUNDS) && GetRoundState() == type);
}

char[] GetVoteType(RoundTypes type) {
    char msg[MAX_INPUT_SIZE] = "undefined";

    switch (type) {
        case PISTOL_ROUND: {
            msg = "pistols only";
        }
        case DEAGLE_ROUND: {
            msg = "deagles only";
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

Action c_VotePistol(int client, int argc) {
    VoteHandler(client, PISTOL_ROUND);
}

Action c_VoteDeagle(int client, int argc) {
    VoteHandler(client, DEAGLE_ROUND);
}

void ResetAllClientsVote(RoundTypes type) {
    for (int i = 1; i < MaxClients; i++) {
        if (!IsClientInGamePlaying(i)) {
                continue;
            }
        g_Client[i].votes[GetVoteIndex(type)] = false;
    }
}

void ResetAllClientsAllVotes() {
    for (int i = 1; i < MaxClients; i++) {
        ResetClientVotes(i, false);
    }
}

void ResetClientVotes(int client, bool trigger) {
    for (int i = 0; i < MAX_VOTE_TYPES; i++) {
        g_Client[client].votes[i] = false;
    }

    if (trigger) {
        TriggerAllVoteTypes();
    }
}

void TriggerAllVoteTypes() {
    bool activated = false;
    for (int i = 0; i < MAX_VOTE_TYPES; i++) {
        if (activated) { // If already activated a round type, reset others that SHOULD be activated.
            if (GetVotesAmount(view_as<RoundTypes>(1 << i)) >= GetVotesAmountNeeded()) {
                ResetAllClientsVote(view_as<RoundTypes>(1 << i)); // Just reset without triggering
            }
            continue;
        }
        if (TriggerVote(view_as<RoundTypes>(1 << i))) { // First round type found that should be activated, activate.
            activated = true;
        }
    }
}

bool TriggerVote(RoundTypes type) {
    int votes_amount = GetVotesAmount(type);
    
    if (votes_amount >= GetVotesAmountNeeded()) {
        ResetAllClientsVote(GetRoundState()); // Reset current votes to disable / enable
        if (IsVoteEnabled(type)) {
            PrintToChatAll("%s %s disabled", RETAKE_PREFIX, GetVoteType(type));
            SetRoundState(FULLBUY_ROUND);
        }
        else {
            PrintToChatAll("%s %s enabled", RETAKE_PREFIX, GetVoteType(type));
            SetRoundState(type);
        }
        
        ResetAllClientsVote(type); // Reset voted type aswell
        return true;
    }
    return false;
}

Action VoteHandler(int client, RoundTypes type) {
    if (CONSOLE_CLIENT == client) { return Plugin_Handled; }
    if (!IsClientInGamePlaying(client)) { return Plugin_Handled; }
    if (GetRoundState() & (RETAKE_NOT_LIVE | TIMER_STARTED)) {
        PrintToChat(client, "%s You can vote only after retake has started..", RETAKE_PREFIX);
    }
    if (!CanVote(client)) {
        PrintToChat(client, "%s You can vote only every %d seconds", RETAKE_PREFIX, VOTE_COOLDOWN_TIME);
        return Plugin_Handled;
    }
    else { g_Client[client].last_command_time = GetEngineTime(); }
    if (MIN_PISTOL_ROUNDS >= GetInternalRoundCounter()) { // Using internal because you can vote before round ends (round end but state hasn't changed)
        PrintToChat(client, "%s Can vote for %s after %d rounds", RETAKE_PREFIX, GetVoteType(type), MIN_PISTOL_ROUNDS);
        return Plugin_Handled;
    }

    g_Client[client].votes[GetVoteIndex(type)] ^= true;
    int votes_amount = GetVotesAmount(type);
    int votes_needed = GetVotesAmountNeeded();

    PrintToChatAll("%s %N %s %s (%d of %d required)", RETAKE_PREFIX, client, GetVotePrefix(client, type), GetVoteType(type), votes_amount, votes_needed);

    TriggerVote(type);

    return Plugin_Handled;
}

#endif // VOTES_SP