#if !defined SPAWN_POINTS_SP
#define SPAWN_POINTS_SP

#include "types.sp"


Handle g_hSql = INVALID_HANDLE;



void ResetSpawns() {
    for (int i = 0; i < MAX_SPAWN_COUNT; i++) {
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

    if (0 == strcmp(driver_type, "mysql", false)) {
        SQL_Query(g_hSql, "CREATE TABLE IF NOT EXISTS `spawns` (`id` int(11) NOT NULL AUTO_INCREMENT, `type` int(11) NOT NULL, `site` int(11) NOT NULL, `map` varchar(32) NOT NULL, `posx` float NOT NULL, `posy` float NOT NULL, `posz` float NOT NULL, `angx` float NOT NULL, PRIMARY KEY (`id`));");
    }
    else if (0 == strcmp(driver_type, "sqlite", false)) {
        SQL_Query(g_hSql, "CREATE TABLE IF NOT EXISTS `spawns` (`id` INTEGER PRIMARY KEY, `type` INTEGER NOT NULL, `site` INTEGER NOT NULL, `map` varchar(32) NOT NULL, `posx` float NOT NULL, `posy` float NOT NULL, `posz` float NOT NULL, `angx` float NOT NULL);");
    }

    return true;
}

void LoadSpawns() {
    ResetSpawns();

    if (INVALID_HANDLE == g_hSql) {
        if (!ConnectToDB()) {
            SetFailState("%s LoadSpawns called with an invalid DB handle", RETAKE_PREFIX);
        }
    }

    char query[MAX_SQL_QUERY_SIZE];
    FormatEx(query, sizeof(query), "SELECT id, type, site, posx, posy, posz, angx FROM spawns WHERE map = '%s'", g_sCurrentMap);
    SQL_TQuery(g_hSql, LoadSpawnsCallBack, query, _, DBPrio_High);
}

void LoadSpawnsCallBack(Handle owner, Handle hndl, const char[] error, any data) {
    if (INVALID_HANDLE == hndl)	{
        LogError("%s SQL Error on LoadSpawnsCallback, error: %s", RETAKE_PREFIX, error);
        return;
    }

    int spawn_index = 0;
    while (SQL_FetchRow(hndl) && spawn_index < MAX_SPAWN_COUNT) {
        g_Spawns[spawn_index].is_initialized = true;
        g_Spawns[spawn_index].id = SQL_FetchInt(hndl, 0);
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

    if (GetRoundState() & ~RETAKE_NOT_LIVE) {
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

void DrawSpawns() {
    if (GetRoundState() != EDIT) {
        return;
    }

    for (int i = 0; i < GetSpawnCount(); i++) {
        int ent = CreateEntityByName("prop_dynamic"); 

        int target_color[3]; // [r, g, b]
        SetModelBombsiteColor(g_Spawns[i].bombsite, target_color);

        SetEntityModel(ent, GetModelByType(g_Spawns[i].spawn_type));
        ActivateEntity(ent);
        DispatchSpawn(ent);
        g_Spawns[i].spawn_location.ToFormat();
        g_Spawns[i].spawn_angles.ToFormat();
        SetEntityRenderColor(ent, target_color[0], target_color[1], target_color[2]);
        TeleportEntity(ent, g_Spawns[i].spawn_location.formatted, g_Spawns[i].spawn_angles.formatted, NULL_VECTOR); 
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
        // Verify Axises are up to date
        spawn.spawn_location.ToFormat();
        spawn.spawn_angles.ToFormat();

        TeleportEntity(client, spawn.spawn_location.formatted, spawn.spawn_angles.formatted, NULL_VECTOR);
    }
}

#endif // SPAWN_POINTS_SP