#if !defined CLIENT_SP
#define CLIENT_SP

#include "retake.sp"

void StripClientWeapons(int client, WeaponTypes exclude_slots) {
    if (!IsClientValid(client)) { return; }
    if(!IsClientInGamePlaying(client)) {
        return;
    }

    int weapon = -1;
    bool remove_slots_exclude[5];


    for (int i = view_as<int>(Slot_Primary); i <= view_as<int>(Slot_Explosive); i++) {
        remove_slots_exclude[i] = (exclude_slots & MapWeaponSlotToType(view_as<WeaponsSlot>(i))) ? true : false;
    }

    for (int slot = 0; slot < 5; slot++) {
        if (remove_slots_exclude[slot]) {
            continue;
        }

        for (int j = 0; j < 10; j++) {
            weapon = GetPlayerWeaponSlot(client, slot);
            if (-1 != weapon) {
                if(IsValidEntity(weapon)) {
                    RemovePlayerItem(client, weapon);
                }
            }
        }
    }
}

int[] GetTeamMatrix(int team, bool is_playing_only = true) {
    int index = 0;
    int team_matrix[MAXPLAYERS];
    for (int i = 1; i < MaxClients; i++) {
        if (!IsClientInGame(i)) {
            continue;
        }
        
        if (is_playing_only && !IsClientInGamePlaying(i)) {
            continue;
        }

        if ((GetClientTeam(i) == team) || (CS_TEAM_ANY == team)) {
            team_matrix[index++] = i;
        }
    }

    return team_matrix;
}

int GetPlayerCount(int[] team_matrix, bool alive_only = false) {
    int counter = 0;
    int i = 0;
    while ((0 != team_matrix[i]) && (i < MaxClients)) { // This is okay because team_matrix is queue'ish
        if (!IsPlayerAlive(team_matrix[i++]) && alive_only) {
            continue;
        }
        counter++;
    }

    return counter;
}

int GetRandomPlayer(int[] team_matrix) {
    if (0 == GetPlayerCount(team_matrix)) { 
        return -1;
    }

    return team_matrix[GetURandomInt() % GetPlayerCount(team_matrix)]; 
}

int GetRandomAwpPlayer(int[] team_matrix) {
    int index = 0;
    int awp_users[MAXPLAYERS];
    for (int i = 0; i < GetPlayerCount(team_matrix); i++) {
        if (g_Client[team_matrix[i]].pref.want_awp) {
            awp_users[index++] = team_matrix[i];
        }
    }

    if (0 == index) {
        return -1;
    }

    return awp_users[GetURandomInt() % index];
}

WeaponTypes GetRandomGrenades(int client) {
        if (!IsClientValid(client)) { return WEAPON_NONE; }
        int rand = GetURandomInt() % 6;
        switch (rand) {
            case 0: {
                return FLASHBANG | FLASHBANG_2ND;
            }
            case 1: {
                return FLASHBANG | HEGRENADE;
            }
            case 2: {
                return SMOKEGRENADE;
            }
            case 3: {
                return (CS_TEAM_T == GetClientTeam(client)) ? FLASHBANG | MOLOTOV : FLASHBANG | INCENDIARY;
            }
            case 4: {
                return (CS_TEAM_T == GetClientTeam(client)) ? MOLOTOV : INCENDIARY;
            }
            case 5: {
                return WEAPON_NONE;
            }
        }
        return WEAPON_NONE;
}

WeaponTypes GetRandomAwpSecondary(int client) {
    if (!IsClientValid(client)) { return WEAPON_NONE; }
    int rand = GetURandomInt() % 3; // 33% chance
    WeaponTypes secondary = P250;
    
    if (0 == rand) {
        // Can be (CZ | P250) || (FIVESEVEN | TEC9 | P250)
        secondary = g_Client[client].pref.awp_secondary & ~P250; // --> (CZ) || (FIVESEVEN | TEC9)
        // Removing team mask --> (CZ) || (is_terror) ? TEC9 : FIVESVEN
        WeaponTypes team_mask = (CS_TEAM_T == GetClientTeam(client)) ? PISTOL_T_MASK : PISTOL_CT_MASK;
        secondary = secondary & team_mask;
        if (WEAPON_NONE == secondary) { // Incase of P250 only
            secondary = P250;
        }
    }

    return secondary;
}

int GetClientCountFix(bool playing_only = false) {
    int player_count = GetPlayerCount(GetTeamMatrix(CS_TEAM_T));
    player_count += GetPlayerCount(GetTeamMatrix(CS_TEAM_CT));

    if (!playing_only) {
        player_count += GetPlayerCount(GetTeamMatrix(CS_TEAM_SPECTATOR, false));
    }

    return player_count;
}

void StripAllClientsWeapons(WeaponTypes slot_exception) {
    for (int i = 1; i < MaxClients; i++) {
        StripClientWeapons(i, slot_exception);
    }
}

void GiveClientItemWeaponID(int client, WeaponTypes weapon_id) { 
    if (!IsClientValid(client)) { return; }
    if(!IsClientInGamePlaying(client)) {
        return;
    }

    if (weapon_id & AK47) {
            GivePlayerItem(client, "weapon_ak47");
        }
    if (weapon_id & SG553) {
            GivePlayerItem(client, "weapon_sg556");
        }
    if (weapon_id & AWP) {
            GivePlayerItem(client, "weapon_awp");
        }
    if (weapon_id & M4A1) {
            GivePlayerItem(client, "weapon_m4a1");
        }
    if (weapon_id & M4A1S) {
            GivePlayerItem(client, "weapon_m4a1_silencer");
        }
    if (weapon_id & CZ) {
            GivePlayerItem(client, "weapon_cz75a");
        }
    if (weapon_id & P250) {
            GivePlayerItem(client, "weapon_p250");
        }
    if (weapon_id & GLOCK) {
            GivePlayerItem(client, "weapon_glock");
        }
    if (weapon_id & USP) {
            GivePlayerItem(client, "weapon_hkp2000");
        }
    if (weapon_id & P2000) {
            GivePlayerItem(client, "weapon_hkp2000");
        }
    if (weapon_id & TEC9) {
            GivePlayerItem(client, "weapon_tec9");
        }
    if (weapon_id & FIVESEVEN) {
            GivePlayerItem(client, "weapon_fiveseven");
        }
    if (weapon_id & C4) {
            GivePlayerItem(client, "weapon_c4");
        }
    if (weapon_id & KNIFE) {
            GivePlayerItem(client, "weapon_knife");
        }
    if (weapon_id & DEAGLE) {
            GivePlayerItem(client, "weapon_deagle");
        }
    if (weapon_id & DEFUSE_KIT) {
            GivePlayerItem(client, "item_defuser");          
        }
    if (weapon_id & FLASHBANG) {
            GivePlayerItem(client, "weapon_flashbang");          
        }
    if (weapon_id & SMOKEGRENADE) {
            GivePlayerItem(client, "weapon_smokegrenade");          
        }
    if (weapon_id & HEGRENADE) {
            GivePlayerItem(client, "weapon_hegrenade");          
        }
    if (weapon_id & MOLOTOV) {
            GivePlayerItem(client, "weapon_molotov");          
        }
    if (weapon_id & INCENDIARY) {
            GivePlayerItem(client, "weapon_incgrenade");          
        }
    if (weapon_id & FLASHBANG_2ND) {
            GivePlayerItem(client, "weapon_flashbang");          
        }
}

void InsertSpectateIntoServer() {
    ArrayList spec_matrix = new ArrayList();
    if (INVALID_HANDLE == spec_matrix) { 
        SetFailState("%s Could not allocate memory for spec_matrix @ InsertSpectateIntoServer", RETAKE_PREFIX);
    }

    PopulateArrayList(spec_matrix, GetTeamMatrix(CS_TEAM_SPECTATOR, false), GetPlayerCount(GetTeamMatrix(CS_TEAM_SPECTATOR, false)));
    PopulateArrayList(spec_matrix, GetTeamMatrix(CS_TEAM_NONE, false), GetPlayerCount(GetTeamMatrix(CS_TEAM_NONE, false)));

    for (int i = 0; i < GetArraySize(spec_matrix); i++) {
        if (GetClientCountFix(true) < MAX_INGAME_PLAYERS) {
            // Remove client from queue if existing
            g_ClientQueue.pop(g_ClientQueue.get_index(GetArrayCell(spec_matrix, i)));
            ChangeClientTeam(GetArrayCell(spec_matrix, i), GetNextTeamBalance());
        }
    }

    delete spec_matrix;
}

bool IsClientValid(int client) {
    return ((CONSOLE_CLIENT < client) && (IsClientInGame(client) && !IsClientSourceTV(client) && !IsFakeClient(client)));
}

void InsertClientIntoQueue(int client) {
    if (!IsClientValid(client)) { return; }
    if (GetRoundState() & RETAKE_NOT_LIVE) {
        return;
    }

    if (!IsClientInGame(client)) {
        return;
    }

    ChangeClientTeam(client, CS_TEAM_SPECTATOR);
    g_ClientQueue.insert(client);
}

bool IsClientInGamePlaying(int client) {
    if (!IsClientValid(client)) {
        return false;
    }

    return (IsClientInGame(client) && (CS_TEAM_T == GetClientTeam(client) || CS_TEAM_CT == GetClientTeam(client)));
}

int GetClientsAmountPercentage(int percentage) {
    int client_count = GetClientCountFix();
    return RoundToCeil(GetPercentage(client_count, percentage));
}

void SwitchClientTeam(int client, int team) {
    if (!IsClientValid(client)) { return; }
    CS_SwitchTeam(client, team);
    if (CS_TEAM_SPECTATOR != team && CS_TEAM_NONE != team) {
        CS_UpdateClientModel(client);
    }
}

#endif // CLIENT_SP