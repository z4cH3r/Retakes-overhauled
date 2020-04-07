#if !defined TYPES_SP
#define TYPES_SP

/********** Defines **********/
#define MAX_INPUT_SIZE 32
#define MAX_CONVAR_SIZE 256
#define MAX_COMMAND_SIZE 128

/********** Enums **********/
enum SpawnType
{
    CT          = 0x00000001,
    T           = 0x00000002,
    BOMBER      = 0x00000002 | 0x00000004,
};

enum RoundTypes
{
    WARMUP          = 0x00000001,
    WAITING         = 0x00000002,
    PISTOL_ROUND    = 0x00000004,
    FULLBUY_ROUND   = 0x00000008,
    DEAGLE_ROUND    = 0x00000010,
};

enum WeaponTypes {
    WEAPON_NONE     = 0x00000000,

    /** Pistols **/
    USP             = 0x00000001,
    P2000           = 0x00000002,
    FIVESEVEN       = 0x00000004,
    GLOCK           = 0x00000010,
    TEC9            = 0x00000020,
    CZ              = 0x00000100,
    DEAGLE          = 0x00000200,
    P250            = 0x00000400,
    PISTOL_MASK     = 0x00000FFF,
    PISTOL_T_MASK   = 0x00000FF0,
    PISTOL_CT_MASK  = 0x00000F0F,

    /** Rifles **/
    M4A1            = 0x00001000,
    M4A1S           = 0x00002000,
    AUG             = 0x00004000,
    AK47            = 0x00010000,
    SG553           = 0x00020000,
    AWP             = 0x00100000,
    RIFLE_MASK      = 0x00FFF000,
    RIFLE_T_MASK    = 0x00FF0000,
    RIFLE_CT_MASK   = 0x00F0F000,

    /** Utility **/
    FLASHBANG       = 0x01000000,
    SMOKE           = 0x02000000,
    HEGRENADE       = 0x04000000,
    MOLOTOV         = 0x10000000,
    INCENDIARY      = 0x20000000,
    UTILITY_MASK    = 0xFF000000,
    UTILITY_T_MASK  = 0x1F000000,
    UTILITY_CT_MASK = 0x2F000000,
}

enum cookies {
    cAwp,
    cAwpSecondary,
    cPrimaryT,
    cPrimaryCT,
}

enum struct ClientPref {
    bool want_awp;
    WeaponTypes awp_secondary;
    WeaponTypes primary_t;
    WeaponTypes primary_ct;

    //SetCookie(int client, cookies cookie, String:value[])
    void StoreClientCookies(int client) {
        char itoa[MAX_INPUT_SIZE];
        IntToString(this.want_awp, itoa, sizeof(itoa));
        SetCookie(client, cAwp, itoa);

        IntToString(view_as<int>(this.awp_secondary), itoa, sizeof(itoa));
        SetCookie(client, cAwpSecondary, itoa);

        IntToString(view_as<int>(this.primary_t), itoa, sizeof(itoa));
        SetCookie(client, cPrimaryT, itoa);

        IntToString(view_as<int>(this.primary_ct), itoa, sizeof(itoa));
        SetCookie(client, cPrimaryCT, itoa);
    }
}

enum struct Client {
    bool vp;
    bool vd;
    ClientPref pref;
}

#endif // TYPES_SP