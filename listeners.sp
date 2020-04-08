#if !defined LISTENERS_SP
#define LISTENERS_SP

#include "types.sp"
#include "main.sp"



public void InitListeners() {
    AddCommandListener(l_JoinTeam, "jointeam");
}

/*
 *  Listen on client "JoinTeam" command to disable players switching teams
 */
public Action l_JoinTeam(int client, const char[] command, int argc) {
    if (0 == client) {
        return Plugin_Continue;
    }

    char func_arg[MAX_COMMAND_SIZE];
    GetCmdArg(1, func_arg, sizeof(func_arg));
    int target_team = StringToInt(func_arg);
    int source_team = GetClientTeam(client);

    if (g_rtRoundState & (WAITING | WARMUP | TIMER_END)) {
        ChangeClientTeam(client, target_team);
        return Plugin_Handled;
    }

    if (source_team == CS_TEAM_NONE || source_team == CS_TEAM_SPECTATOR) {
        target_team = CS_TEAM_SPECTATOR;
    }

    PrintToChatAll("Client %d source %d target %d", client, source_team, target_team);

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

#endif // LISTENERS_SP