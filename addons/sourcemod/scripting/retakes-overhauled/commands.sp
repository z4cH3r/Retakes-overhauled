#if !defined COMMANDS_SP
#define COMMANDS_SP

#include "retakes-overhauled/types.sp"

void InitAdminCMDs() {
    RegAdminCmd("sm_edit", c_EnableEdit, ADMFLAG_ROOT);
    RegAdminCmd("sm_start", c_StartRetake, ADMFLAG_ROOT);
    RegAdminCmd("sm_add", c_AddSpawn, ADMFLAG_ROOT);
    RegAdminCmd("sm_spawns", c_AllSpawn, ADMFLAG_ROOT);
}

public Action c_StartRetake(int client, int argc) {
    if (GetRoundState() == WAITING) {
        PrintToChatAll("%s Not enough players, cannot start", RETAKE_PREFIX);
    }
    else {
        ServerCommand("mp_restartgame 1");
        TryRetakeStart();
    }
}

public Action c_EnableEdit(int client, int argc) {
    if (GetRoundState() == EDIT) {
        TryRetakeStart();
    }
    else {
        EnableEdit();
    }
}

public Action c_AddSpawn(int client, int argc) {
    if (GetRoundState() == EDIT) {
        Menu menu = GetAddSpawnMenu(A, T);
        menu.Display(client, MENU_TIME_FOREVER);
    }
    else {
        PrintToChat(client, "%s Not in edit mode, aborting commands", RETAKE_PREFIX);
    }
    return Plugin_Handled;
}

public Action c_AllSpawn(int client, int argc) {
    if (GetRoundState() == EDIT) {
        Menu menu = GetAllSpawnMenu();
        menu.Display(client, MENU_TIME_FOREVER);
        g_Client[client].spawnpoint_tele = true;
    }
    else {
        PrintToChat(client, "%s Not in edit mode, aborting commands", RETAKE_PREFIX);
    }
    return Plugin_Handled;
}

#endif // COMMANDS_SP