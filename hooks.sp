#if !defined HOOKS_SP
#define HOOKS_SP

#include "main.sp"
#include "types.sp"



public void InitHooks() {
    HookEvent("round_prestart", e_OnRoundPreStart);
    HookEvent("round_poststart", e_OnRoundPostStart);
}

public Action e_OnRoundPreStart(Handle event, const String:name[], bool dontBroadcast) {
     for (int i = 1; i < MaxClients; i++) {
        if (IsFakeClient(i) || !IsClientInGame(i)) {
            continue;
        }

        DeleteItems(i, 0);
     }
}

public Action e_OnRoundPostStart(Handle event, const String:name[], bool dontBroadcast) {
    PrintToChatAll("Hello?");
    for (int i = 1; i < MaxClients; i++) {
        if (IsFakeClient(i) || !IsClientInGame(i)) {
            continue;
        }
        cookies primary;

        if (CS_TEAM_T == GetClientTeam(i)) {
            primary = cPrimaryT;
        }
        else {
            primary = cPrimaryCT;
        }

        GivePlayerItemWeaponID(i, GetClientWeaponPref(i, primary));
        GivePlayerItemWeaponID(i, CZ);
    }
}

#endif // HOOKS_SP