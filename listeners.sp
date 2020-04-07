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
    switch (target_team) {
        case CS_TEAM_T: {
            PrintToChatAll("You have chosen Terrorist");
        }
        case CS_TEAM_CT: {
            PrintToChatAll("You have chosen Counter-Terrorist");
        }
    }

    CS_SwitchTeam(client, target_team);
    CS_UpdateClientModel(client);

    return Plugin_Handled;
}  

#endif // LISTENERS_SP