#if !defined MENUS_SP
#define MENUS_SP

// TODO: REFACTOR FILE

Menu GetAddSpawnMenu(Bombsite site, SpawnType type) {
    char itoa[MAX_INPUT_SIZE];
    Menu add_spawn_menu = CreateMenu(AddSpawnHandler, MENU_ACTIONS_ALL);
    SetMenuTitle(add_spawn_menu, "Add spawn:");

    IntToString(view_as<int>(site), itoa, sizeof(itoa));
    if (A == site) {
        add_spawn_menu.AddItem(itoa, "Bombsite: A");
    }
    else {
        add_spawn_menu.AddItem(itoa, "Bombsite: B");
    }

    IntToString(view_as<int>(type), itoa, sizeof(itoa));
    if (T == type) {
        add_spawn_menu.AddItem(itoa, "Spawn type: Terrorist");
    }
    else if (BOMBER == type) {
        add_spawn_menu.AddItem(itoa, "Spawn type: Bomber");
    }
    else {
        add_spawn_menu.AddItem(itoa, "Spawn type: Counter-Terrorist");
    }
    
    add_spawn_menu.AddItem("1", "Save spawn point");

    return add_spawn_menu;
}

public int AddSpawnHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select)
    {
        char input[MAX_INPUT_SIZE];
        char disp[MAX_INPUT_SIZE];
        char s_cur_site[MAX_INPUT_SIZE]; 
        menu.GetItem(0, s_cur_site, sizeof(s_cur_site));
        char s_cur_spawn_type[MAX_INPUT_SIZE]; 
        menu.GetItem(1, s_cur_spawn_type, sizeof(s_cur_spawn_type));
        Bombsite site = view_as<Bombsite>(StringToInt(s_cur_site));
        SpawnType type = view_as<SpawnType>(StringToInt(s_cur_spawn_type));

        menu.GetItem(param2, input, sizeof(input), _, disp, sizeof(disp));

        if (-1 != StrContains(disp, "Bombsite:", false)) {
            if (A == site) {
                site = B;
            }
            else {
                site = A;
            }
        }
        else if (-1 != StrContains(disp, "Spawn type:", false)) {
            if (T == type) {
                type = BOMBER;
            }
            else if (BOMBER == type) {
                type = CT;
            }
            else {
                type = T;
            }
        }
        else {
            float loc[3];
            float ang[3];
            GetClientAbsOrigin(client, loc);
            GetClientEyeAngles(client, ang);
            AddSpawnPoint(site, type, loc, ang);
            return;
        }
        GetAddSpawnMenu(site, type).Display(client, MENU_TIME_FOREVER);        
        
    }
    if (action == MenuAction_End)
    {
        delete menu;
    }
}

Menu GetEditSpawnMenu(int spawn_index) {
    char itoa[MAX_INPUT_SIZE];
    char title[MAX_INPUT_SIZE];
    Format(title, sizeof(title), "Edit spawn %d:", g_Spawns[spawn_index].sql_id);
    Menu edit_spawn_menu = CreateMenu(EditSpawnHandler, MENU_ACTIONS_ALL);
    SetMenuTitle(edit_spawn_menu, title);

    IntToString(view_as<int>(spawn_index), itoa, sizeof(itoa));
    edit_spawn_menu.AddItem(itoa, "Teleport to spawn point");
    edit_spawn_menu.AddItem(itoa, "Remove spawn point");

    return edit_spawn_menu;
}

Menu GetAllSpawnMenu() {
    char buffer[MAX_INPUT_SIZE];
    char itoa[MAX_INPUT_SIZE];
    Menu all_spawn_menu = CreateMenu(AllSpawnHandler, MENU_ACTIONS_ALL);
    SetMenuTitle(all_spawn_menu, "Teleport to spawn:");
    if (0 == GetSpawnCount()) {
        PrintToChatAll("%s No spawn points existing", RETAKE_PREFIX);
    }
    for (int i = 0; i < GetSpawnCount(); i++) {
        Format(buffer, sizeof(buffer), "ID: %d - Site %s - %s",                 \
         g_Spawns[i].sql_id, GetSiteStringFromBombsite(g_Spawns[i].bombsite),   \
         GetSpawnTypeStringFromSpawnType(g_Spawns[i].spawn_type));

        IntToString(view_as<int>(i), itoa, sizeof(itoa));
        all_spawn_menu.AddItem(itoa, buffer);
    }
    
    return all_spawn_menu;
}

public int AllSpawnHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select)
    {
        char s_spawn_index[MAX_INPUT_SIZE];
        char disp[MAX_INPUT_SIZE];
        menu.GetItem(param2, s_spawn_index, sizeof(s_spawn_index), _, disp, sizeof(disp));
        TeleportClient(client, g_Spawns[StringToInt(s_spawn_index)]);
        GetAllSpawnMenu().Display(client, MENU_TIME_FOREVER);     
        return;
    }
    if (action == MenuAction_Cancel) {
        if (IsClientValid(client)) {
            g_Client[client].spawnpoint_tele = false;
        }
    }
    if (action == MenuAction_End)
    {
        delete menu;
    }
}

public int EditSpawnHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select)
    {
        char s_spawn_index[MAX_INPUT_SIZE];
        char disp[MAX_INPUT_SIZE];
        menu.GetItem(param2, s_spawn_index, sizeof(s_spawn_index), _, disp, sizeof(disp));

        if (-1 != StrContains(disp, "Teleport", false)) {
            TeleportClient(client, g_Spawns[StringToInt(s_spawn_index)]);
            GetEditSpawnMenu(StringToInt(s_spawn_index)).Display(client, MENU_TIME_FOREVER);
        }
        else if (-1 != StrContains(disp, "Remove", false)) {
            g_Client[client].edit_menu_opened = false;
            DeleteSpawnPoint(g_Spawns[StringToInt(s_spawn_index)].sql_id);
        }
    }
    if (action == MenuAction_End)
    {
        delete menu;
    }
}

Menu GetAwpMenu() {
    Menu AwpMenu = new Menu(MenuGunAwpHandler);
    AwpMenu.SetTitle("Would you like to play with awp?");
    AwpMenu.AddItem("1", "Yes");
    AwpMenu.AddItem("0", "No");
    AwpMenu.ExitButton = false;
    return AwpMenu;
 }

Menu GetAwpSecondaryMenu() {
    Menu AwpSecondaryMenu = new Menu(AwpSecondaryMenuHandler);
    AwpSecondaryMenu.SetTitle("Which pistol would you like with awp?");

    char itoa_FiveSeven_Tec9_P250[MAX_INPUT_SIZE];
    IntToString(view_as<int>(FIVESEVEN | TEC9 | P250), itoa_FiveSeven_Tec9_P250, sizeof(itoa_FiveSeven_Tec9_P250));

    char itoa_CZ_P250[MAX_INPUT_SIZE];
    IntToString(view_as<int>(CZ | P250), itoa_CZ_P250, sizeof(itoa_CZ_P250));

    char itoa_P250[MAX_INPUT_SIZE];
    IntToString(view_as<int>(P250), itoa_P250, sizeof(itoa_P250));

    AwpSecondaryMenu.AddItem(itoa_FiveSeven_Tec9_P250, "Five-Seven / Tec-9 / p250");
    AwpSecondaryMenu.AddItem(itoa_CZ_P250, "CZ / p250");
    AwpSecondaryMenu.AddItem(itoa_P250, "p250");
    AwpSecondaryMenu.ExitButton = false;

    return AwpSecondaryMenu;
 }

Menu GetPrimaryTMenu() {
    Menu PrimaryTMenu = new Menu(PrimaryTMenuHandler);
    PrimaryTMenu.SetTitle("Select Terrorist weapon:");

    char itoa_ak[MAX_INPUT_SIZE];
    char itoa_sg[MAX_INPUT_SIZE];

    IntToString(view_as<int>(AK47), itoa_ak, sizeof(itoa_ak));
    IntToString(view_as<int>(SG553), itoa_sg, sizeof(itoa_sg));

    PrimaryTMenu.AddItem(itoa_ak, "AK-47");
    PrimaryTMenu.AddItem(itoa_sg, "SG 553");
    PrimaryTMenu.ExitButton = false;

    return PrimaryTMenu;
 }

Menu GetPrimaryCTMenu() {
    Menu PrimaryCTMenu = new Menu(PrimaryCTMenuHandler);
    PrimaryCTMenu.SetTitle("Select Counter-Terrorist weapon:");

    char itoa_m4a1[MAX_INPUT_SIZE];
    char itoa_m4a1s[MAX_INPUT_SIZE];

    IntToString(view_as<int>(M4A1), itoa_m4a1, sizeof(itoa_m4a1));
    IntToString(view_as<int>(M4A1S), itoa_m4a1s, sizeof(itoa_m4a1s));

    PrimaryCTMenu.AddItem(itoa_m4a1, "M4A4");
    PrimaryCTMenu.AddItem(itoa_m4a1s, "M4A1-S");
    PrimaryCTMenu.ExitButton = false;

    return PrimaryCTMenu;
 }

/* Hold menus in main because we want to access g_Client */
public Action MenuGunPref(int client, int argc)
{
    Menu PrimaryTMenu = GetPrimaryTMenu();
    PrimaryTMenu.Display(client, MENU_TIME_FOREVER);
 
    return Plugin_Handled;
}

public int PrimaryTMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_Select)
    {
        char input[MAX_INPUT_SIZE];
        menu.GetItem(param2, input, sizeof(input));
        g_Client[client].pref.primary_t = view_as<WeaponTypes>(StringToInt(input));
        g_Client[client].pref.StoreClientCookies(client);

        Menu PrimaryCTMenu = GetPrimaryCTMenu();
        
        PrimaryCTMenu.Display(client, MENU_TIME_FOREVER);        
    }
    if (action == MenuAction_End)
    {
        delete menu;
    }
}

public int PrimaryCTMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_Select)
    {
        char input[MAX_INPUT_SIZE];
        menu.GetItem(param2, input, sizeof(input));
        g_Client[client].pref.primary_ct = view_as<WeaponTypes>(StringToInt(input));
        g_Client[client].pref.StoreClientCookies(client);

        Menu AwpMenu = GetAwpMenu();
        AwpMenu.Display(client, MENU_TIME_FOREVER);
    }
    if (action == MenuAction_End)
    {
        delete menu;
    }
}

public int MenuGunAwpHandler(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_Select)
    {
        char input[MAX_INPUT_SIZE];
        menu.GetItem(param2, input, sizeof(input));
        g_Client[client].pref.want_awp = view_as<bool>(StringToInt(input));
        g_Client[client].pref.StoreClientCookies(client);
        if (g_Client[client].pref.want_awp) {
            Menu AwpSecondaryMenu = GetAwpSecondaryMenu();
            AwpSecondaryMenu.Display(client, MENU_TIME_FOREVER);
        }
    }
    if (action == MenuAction_End)
    {
        delete menu;
    }
}

public int AwpSecondaryMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_Select)
    {
        char input[MAX_INPUT_SIZE];
        menu.GetItem(param2, input, sizeof(input));
        g_Client[client].pref.awp_secondary = view_as<WeaponTypes>(StringToInt(input));
        g_Client[client].pref.StoreClientCookies(client);
    }
    if (action == MenuAction_End)
    {
        delete menu;
    }
}

#endif // MENUS_SP