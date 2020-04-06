#if !defined MAIN_SP
#define MAIN_SP

#pragma semicolon 1

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include "types.sp"
#include "hooks.sp"
#include "cookies.sp"
#include "listeners.sp"
#include "plugin_info.sp"


RoundTypes g_ROUND_STATUS = WARMUP;
Client g_ClientWeaponPref[MAXPLAYERS + 1];



public WeaponTypes GetClientWeaponPref(int client, cookies cookie) {
    WeaponTypes ret = WEAPON_NONE;
    switch (cookie) {
        case cPrimaryT: {
            ret = g_ClientWeaponPref[client].pref.primary_t;
        }
        case cPrimaryCT: {
            ret = g_ClientWeaponPref[client].pref.primary_ct;
        }
        case cAwp: {
            ret = g_ClientWeaponPref[client].pref.want_awp ? AWP : WEAPON_NONE;
        }
        case cPistol: {
            ret = g_ClientWeaponPref[client].pref.pistol;
        }
    }

    return ret;
}

public void InitConsoleCMDs() {
    RegConsoleCmd("guns", MenuGunPref);
    // RegConsoleCmd("vp", MenuGunPref);
    // RegConsoleCmd("vd", MenuGunPref);
}

public void RetakeStart() {
    Handle g_hCTDefaultSecondary = FindConVar("mp_ct_default_secondary");
    Handle g_hTDefaultSecondary = FindConVar("mp_t_default_secondary");
    SetConVarString(g_hCTDefaultSecondary, "");
    SetConVarString(g_hTDefaultSecondary, "");
}

public void OnPluginStart() { 
    PrintToChatAll("test");

    RetakeStart();

    InitHooks();

    InitListeners();

    InitCookies();

    InitConsoleCMDs();

    for (int i = 1; i < MaxClients; i++) {
        if (!AreClientCookiesCached(i) || IsFakeClient(i)) {
            continue;
        }

        OnClientCookiesCached(i);
    }
}

public void OnMapStart() {
    g_ROUND_STATUS = WARMUP;
}

public RoundTypes GetRoundStatus() {
    return g_ROUND_STATUS;
}

public int GetConnectClients() {
    int connected_clients = 0;
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && (!IsFakeClient(i))) {
            connected_clients++;
        }
    }

    return connected_clients;
}

public void OnClientCookiesCached(int client) {
    if (IsFakeClient(client)) {
        return;
    }
    char pref[MAX_INPUT_SIZE];

    GetClientCookie(client, GetCookie(cAwp), pref, sizeof(pref));
    g_ClientWeaponPref[client].pref.want_awp = bool:StringToInt(pref);
    PrintToChatAll("Awp %s", pref);

    GetClientCookie(client, GetCookie(cPistol), pref, sizeof(pref));
    g_ClientWeaponPref[client].pref.pistol = view_as<WeaponTypes>(StringToInt(pref));
    PrintToChatAll("Pistol %s", pref);

    GetClientCookie(client, GetCookie(cPrimaryT), pref, sizeof(pref));
    g_ClientWeaponPref[client].pref.primary_t = view_as<WeaponTypes>(StringToInt(pref));
    PrintToChatAll("Primary T %s", pref);

    GetClientCookie(client, GetCookie(cPrimaryCT), pref, sizeof(pref));
    g_ClientWeaponPref[client].pref.primary_ct = view_as<WeaponTypes>(StringToInt(pref));
    PrintToChatAll("primary CT %s", pref);
}

/* Hold menus in main because we want to access g_ClientWeaponPref */
public Action MenuGunPref(int client, int args)
{
    Menu PrimaryTMenu = new Menu(MenuGunPrimaryTHandler);
    PrimaryTMenu.SetTitle("Select Terrorist weapon:");

    char itoa_ak[MAX_INPUT_SIZE];
    char itoa_sg[MAX_INPUT_SIZE];

    IntToString(view_as<int>(AK47), itoa_ak, sizeof(itoa_ak));
    IntToString(view_as<int>(SG553), itoa_sg, sizeof(itoa_sg));

    

    PrimaryTMenu.AddItem(itoa_ak, "AK-47");
    PrimaryTMenu.AddItem(itoa_sg, "SG 553");
    PrimaryTMenu.ExitButton = false;
    PrimaryTMenu.Display(client, MENU_TIME_FOREVER);
 
    return Plugin_Handled;
}

public int MenuGunPrimaryTHandler(Menu menu, MenuAction action, int client, int param2)
{
    /* If an option was selected, tell the client about the item. */
    if (action == MenuAction_Select)
    {
        char input[MAX_INPUT_SIZE];
        bool found = menu.GetItem(param2, input, sizeof(input));
        PrintToChatAll("client? %d - You selected item: %s (found? %d info: %s)", client, param2, found, input);
        g_ClientWeaponPref[client].pref.primary_t = view_as<WeaponTypes>(StringToInt(input));
        g_ClientWeaponPref[client].pref.StoreClientCookies(client);

        Menu PrimaryCtMenu = new Menu(MenuGunPrimaryCTHandler);
        PrimaryCtMenu.SetTitle("Select Counter-Terrorist weapon:");

        char itoa_m4a1[MAX_INPUT_SIZE];
        char itoa_m4a1s[MAX_INPUT_SIZE];

        IntToString(view_as<int>(M4A1), itoa_m4a1, sizeof(itoa_m4a1));
        IntToString(view_as<int>(M4A1S), itoa_m4a1s, sizeof(itoa_m4a1s));

        PrimaryCtMenu.AddItem(itoa_m4a1, "M4A4");
        PrimaryCtMenu.AddItem(itoa_m4a1s, "M4A1-S");
        PrimaryCtMenu.ExitButton = false;
        PrimaryCtMenu.Display(client, MENU_TIME_FOREVER);        
    }
    /* If the menu was cancelled, print a message to the server about it. */
    if (action == MenuAction_End)
    {
        delete menu;
    }
}

public int MenuGunPrimaryCTHandler(Menu menu, MenuAction action, int client, int param2)
{
    /* If an option was selected, tell the client about the item. */
    if (action == MenuAction_Select)
    {
        char input[MAX_INPUT_SIZE];
        bool found = menu.GetItem(param2, input, sizeof(input));
        PrintToChatAll("client? %d - You selected item: %s (found? %d info: %s)", client, param2, found, input);
        g_ClientWeaponPref[client].pref.primary_ct = view_as<WeaponTypes>(StringToInt(input));
        g_ClientWeaponPref[client].pref.StoreClientCookies(client);

        Menu AwpMenu = new Menu(MenuGunAwpHandler);
        AwpMenu.SetTitle("Would you like to play with awp?");
        AwpMenu.AddItem("1", "Yes");
        AwpMenu.AddItem("0", "No");
        AwpMenu.ExitButton = false;
        AwpMenu.Display(client, MENU_TIME_FOREVER);
    }
    if (action == MenuAction_End)
    {
        delete menu;
    }
}

public int MenuGunAwpHandler(Menu menu, MenuAction action, int client, int param2)
{
    /* If an option was selected, tell the client about the item. */
    if (action == MenuAction_Select)
    {
        char input[MAX_INPUT_SIZE];
        bool found = menu.GetItem(param2, input, sizeof(input));
        PrintToChatAll("client? %d - You selected item: %s (found? %d info: %s)", client, param2, found, input);
        g_ClientWeaponPref[client].pref.want_awp = view_as<bool>(StringToInt(input));
        g_ClientWeaponPref[client].pref.StoreClientCookies(client);
        if (g_ClientWeaponPref[client].pref.want_awp) {
            char itoa_FiveSeven_Tec9_P250[MAX_INPUT_SIZE];
            IntToString(view_as<int>(FIVESEVEN | TEC9 | P250), itoa_FiveSeven_Tec9_P250, sizeof(itoa_FiveSeven_Tec9_P250));

            char itoa_CZ_P250[MAX_INPUT_SIZE];
            IntToString(view_as<int>(CZ | P250), itoa_CZ_P250, sizeof(itoa_CZ_P250));

            char itoa_P250[MAX_INPUT_SIZE];
            IntToString(view_as<int>(P250), itoa_P250, sizeof(itoa_P250));

            Menu PistolMenu = new Menu(MenuGunPistolHandler);
            PistolMenu.SetTitle("Which pistol would you like with awp?");
            PistolMenu.AddItem(itoa_FiveSeven_Tec9_P250, "Five-Seven / Tec-9 / p250");
            PistolMenu.AddItem(itoa_CZ_P250, "CZ / p250");
            PistolMenu.AddItem(itoa_P250, "p250");
            PistolMenu.ExitButton = false;
            PistolMenu.Display(client, MENU_TIME_FOREVER);
        }
    }
    if (action == MenuAction_End)
    {
        delete menu;
    }
}

public int MenuGunPistolHandler(Menu menu, MenuAction action, int client, int param2)
{
    /* If an option was selected, tell the client about the item. */
    if (action == MenuAction_Select)
    {
        char input[MAX_INPUT_SIZE];
        bool found = menu.GetItem(param2, input, sizeof(input));
        PrintToChatAll("client? %d - You selected item: %s (found? %d info: %s)", client, param2, found, input);
        g_ClientWeaponPref[client].pref.pistol = view_as<WeaponTypes>(StringToInt(input));
        g_ClientWeaponPref[client].pref.StoreClientCookies(client);
    }
    if (action == MenuAction_End)
    {
        delete menu;
    }
}

public void GivePlayerItemWeaponID(int client, WeaponTypes weapon_id) {
    switch (weapon_id) {
        case AK47: {
            GivePlayerItem(client, "weapon_ak47");
        }
        case SG553: {
            GivePlayerItem(client, "weapon_sg556");
        }
        case AWP: {
            GivePlayerItem(client, "weapon_awp");
        }
        case M4A1: {
            GivePlayerItem(client, "weapon_m4a1");
        }
        case M4A1S: {
            GivePlayerItem(client, "weapon_m4a1_silencer");
        }
        case CZ: {
            GivePlayerItem(client, "weapon_cz75a");
        }
        case P250: {
            GivePlayerItem(client, "weapon_p250");
        }
    }
}

public Action DeleteItems(int client, int argc)
{
    int array_size = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
    int entity;

    for(new i = 0; i < array_size; i++)
    {
        entity = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);

        if(entity != -1 && GetEntSendPropOffs(entity, "m_bStartedArming") == -1)
        {
            CS_DropWeapon(client, entity, false, true);
            AcceptEntityInput(entity, "Kill");
        }
    }
    return Plugin_Handled;
}  

#endif // MAIN_SP