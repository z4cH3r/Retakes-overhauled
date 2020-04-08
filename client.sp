#if !defined CLIENT_SP
#define CLIENT_SP

#include "main.sp"

public void StripClientWeapons(int client, WeaponTypes exclude_slots) {
    int weapon = -1;
    bool remove_slots_exclude[5];

    if(!IsClientInGame(client) || !IsPlayerAlive(client) || !(GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT)) {
        return;
    }

    for (int i = 0; i < 5; i++) {
        remove_slots_exclude[i] = (exclude_slots & MapWeaponSlotToType(view_as<WeaponsSlot>(i))) ? true : false;
    }


    for (int slot = 0; slot < 5; slot++) {
        if (remove_slots_exclude[slot]) {
            continue;
        }

        while((weapon = GetPlayerWeaponSlot(client, slot)) != -1) {
            if(IsValidEntity(weapon)) {
                RemovePlayerItem(client, weapon);
            }
        }
    }
}

int GetTeamClientCountFix(int team, bool alive_only = true) {
	int count = 0;
	for (int i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == team) {
            if (alive_only && !IsPlayerAlive(i)) {
                continue;
            }
            count++;
        }
	}
	return count;
}

public void GiveBombToPlayer(int client) {
    if (0 != client && IsClientInGame(client)) {
        GiveClientItemWeaponID(client, C4);
    }
}

public int GetRandomPlayer(int team) {
    int index = 0;
    int clients[MAXPLAYERS];
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGame(i)) {
            continue;
        }
        
        if (team == GetClientTeam(i)) {
            clients[index++] = i;
        }
    }

    if (index > 0) {
        // -- because index is increased after each insert and GetRandomInt is inclusive
        index -= 1;
    }

    return clients[GetRandomInt(0, index)]; 
}

public int GetRandomAwpPlayer(int team) {
    int index = 0;
    int clients[MAXPLAYERS];
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGamePlaying(i) || IsFakeClient(i)) {
            continue;
        }
        
        if (team == GetClientTeam(i) && true == g_Client[i].pref.want_awp) {
            clients[index++] = i;
        }
    }

    if (index > 0) {
        // -- because index is increased after each insert and GetRandomInt is inclusive
        index -= 1;
    }

    return clients[GetRandomInt(0, index)];
}

public WeaponTypes GetRandomGrenades(int client) {
        int rand = GetURandomInt() % 6;

        PrintToChatAll("Grenade random %d client %d", rand, client);

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

public WeaponTypes GetRandomAwpSecondary(int client) {
    if (!IsClientInGamePlaying(client)) { return WEAPON_NONE; }
    int rand = GetURandomInt() % 3; // 33% chance
    WeaponTypes secondary = P250;
    
    PrintToChatAll("rand = %d", rand);
    if (0 == rand) {
        secondary = g_Client[client].pref.awp_secondary & ~P250;
        WeaponTypes team_mask = (CS_TEAM_T == GetClientTeam(client)) ? PISTOL_T_MASK : PISTOL_CT_MASK;
        secondary = secondary & team_mask;
        secondary = (secondary & CZ) ? CZ : secondary;
    }

    return secondary;
}

int GetClientCountFix(bool exclude_spec = true, bool exclude_fake_clients = true) {
    int counter = 0;

    for (int i = 1; i < MaxClients; i++) {
        if (!IsClientInGamePlaying(i)) {
            continue;
        }

        if ((exclude_fake_clients && IsFakeClient(i)) || (exclude_spec && GetClientTeam(i) == CS_TEAM_SPECTATOR)) {
            continue;
        }

        counter++;
    }

    return counter;
}

public void StripAllClientsWeapons(WeaponTypes slot_exception) {
    for (int i = 1; i < MaxClients; i++) {
        StripClientWeapons(i, slot_exception);
    }
}

public void GiveAllClientsWeapon(WeaponTypes weapon) {
    for(int i = 1; i <= MaxClients; i++) {
        GiveClientItemWeaponID(i, weapon);
    }
}

public void GiveClientItemWeaponID(int client, WeaponTypes weapon_id) { 
    if(!IsClientInGame(client) || !IsPlayerAlive(client) || !(GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT)) {
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

public void InsertClientIntoQueue(int client) {
    if (GetRoundState() & (WARMUP | WAITING)) {
        return;
    }

    ChangeClientTeam(client, CS_TEAM_SPECTATOR);
    g_ClientQueue.insert(client);

    if (GetClientCountFix() < MINIMUM_PLAYERS) {
        RetakeStop();
    }
}

public bool IsClientInGamePlaying(int client) {
    return (IsClientInGame(client) && (GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT));
}

public int GetClientsAmountPercentage(int percentage) {
    int client_count = GetClientCountFix();
    return RoundToCeil(float(client_count) * (float(percentage) / 100.0));
}

#endif // CLIENT_SP