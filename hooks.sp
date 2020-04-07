#if !defined HOOKS_SP
#define HOOKS_SP

#include "main.sp"
#include "round.sp"
#include "types.sp"

/** Convars **/
Handle g_hFreeArmor = INVALID_HANDLE;
Handle g_hGivePlayerC4 = INVALID_HANDLE;
Handle g_hTDefaultSecondary = INVALID_HANDLE;
Handle g_hCTDefaultSecondary = INVALID_HANDLE;

public void InitHooks() {
    /** Event Hooks **/
    HookEvent("round_poststart", e_OnRoundPostStart);
    HookEvent("round_prestart", e_OnRoundPreStart);

    /** Convar Hooks **/
    g_hFreeArmor = FindConVar("mp_free_armor");
    g_hGivePlayerC4 = FindConVar("mp_give_player_c4");
    g_hTDefaultSecondary = FindConVar("mp_t_default_secondary");
    g_hCTDefaultSecondary = FindConVar("mp_ct_default_secondary");
    HookConVarChange(g_hFreeArmor, ConVarChange_Handler);
    HookConVarChange(g_hGivePlayerC4, ConVarChange_Handler);
    HookConVarChange(g_hTDefaultSecondary, ConVarChange_Handler);
    HookConVarChange(g_hCTDefaultSecondary, ConVarChange_Handler);
}

/** Enforce server cvars **/
public void ConVarChange_Handler(Handle convar, const char[] oldValue, const char[] newValue) {
    char cvar_value[MAX_CONVAR_SIZE];

    GetConVarString(g_hTDefaultSecondary, cvar_value, sizeof(cvar_value));
    if (0 != strcmp("''", cvar_value) && 0 != strcmp("\"\"", cvar_value)) {
        SetConVarString(g_hTDefaultSecondary, "");
    }

    GetConVarString(g_hCTDefaultSecondary, cvar_value, sizeof(cvar_value));
    if (0 != strcmp("''", cvar_value) && 0 != strcmp("\"\"", cvar_value)) {
        SetConVarString(g_hCTDefaultSecondary, "");
    }

    if (0 != GetConVarInt(g_hGivePlayerC4)) {
        SetConVarInt(g_hGivePlayerC4, 0);
    }

    if (0 != GetConVarInt(g_hFreeArmor)) {
        SetConVarInt(g_hFreeArmor, 0);
    }
}

public Action e_OnRoundPreStart(Handle event, const char[] name, bool dontBroadcast) {
    return Plugin_Handled;
}

public Action e_OnRoundPostStart(Handle event, const char[] name, bool dontBroadcast) {
    SetupRound();

    return Plugin_Handled;
}

#endif // HOOKS_SP