#if !defined TYPES_SP
#define TYPES_SP

/********** Defines **********/
#define MAX_COMMAND_SIZE 128
#define MAX_INPUT_SIZE 32

/********** Enums **********/
enum SpawnType
{
    CT          = 0x00000001,
    T           = 0x00000002,
    BOMBER      = 0x00000002 | 0x00000004,
};

enum RoundTypes
{
    WARMUP          = 0b00000001,
    WAITING         = 0b00000010,
    PISTOL_ROUND    = 0b00000100,
    FULLBUY_ROUND   = 0b00001000,
    DEAGLE_ROUND    = 0b00010000,
};

enum WeaponTypes {
    WEAPON_NONE     = 0x00000000,

    /** Pistols **/
    USP             = 0x00000001,
    P2000           = 0x00000002,
    CZ              = 0x00000004,
    DEAGLE          = 0x00000008,
    FIVESEVEN       = 0x00000010,
    TEC9            = 0x00000020,
    P250            = 0x00000040,
    PISTOL_MASK     = 0x000000FF,

    /** Rifles **/
    AK47            = 0x00000100,
    SG553           = 0x00000200,
    M4A1            = 0x00000400,
    M4A1S           = 0x00000800,
    AWP             = 0x00001000,
    RIFLE_MASK      = 0x0000FF00,

    /** Utility **/
    FLASHBANG       = 0x00010000,
    SMOKE           = 0x00020000,
    HEGRENADE       = 0x00040000,
    MOLOTOV         = 0x00080000,
    INCENDIARY      = 0x00100000,
    UTILITY_MASK    = 0x00FF0000
}

enum cookies {
    cAwp,
    cPistol,
    cPrimaryT,
    cPrimaryCT,
}

enum struct ClientPref {
    bool want_awp;
    WeaponTypes pistol;
    WeaponTypes primary_t;
    WeaponTypes primary_ct;

    //SetCookie(int client, cookies cookie, String:value[])
    void StoreClientCookies(int client) {
        char itoa[MAX_INPUT_SIZE];
        IntToString(this.want_awp, itoa, sizeof(itoa));
        SetCookie(client, cAwp, itoa);

        IntToString(view_as<int>(this.pistol), itoa, sizeof(itoa));
        SetCookie(client, cPistol, itoa);

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