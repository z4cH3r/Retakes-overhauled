#if !defined SPAWN_POINTS_SP
#define SPAWN_POINTS_SP

#include "retakes-overhauled/types.sp"


Handle g_hSql = INVALID_HANDLE;



void ResetSpawns() {
    for (int i = 0; i < MAX_SPAWN_COUNT; i++) {
        if (ValidateCachedEntity(g_Spawns[i].ent_id)) {
            // Hide all cached entities (We then draw only those we need)
            SetEntityRenderMode(g_Spawns[i].ent_id, RENDER_NONE);
        }
        else {
            // Clear deprecated entities (last round, etc)
            g_Spawns[i].ent_id = 0;
        }
        g_Spawns[i].Initialize();
    }
}

int GetSpawnCount() {
    int counter = 0;
    for (int i = 0; i < MAX_SPAWN_COUNT; i++) {
        if (g_Spawns[i].is_initialized) {
            counter++;
        }
    }

    return counter;
}

bool ConnectToDB() {
    if (g_hSql != INVALID_HANDLE) {
        CloseHandle(g_hSql);
        g_hSql = INVALID_HANDLE;
    }
    
    char error[MAX_INPUT_SIZE];

    if (!SQL_CheckConfig(RETAKE_CONFIG)) {
        SetFailState("%s No config entry found for '%s' in databases.cfg", RETAKE_PREFIX, RETAKE_CONFIG);
        return false;
    }

    for (int i = 0; i < MAX_DB_RETRIES; i++) {
        g_hSql = SQL_Connect(RETAKE_CONFIG, true, error, MAX_INPUT_SIZE);
        if (INVALID_HANDLE != g_hSql) {
            break;
        }
    }

    if (INVALID_HANDLE == g_hSql) {
        SetFailState("%s Could not connect to DB, reason: %s", RETAKE_PREFIX, error);
        return false;
    }

    // Initialize DB if stuff is missing :p
    char driver_type[MAX_INPUT_SIZE];
    SQL_GetDriverIdent(SQL_ReadDriver(g_hSql), driver_type, sizeof(driver_type));
    Handle hndl;

    if (0 == strcmp(driver_type, "mysql", false)) {
        hndl = SQL_Query(g_hSql, "CREATE TABLE IF NOT EXISTS `spawns` (`id` int(11) NOT NULL AUTO_INCREMENT, `type` int(11) NOT NULL, `site` int(11) NOT NULL, `map` varchar(32) NOT NULL, `posx` float NOT NULL, `posy` float NOT NULL, `posz` float NOT NULL, `angx` float NOT NULL, PRIMARY KEY (`id`));");
    }
    else if (0 == strcmp(driver_type, "sqlite", false)) {
        hndl = SQL_Query(g_hSql, "CREATE TABLE IF NOT EXISTS `spawns` (`id` INTEGER PRIMARY KEY, `type` INTEGER NOT NULL, `site` INTEGER NOT NULL, `map` varchar(32) NOT NULL, `posx` float NOT NULL, `posy` float NOT NULL, `posz` float NOT NULL, `angx` float NOT NULL);");
    }
    if (INVALID_HANDLE != hndl) {
        CloseHandle(hndl);
    }

    return true;
}

void LoadSpawns() {
    if (INVALID_HANDLE == g_hSql) {
        if (!ConnectToDB()) {
            SetFailState("%s LoadSpawns called with an invalid DB handle", RETAKE_PREFIX);
            return;
        }
    }

    ResetSpawns();

    char query[MAX_SQL_QUERY_SIZE];
    FormatEx(query, sizeof(query), "SELECT id, type, site, posx, posy, posz, angx FROM spawns WHERE map = '%s'", GetCurrentMapLower());
    Handle hndl = SQL_Query(g_hSql, query);
    int spawn_index = 0;
    while (SQL_FetchRow(hndl) && spawn_index < MAX_SPAWN_COUNT) {
        g_Spawns[spawn_index].is_initialized = true;
        g_Spawns[spawn_index].sql_id = SQL_FetchInt(hndl, 0);
        g_Spawns[spawn_index].spawn_type = view_as<SpawnType>(SQL_FetchInt(hndl, 1));
        g_Spawns[spawn_index].bombsite = view_as<Bombsite>(SQL_FetchInt(hndl, 2));
        g_Spawns[spawn_index].spawn_location.x = SQL_FetchFloat(hndl, 3);
        g_Spawns[spawn_index].spawn_location.y = SQL_FetchFloat(hndl, 4);
        g_Spawns[spawn_index].spawn_location.z = SQL_FetchFloat(hndl, 5);
        g_Spawns[spawn_index].spawn_location.ToFormat();
        g_Spawns[spawn_index].spawn_angles.x = 0.0;
        g_Spawns[spawn_index].spawn_angles.y = SQL_FetchFloat(hndl, 6);
        g_Spawns[spawn_index].spawn_angles.z = 0.0;
        g_Spawns[spawn_index].spawn_angles.ToFormat();
        spawn_index++;
    }
    if (INVALID_HANDLE != hndl) {
        CloseHandle(hndl);
    }

    if (GetRoundState() & ~EDIT) {
        if(GetSpawnCount() == 0) {
            PrintToChatAll("%s Edit mode is enabled becuase there are no spawns", RETAKE_PREFIX);
            EnableEdit();
        }
    }
}

char[] GetModelByType(SpawnType type) {
    char target_model[MAX_INPUT_SIZE];
    target_model = ERROR_MODEL;

    switch (type) {
        case CT: {
            target_model = CT_MODEL;
            }
        case T: {
            target_model = T_MODEL;
            }
        case BOMBER: {
            target_model = BOMBER_MODEL;
            }
    }

    return target_model;
}

void SetModelBombsiteColor(Bombsite site, int[] color) {
    if (A == site) {
        color[0] = 255;
    }
    else if (B == site) {
        color[2] = 255;
    }
    else {
        color[1] = 255;
    }
}

int GetRandomSpawn(SpawnType type, Bombsite site) {
    int spawns[MAX_SPAWN_COUNT];
    int index = 0;
    int spawn_index = -1;

    for (int i = 0; i < GetSpawnCount(); i++) {
        if ((g_Spawns[i].bombsite == site) && (g_Spawns[i].spawn_type == type) && (!g_Spawns[i].is_used)) {
            spawns[index++] = i;
        }
    }

    if (0 == index) {
        return spawn_index;
    }

    spawn_index = spawns[GetURandomInt() % index];
    g_Spawns[spawn_index].is_used = true;
    return spawn_index;
}

void ResetSpawnUsage() {
        for (int i = 0; i < GetSpawnCount(); i++) {
            g_Spawns[i].is_used = false;
    }
}

void TeleportClient(int client, Spawn spawn) {
    if (IsClientInGamePlaying(client) && IsPlayerAlive(client)) {
        // Verify Axes are up to date
        spawn.spawn_location.ToFormat();
        spawn.spawn_angles.ToFormat();

        TeleportEntity(client, spawn.spawn_location.formatted, spawn.spawn_angles.formatted, NULL_VECTOR);
    }
}

bool ValidateCachedEntity(int ent) {
    return ent > 0 && IsValidEntity(ent);
}

void DrawSpawns() {
    if (GetRoundState() != EDIT) {
        return;
    }

    PrintToChatAll("%s There are %d spawns", RETAKE_PREFIX, GetSpawnCount());
    for (int i = 0; i < GetSpawnCount(); i++) {
        int ent = g_Spawns[i].ent_id;
        
        if (!ValidateCachedEntity(ent)) {
            ent = CreateEntityByName("prop_dynamic");
            if (-1 == ent) {
                SetFailState("%s Could not create entity", RETAKE_PREFIX);
                return;
            }
            g_Spawns[i].ent_id = ent;
        }

        int target_color[3]; // [r, g, b]
        SetModelBombsiteColor(g_Spawns[i].bombsite, target_color);
        SetEntityRenderMode(g_Spawns[i].ent_id, RENDER_NORMAL);
        SetEntityModel(ent, GetModelByType(g_Spawns[i].spawn_type));
        ActivateEntity(ent);
        DispatchSpawn(ent);
        g_Spawns[i].spawn_location.ToFormat();
        g_Spawns[i].spawn_angles.ToFormat();
        SetEntityRenderColor(ent, target_color[0], target_color[1], target_color[2]);
        SetEntityTouchFlags(ent, GetTeamMatrix(CS_TEAM_ANY));
        SDKHook(ent, SDKHook_StartTouch, OnStartTouch);
        SDKHook(ent, SDKHook_Touch, OnTouch);
        SDKHook(ent, SDKHook_EndTouch, OnEndTouch);
        TeleportEntity(ent, g_Spawns[i].spawn_location.formatted, g_Spawns[i].spawn_angles.formatted, NULL_VECTOR); 
    }
}

void SetEntityTouchFlags(int entity, int[] players_matrix) {
    DispatchKeyValue(entity, "TouchType", "4");
    SetEntProp(entity, Prop_Send, "m_usSolidFlags", 12); //FSOLID_NOT_SOLID|FSOLID_TRIGGER
    SetEntProp(entity, Prop_Data, "m_nSolidType", 6); // SOLID_VPHYSICS
    SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1); //COLLISION_GROUP_DEBRIS 
    SetEntityMoveType(entity, MOVETYPE_NONE);
    SetEntProp(entity, Prop_Data, "m_MoveCollide", 0);
    for (int i = 0; i < GetPlayerCount(players_matrix); i++) {
        SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", players_matrix[i]);
    }
}

int GetSpawnIndexByEnt(int ent) {
    for (int i = 0; i < GetSpawnCount(); i++) {
        if (g_Spawns[i].ent_id == ent) {
            return i;
        }
    }
    return -1;
}

Action OnStartTouch(int ent, int client) {
    int spawn_index = GetSpawnIndexByEnt(ent);
    if (-1 != spawn_index && !g_Client[client].edit_menu_opened && !g_Client[client].spawnpoint_tele) {
        if (IsClientValid(client) && GetUserAdmin(client) != INVALID_ADMIN_ID) {
            g_Client[client].edit_menu_opened = true;
            Menu menu = GetEditSpawnMenu(spawn_index);
            menu.Display(client, MENU_TIME_FOREVER);
        }
    }
    return Plugin_Continue;
}

Action OnTouch(int ent, int client) {
    OnStartTouch(ent, client);
    return Plugin_Continue;
}

Action OnEndTouch(int ent, int client) {
    g_Client[client].edit_menu_opened = false;
    return Plugin_Continue;
}

void AddSpawnPoint(Bombsite site, SpawnType type, float[] loc, float[] ang) {
    if (GetSpawnCount() >= MAX_SPAWN_COUNT) {
        PrintToChatAll("Could not add spawn due to num of spawns at maximum (%d out of %d)", GetSpawnCount(), MAX_SPAWN_COUNT);
        return;
    }

    char query[MAX_SQL_QUERY_SIZE];
    FormatEx(query, sizeof(query), "INSERT INTO spawns (map, type, site, posx, posy, posz, angx) VALUES ('%s', '%d', '%d', %f, %f, %f, %f);", GetCurrentMapLower(), type, site, loc[0], loc[1], loc[2], ang[1]);
    Handle ret = SQL_Query(g_hSql, query);
    if (INVALID_HANDLE != ret) {
        CloseHandle(ret);
        LoadSpawns();
        DrawSpawns();
    }
}

void DeleteSpawnPoint(int sql_id) {
    char query[MAX_SQL_QUERY_SIZE];
    FormatEx(query, sizeof(query), "DELETE FROM spawns WHERE id = %d", sql_id);
    Handle ret = SQL_Query(g_hSql, query);
    if (INVALID_HANDLE != ret) {
        CloseHandle(ret);
        LoadSpawns();
        DrawSpawns();
    }
}

#endif // SPAWN_POINTS_SP