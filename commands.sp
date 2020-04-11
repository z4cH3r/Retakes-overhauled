#if !defined COMMANDS_SP
#define COMMANDS_SP

#include "types.sp"

void InitAdminCMDs() {
    RegAdminCmd("sm_edit", c_EnableEdit, ADMFLAG_ROOT);
    RegAdminCmd("sm_start", c_StartRetake, ADMFLAG_ROOT);
    RegAdminCmd("sm_fak", c_DoStuff, ADMFLAG_ROOT);
}

public Action c_StartRetake(int client, int argc) {
    if (GetRoundState() == WAITING) {
        PrintToChatAll("%s Not enough players, cannot start", RETAKE_PREFIX);
    }
    else {
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

public Action c_DoStuff(int client, int argc) {
    int EntIndex = CreateEntityByName("prop_dynamic"); 
    SetEntityModel(EntIndex, "models/player/tm_phoenix.mdl");
    ActivateEntity(EntIndex);
    DispatchSpawn(EntIndex);
    float client_origin[3];
    float client_angles[3];
    GetClientAbsAngles(client, client_angles);
    GetClientAbsOrigin(client, client_origin);
    // SetVariantString("Idle_Shoot_C4");
    // AcceptEntityInput(EntIndex, "SetAnimation");
    TeleportEntity(EntIndex, client_origin, client_angles, NULL_VECTOR); 
    PrintToChatAll("%s %d", RETAKE_PREFIX, EntIndex);
    return Plugin_Handled;
}

#endif // COMMANDS_SP